--!strict
local Match = {}
Match.__index = Match

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Hand = require(Modules.Poker.Hand)
local Table = require(Modules.Poker.Table)

local Timer = require(Modules.Common.Timer)
local Queue = require(Modules.Common.Queue)

local Native = {
    Player = require(Modules.Native.Player),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Match = {
        Rematch = {
            Act = ReplicatedStorage.Events.Match.Rematch.Act,
            Acted = ReplicatedStorage.Events.Match.Rematch.Acted,
            Join = ReplicatedStorage.Events.Match.Rematch.Join,
            Quit = ReplicatedStorage.Events.Match.Rematch.Quit,
        },
        Turn = {
            Started = ReplicatedStorage.Events.Match.Turn.Started,
            Betting = {
                Started = ReplicatedStorage.Events.Match.Turn.Betting.Started,
                Act = ReplicatedStorage.Events.Match.Turn.Betting.Act,
                Acted = ReplicatedStorage.Events.Match.Turn.Betting.Acted,
                Action = ReplicatedStorage.Events.Match.Turn.Betting.Action,
            },
        },
    },
}

local Storages = {
    Memory = {
        Players = require(ServerStorage:WaitForChild("Storages").Memory.Players),
    },
}

function Match.new(players: {[number]: Player})
    local match = setmetatable({
        Table = Table.new(players),
        Timer = Timer.new(),
        -- TODO: as enum.
        Status = "Going",

        -- NOTE: the last player to move.
        __last = #players,
        -- NOTE: player removing connection.
        __conn = nil,
    }, Match)

    -- TODO(priority): disconnect this connection. (maybe make something like :Destroy())?
    match.__conn = Players.PlayerRemoving:Connect(function(player: Player)
        match.Table:Remove(player)
    end)

    return match
end

function Match:Start()
    -- cannot happen, but idk..
    if #self.Table.Players <= 1 then return end

    local turns = Queue.new()
    turns:Push({Type = "DP"})
    turns:Push({Type = "BT"})
    turns:Push({Type = "DT", Count = 3})
    turns:Push({Type = "BT"})
    turns:Push({Type = "DT", Count = 1})
    turns:Push({Type = "BT"})
    turns:Push({Type = "DT", Count = 1})
    turns:Push({Type = "BT"})
    turns:Push({Type = "SD"})

    local winners = self:_Turn(turns)

    self:__RemoveAllPlayersActionBillboard()
    self:__AddWinnerBillboard(winners)

    -- TODO: ehh, do we remove it this quick? players can't view their hand anymore.
    -- Storages.Memory.Matches.Remove(self)
end

function Match:Reset(players: {[number]: Player})
    self.Table:Destroy()

    self.Table = Table.new(players)
    self.Status = "Going"
    self.__last = #players
end

function Match:__AddPlayerIcons()
    -- TODO: get billboard dynamically.
    local billboard = workspace.Development.Board.Billboard
    billboard.Frame.Visible = true

    for _, p in (self.Table.Players) do
        local frame: Frame = ReplicatedStorage.Icon:Clone()
        local image: ImageLabel = frame.ImageLabel

        local icon: string = Storages.Memory.Players.Get(p.Player).Icon
        image.Image = icon

        frame.Name = p.Player.UserId
        frame.Parent = billboard.Frame
    end
end

function Match:__UpdatePlayerIconToJoin(player: Player)
    -- TODO: get billboard dynamically.
    local billboard = workspace.Development.Board.Billboard
    local frame: Frame = billboard.Frame[player.UserId]

    if not frame or not frame.ImageLabel or not frame.ImageLabel.UIStroke then return end

    frame.ImageLabel.UIStroke.Color = Color3.fromRGB(0, 255, 0) -- NOTE: green
end

function Match:__UpdatePlayerIconToQuit(player: Player)
    -- TODO: get billboard dynamically.
    local billboard = workspace.Development.Board.Billboard
    local frame: Frame = billboard.Frame[player.UserId]

    if not frame or not frame.ImageLabel or not frame.ImageLabel.UIStroke then return end

    frame.ImageLabel.UIStroke.Color = Color3.fromRGB(255, 0, 0) -- NOTE: red
end

function Match:__RemovePlayerIcons()
    -- TODO: get billboard dynamically.
    local billboard = workspace.Development.Board.Billboard
    billboard.Frame.Visible = false

    for _, p in (self.Table.Players) do
        local frame: Frame = billboard.Frame[p.Player.UserId]
        if not frame then continue end

        frame:Destroy()
    end
end

-- NOTE: prompt rematch to all players.
function Match:Rematch(): {[number]: Player}
    if #self.Table.Players <= 1 then return end

    for _, p in (self.Table.Players) do
        Events.Match.Rematch.Act:FireClient(p.Player)
    end

    self:__RemoveAllPlayersActionBillboard()
    self:__AddPlayerIcons()

    self.Timer:Stop()
    self.Timer:Reset()
    self.Timer:Start(30) -- NOTE: 30 seconds.

    local _players  = {
        Joins = {},
        Quits = {},
    }

    local function everyoneActed(): boolean
        for _, p in ipairs(self.Table.Players) do
            local id = p.Player.UserId
            local acted = _players.Joins[id] or _players.Quits[id]

            if not acted then
                return false
            end
        end

        return true
    end

    local ready = Instance.new("BindableEvent")
    local connections = {
        -- TODO: rename to accept/decline.
        Join = nil,
        Quit = nil,
        Timer = {
            Progression = nil,
            Finished = nil,
        },
    }

    connections.Join = Events.Match.Rematch.Join.OnServerEvent:Connect(function(player: Player)
        _players.Joins[player.UserId] = true
        self:__UpdatePlayerIconToJoin(player)
        Events.Match.Rematch.Acted:FireClient(player)

        if everyoneActed() then
            ready:Fire()
        end
    end)

    connections.Quit = Events.Match.Rematch.Quit.OnServerEvent:Connect(function(player: Player)
        _players.Quits[player.UserId] = true
        self:__UpdatePlayerIconToQuit(player)
        Events.Match.Rematch.Acted:FireClient(player)

        if everyoneActed() then
            ready:Fire()
        end
    end)

    connections.Timer.Progression = self.Timer.Progression:Connect(function(progress: number)
        -- UDim2.fromScale(progress, 1)
    end)

    connections.Timer.Finished = self.Timer.Finished:Connect(function()
        for _, p in ipairs(self.Table.Players) do
            local id = p.Player.UserId
            local acted = _players.Joins[id] or _players.Quits[id]

            if not acted then
                _players.Quits[id] = true
                self:__UpdatePlayerIconToQuit(p.Player)
                Events.Match.Rematch.Acted:FireClient(p.Player)
            end
        end

        ready:Fire()
    end)

    -- NOTE: blocking, waiting for all players to ready.
    ready.Event:Wait()

    self.Timer:Stop()
    self.Timer:Reset()

    connections.Join:Disconnect()
    connections.Quit:Disconnect()
    connections.Timer.Progression:Disconnect()
    connections.Timer.Finished:Disconnect()

    task.wait(2)
    self:__RemovePlayerIcons()

    local _playersJoined = {}
    for id, _ in pairs(_players.Joins) do
        local p = self.Table:Get({UserId = id})
        if not p then continue end

        table.insert(_playersJoined, p.Player)
    end

    return _playersJoined
end

function Match:__GetPlayerBillboardWrapper(player: Player): Frame
    local character = player.Character or player.CharacterAdded:Wait()
    local head: Head = character:WaitForChild("Head")
    local wrapper: Frame = head:WaitForChild("Billboard").Frame.Wrapper

    return wrapper
end

function Match:__AddActionBillboard(player: Player, action)
    local wrapper: Frame = self:__GetPlayerBillboardWrapper(player)

    local label = Instance.new("TextLabel", wrapper)
    label.Name = "Action"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.TextScaled = true
    label.Text = action.Type

    if action.Amount and action.Type ~= "ALL IN" then
        label.Text = action.Type .. " " .. action.Amount
    end
end

function Match:__RemoveActionBillboard(player: Player)
    local wrapper: Frame = self:__GetPlayerBillboardWrapper(player)
    local label: TextLabel = wrapper:FindFirstChild("Action")

    if label then
        label:Destroy()
    end
end

function Match:__RemoveAllPlayersActionBillboard()
    for _, _player in ipairs(self.Table.Players) do
        self:__RemoveActionBillboard(_player.Player)
    end
end

function Match:__AddTimerBillboard(player: Player): Frame
    local wrapper = self:__GetPlayerBillboardWrapper(player)

    local timerWrapper = Instance.new("Frame", wrapper)
    timerWrapper.Name = "Timer"
    timerWrapper.BackgroundTransparency = 1
    timerWrapper.Size = UDim2.fromScale(.7, .1)

    local timerProgressBar = Instance.new("Frame", timerWrapper)
    timerProgressBar.Name = "Bar"
    timerProgressBar.Size = UDim2.fromScale(1, 1)

    return timerProgressBar
end

function Match:__RemoveTimerBillboard(player: Player)
    local wrapper = self:__GetPlayerBillboardWrapper(player)
    local timerWrapper: Frame = wrapper.Timer

    if timerWrapper then
        timerWrapper:Destroy()
    end
end

function Match:__AddWinnerBillboard(winners)
    local draw = #winners > 1
    local text = draw and "DRAW" or "WINNER"

    for _, w in ipairs(winners) do
        local character = w.Player.Character or w.Player.CharacterAdded:Wait()
        local head: Head = character:WaitForChild("Head")
        local wrapper: Frame = head:WaitForChild("Billboard").Frame.Wrapper

        local label = Instance.new("TextLabel", wrapper)
        label.Name = "Action" -- TODO: rename label other than Action
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.TextScaled = true
        label.Text = text
    end
end

function Match:_Turn(turns: Queue): {[number]: Player}
    local winners = {}

    for _, p in ipairs(self.Table.Players) do
        Events.Match.Turn.Started:FireClient(p.Player, p.Health)
    end

    while not turns:IsEmpty() do
        local turn = turns:Pop()
        local handlers = {
            DP = function() self:_TurnPlayerDealing() end,
            DT = function() self:_TurnTableDealing(turn.Count) end,
            BT = function() self:_TurnBetting() end,
            SD = function() winners = self:_TurnShowdown() end,
        }

        if self.Status == "Everyone Folded" then
            handlers["SD"]()
            break
        end

        handlers[turn.Type]()
    end

    return winners
end

function Match:_BuildQueue(): Queue
    local queue = Queue.new()

    for i = 1, #self.Table.Players do
        local p = self.Table.Players[((self.__last + i - 1) % #self.Table.Players) + 1]
        queue:Push(p)
    end

    return queue
end

function Match:_TurnPlayerDealing()
    local queue = self:_BuildQueue()

    for _ = 1, queue:Size() do
        local _player = queue:Pop()
        assert(_player.Status == "Alive")

        task.wait(1)
        self.Table:Deal(_player.Player)
        task.wait(1)
        self.Table:Deal(_player.Player)
    end
end

function Match:_TurnTableDealing(count: number)
    for i = 1, count do
        task.wait(.65)
        self.Table:Deal()
    end
end

function Match:_TurnBetting()
    -- NOTE: kinda unnecessary, but ig it's O(1) rather than O(n)
    --       also, this check is cleaner tho
    if self.Status == "Everyone All In" then return end
    assert(self.Status == "Going")

    local queue = self:_BuildQueue()
    local highestBet = 0
    local lastAction = {
        Type = nil,
        Amount = nil,
    }

    local function isEveryoneAllIn(): boolean
        for _, _player in ipairs(self.Table.Players) do
            if _player.Status ~= "All In" then
                return false
            end
        end

        return true
    end

    -- NOTE: funny, this also checks if there's only 1 player left.
    local function isEveryoneExceptOneFolded(): number
        local count = 0

        for _, _player in ipairs(self.Table.Players) do
            if _player.Status == "Folded" then continue end
            count += 1
        end

        return count == 1
    end

    -- NOTE: should jump into showdown
    if isEveryoneExceptOneFolded() then
        self.Status = "Everyone Folded"
        return
    end

    if isEveryoneAllIn() then
        self.Status = "Everyone All In"
        return
    end

    self:__RemoveAllPlayersActionBillboard()

    for _, _player in ipairs(self.Table.Players) do
        if _player.Status ~= "Alive" then continue end
        Events.Match.Turn.Betting.Started:FireClient(_player.Player)
    end

    while not queue:IsEmpty() do
        if isEveryoneExceptOneFolded() then
            -- NOTE: should jump into showdown
            self.Status = "Everyone Folded"
            return
        end

        -- NOTE: just to be sure
        if isEveryoneAllIn() then
            self.Status = "Everyone All In"
            return
        end

        local _player = queue:Pop()
        if _player.Status ~= "Alive" then continue end

        local actionHandlers = {
            BET = function(action)
                local amount = action.Amount

                if amount <= highestBet then return false end
                if amount <= 0 then return false end

                if _player.Health < amount then return false end

                highestBet = amount
                _player.Health -= amount
                self.Table.Pot += amount

                if _player.Health <= 0 then
                    action.Type = "ALL IN"
                    _player.Status = "All In"
                end

                -- NOTE: if a player bets (will always be higher than `highestBet`), we go around.
                queue = Queue.new()
                local playerIndex = self.Table:Index(_player.Player)
                assert(playerIndex > 0)

                for i = playerIndex + 1, #self.Table.Players do
                    local p = self.Table.Players[i]
                    if p.Status ~= "Alive" then continue end

                    queue:Push(p)
                end

                for i = 1, playerIndex - 1 do
                    local p = self.Table.Players[i]
                    if p.Status ~= "Alive" then continue end

                    queue:Push(p)
                end

                -- NOTE: rebuilding queue means a new betting round (then we reset everyone's action label?).
                -- self:__RemoveAllPlayersActionBillboard()

                print("[bet] pot increased", _player.Health, self.Table.Pot)
                return true
            end,

            CALL = function(action)
                -- NOTE: prevent calling first turn.
                if not lastAction.Type then return false end

                if lastAction.Type == "CHECK" then return false end

                local amount = math.min(_player.Health, highestBet)
                if amount <= 0 then return false end

                action.Amount = amount
                _player.Health -= amount
                self.Table.Pot += amount

                if _player.Health <= 0 then
                    action.Type = "ALL IN"
                    _player.Status = "All In"
                end

                print("[call] pot increased", _player.Health, self.Table.Pot)
                return true
            end,

            CHECK = function(action)
                if lastAction.Type and lastAction.Type ~= "CHECK" then return false end

                print("[check] game continues", _player.Health, self.Table.Pot)
                return true
            end,

            FOLD = function(action)
                _player.Status = "Folded"
                print("[fold] player out", _player.Health, self.Table.Pot)
                return true
            end,
        }

        -- NOTE: we have to do these nasty out of the object thing whatever dood..
        actionHandlers["ALL IN"] = function(action)
            -- NOTE: we can just use BET, but it won't go through cuz
            --       we can't BET the same as `highestBet`.
            if _player.Health <= highestBet then
                return actionHandlers["CALL"](action)
            end

            action.Amount = _player.Health
            return actionHandlers["BET"](action)
        end

        -- NOTE: ah yes, another one why not dood..
        actionHandlers["RAISE"] = function(action)
            action.Amount = highestBet + action.Amount
            return actionHandlers["BET"](action)
        end

        local acted = Instance.new("BindableEvent")
        local connections = {
            Act = nil,
            Timer = {
                Progression = nil,
                Finished = nil,
            },
        }

        local function __disconnect()
            if connections.Act then               connections.Act:Disconnect() end
            if connections.Timer.Progression then connections.Timer.Progression:Disconnect() end
            if connections.Timer.Finished then    connections.Timer.Finished:Disconnect() end
        end

        connections.Act = Events.Match.Turn.Betting.Act.OnServerEvent:Connect(function(player: Player, action)
            if player ~= _player.Player then return end

            local handler = actionHandlers[action.Type]
            if not handler then return end

            local accepted = handler(action)
            if not accepted then return end

            lastAction = {
                Type = action.Type,
                Amount = action.Amount,
            }

            acted:Fire()
            Events.Match.Turn.Betting.Acted:FireClient(_player.Player, _player.Health)
        end)
        
        connections.Timer.Finished = self.Timer.Finished:Connect(function()
            if Native.Player.Disconnected(_player.Player) then
                -- NOTE: does not matter anyway..
                actionHandlers["FOLD"]({ Type = "FOLD", Amount = nil })
                return
            end

            local actions = {"CHECK", "CALL", "FOLD"}
            for _, action in ipairs(actions) do
                local fakeAction = { Type = action, Amount = nil }
                local accepted = actionHandlers[action](fakeAction)

                if accepted then 
                    lastAction = fakeAction
                    break
                end
            end

            acted:Fire()
            Events.Match.Turn.Betting.Acted:FireClient(_player.Player, _player.Health)
        end)

        self:__RemoveActionBillboard(_player.Player)
        local timerProgressBar = self:__AddTimerBillboard(_player.Player)

        connections.Timer.Progression = self.Timer.Progression:Connect(function(progress: number)
            if Native.Player.Disconnected(_player.Player) then
                self.Timer:Stop()
                self.Timer:Reset()

                -- just to continue off.
                acted:Fire()
                return
            end

            if not timerProgressBar then return end
            timerProgressBar.Size = UDim2.fromScale(progress, 1)
        end)

        if Native.Player.Disconnected(_player.Player) then
            __disconnect()
            continue
        end
        Events.Match.Turn.Betting.Act:FireClient(_player.Player, _player.Health)

        self.Timer:Stop()
        self.Timer:Reset()
        self.Timer:Start(20)

        -- NOTE: this blocks process.
        --       pass this event, the player should have acted.
        acted.Event:Wait()

        self.Timer:Stop()
        self.Timer:Reset()

        -- NOTE: check from `connections.Timer`
        if Native.Player.Disconnected(_player.Player) then
            __disconnect()
            continue
        end

        self:__RemoveTimerBillboard(_player.Player)
        self:__AddActionBillboard(_player.Player, lastAction)

        for _, p in ipairs(self.Table.Players) do
            if p.Id == _player.Id then continue end
            Events.Match.Turn.Betting.Action:FireClient(p.Player, _player.Player, lastAction)
        end

        __disconnect()
        self.__last = self.Table:Index(_player.Player)
    end

    -- NOTE: should jump into showdown
    if isEveryoneExceptOneFolded() then
        self.Status = "Everyone Folded"
        return
    end

    if isEveryoneAllIn() then
        self.Status = "Everyone All In"
        return
    end
end

function Match:_TurnShowdown()
    -- NOTE: ended by folds
    if self.Status == "Everyone Folded" then
        for _, _player in ipairs(self.Table.Players) do
            if _player.Status ~= "Folded" then
                print("[end] match ended by force, winner: (" .. _player.Player.DisplayName .. ")")
                return {{Player = _player.Player,
                         Hand = nil,
                         Rank = nil}}
            end
        end

        assert(false, "there should be 1 alive player")
        return {}
    end

    local hands = {}
    for _, _player in ipairs(self.Table.Players) do
        if _player.Status == "Folded" then continue end

        local hand = Hand.new(_player.Hand:Best(self.Table.Cards.Community.Cards))
        table.insert(hands, {Player = _player.Player,
                             Hand = hand,
                             Rank = hand:Rank()})
    end

    table.sort(hands, function(a, b)
        return a.Hand:Beats(b.Hand, {_Other = b.Rank, _Our = a.Rank})
    end)

    local winners = {hands[1]}
    for i = 2, #hands do
        if not hands[i].Hand:Equal(winners[1].Hand, {_Other = winners[1].Rank, _Our = hands[i].Rank}) then
            break
        end

        table.insert(winners, hands[i])
    end

    print("table ::", self.Table.Cards.Community)

    for _, h in ipairs(winners) do
        print("[end/w] match ended, winner: (" .. h.Player.DisplayName .. ") :: " .. h.Rank.Tier .. " @", h.Rank.Cards)
        print(h.Hand)
    end

    for i = #winners + 1, #hands do
        local h = hands[i]
        print("[end/o] match ended, others: (" .. h.Player.DisplayName .. ") :: " .. h.Rank.Tier .. " @", h.Rank.Cards)
        print(h.Hand)
    end

    return winners
end

return Match
