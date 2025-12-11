--!strict
local Match = {}
Match.__index = Match

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Billboard = require(Modules.Gui.Billboard)
local Dialog = require(Modules.Gui.Dialog)

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
    Global = {
        Stars = require(ServerStorage:WaitForChild("Storages").Global.Stars),
    },
}

function Match.new(players: {[number]: Player})
    local match = setmetatable({
        Table = Table.new(players),
        Timer = Timer.new(),
        -- TODO: as enum.
        State = "Going",

        -- NOTE: the last player to move.
        __last = #players,
        -- NOTE: player removing connection.
        __conn = nil,
    }, Match)

    -- TODO(priority): disconnect this connection. (maybe make something like :Destroy())?
    -- TODO(priority): when it's our turn, we can still bet and everything, so.. this is a thing to keep in mind.
    match.__conn = Players.PlayerRemoving:Connect(function(player: Player)
        match.Table:Remove(player)
    end)

    return match
end

function Match:Start()
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
    local draw = #winners > 1

    local players = self.Table.Players
    for _, p in ipairs(players) do Billboard.Set(p.Player, Billboard.Types.Floating, "") end
    for _, w in ipairs(winners) do
        Storages.Global.Stars.Gain(w.Player, self.Table.Pot / #winners)
        Billboard.Set(w.Player, Billboard.Types.Floating, draw and "DRAW" or "WINNER")
        Billboard.Set(w.Player, Billboard.Types.Stars, Storages.Global.Stars.Get(w.Player) .. " ★")
    end

    task.wait(5)
    for _, w in ipairs(winners) do Billboard.Set(w.Player, Billboard.Types.Floating, "") end
end

function Match:_Turn(turns: Queue): {[number]: Player}
    local winners = {}

    for _, p in ipairs(self.Table.Players) do
        Events.Match.Turn.Started:FireClient(p.Player, p.Stars)
    end

    while not turns:IsEmpty() do
        local turn = turns:Pop()
        local handlers = {
            DP = function() self:_TurnPlayerDealing() end,
            DT = function() self:_TurnTableDealing(turn.Count) end,
            BT = function() self:_TurnBetting() end,
            SD = function() winners = self:_TurnShowdown() end,
        }

        if self.State == "Everyone Folded" then
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
        if not p.Status["Alive"] then continue end

        queue:Push(p)
    end

    return queue
end

function Match:_RebuildQueue(from: Player): Queue
    local queue = Queue.new()

    local playerIndex = self.Table:Index(from)
    assert(playerIndex > 0)

    for i = playerIndex + 1, #self.Table.Players do
        local p = self.Table.Players[i]
        if not p.Status["Alive"] then continue end

        queue:Push(p)
    end

    for i = 1, playerIndex - 1 do
        local p = self.Table.Players[i]
        if not p.Status["Alive"] then continue end

        queue:Push(p)
    end

    return queue
end

function Match:_TurnPlayerDealing()
    local queue = self:_BuildQueue()

    for _ = 1, queue:Size() do
        local _player = queue:Pop()
        assert(_player.Status["Alive"])

        task.wait(0.55)
        self.Table:Deal(_player.Player)
        task.wait(0.55)
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
    if self.State ~= "Going" then return end

    local queue = self:_BuildQueue()
    local highestBet = 0
    local lastAction = {
        Type = nil,
        Amount = nil,
    }

    local function isEveryoneAllIn(): boolean
        for _, _player in ipairs(self.Table.Players) do
            if not _player.Status["All In"] then
                return false
            end
        end

        return true
    end

    local function isEveryoneExceptOneFolded(): number
        local count = 0

        for _, _player in ipairs(self.Table.Players) do
            if _player.Status["Folded"] then continue end
            count += 1
        end

        return count == 1
    end

    local function isEveryoneExceptOneAlive(): number
        local count = 0

        for _, _player in ipairs(self.Table.Players) do
            if not _player.Status["Alive"] then continue end
            count += 1
        end

        return count == 1
    end

    -- NOTE: should jump into showdown
    if isEveryoneExceptOneFolded() then
        self.State = "Everyone Folded"
        return
    end

    if isEveryoneAllIn() then
        self.State = "Everyone All In"
        return
    end

    if isEveryoneExceptOneAlive() then
        -- idk, should go off
        self.State = "Everyone Except One Alive"
        return
    end

    for _, _player in ipairs(self.Table.Players) do
        Billboard.Set(_player.Player, Billboard.Types.Floating, "")

        if not _player.Status["Alive"] then continue end
        Events.Match.Turn.Betting.Started:FireClient(_player.Player)
    end

    while not queue:IsEmpty() do
        local _player = queue:Pop()
        if not _player.Status["Alive"] then continue end

        local actionHandlers = {
            BET = function(action)
                local amount = action.Amount

                if amount <= highestBet then return false end
                if amount <= 0 then return false end

                if _player.Stars < amount then return false end

                highestBet = amount
                _player.Stars -= amount
                Storages.Global.Stars.Lose(_player.Player, amount)
                self.Table.Pot += amount

                if _player.Stars <= 0 then
                    action.Type = "ALL IN"

                    _player.Status["Alive"] = false
                    _player.Status["All In"] = true
                end

                -- NOTE: if a player bets (will always be higher than `highestBet`), we go around.
                queue = self:_RebuildQueue(_player.Player)

                -- NOTE: rebuilding queue means a new betting round (then we reset everyone's action label?).
                -- self:__RemoveAllPlayersActionBillboard()

                print("[bet] pot increased", _player.Stars, self.Table.Pot)
                return true
            end,

            CALL = function(action)
                -- NOTE: prevent calling first turn.
                if not lastAction.Type then return false end

                if lastAction.Type == "CHECK" then return false end

                local amount = math.min(_player.Stars, highestBet)
                if amount <= 0 then return false end

                action.Amount = amount
                _player.Stars -= amount
                Storages.Global.Stars.Lose(_player.Player, amount)
                self.Table.Pot += amount

                if _player.Stars <= 0 then
                    action.Type = "ALL IN"

                    _player.Status["Alive"] = false
                    _player.Status["All In"] = true
                end

                print("[call] pot increased", _player.Stars, self.Table.Pot)
                return true
            end,

            CHECK = function(action)
                if lastAction.Type and lastAction.Type ~= "CHECK" then return false end

                print("[check] game continues", _player.Stars, self.Table.Pot)
                return true
            end,

            FOLD = function(action)
                _player.Status["Alive"] = false
                _player.Status["Folded"] = true

                print("[fold] player out", _player.Stars, self.Table.Pot)
                return true
            end,
        }

        -- NOTE: we have to do these nasty out of the object thing whatever dood..
        actionHandlers["ALL IN"] = function(action)
            -- NOTE: we can just use BET, but it won't go through cuz
            --       we can't BET the same as `highestBet`.
            if _player.Stars <= highestBet then
                return actionHandlers["CALL"](action)
            end

            action.Amount = _player.Stars
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

        -- TODO: should we refund stars if disconnected? idk tho.. could be duplicated
        local function __disconnect()
            if connections.Act then               connections.Act:Disconnect() end
            if connections.Timer.Progression then connections.Timer.Progression:Disconnect() end
            if connections.Timer.Finished then    connections.Timer.Finished:Disconnect() end
        end

        local _locked = false
        connections.Act = Events.Match.Turn.Betting.Act.OnServerEvent:Connect(function(player: Player, action)
            if player ~= _player.Player then return end
            if _locked then return end

            _locked = true

            local handler = actionHandlers[action.Type]
            if not handler then return end

            local accepted = handler(action)
            if not accepted then
                _locked = false
                return
            end

            lastAction = {
                Type = action.Type,
                Amount = action.Amount,
            }

            acted:Fire()
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
        end)

        connections.Timer.Progression = self.Timer.Progression.Tick:Connect(function(sec: number)
            if Native.Player.Disconnected(_player.Player) then
                self.Timer:Stop()
                self.Timer:Reset()

                -- just to continue off.
                acted:Fire()
                return
            end

            Billboard.Set(_player.Player, Billboard.Types.Floating, sec .. "s left")
        end)

        if Native.Player.Disconnected(_player.Player) then
            __disconnect()
            continue
        end
        Events.Match.Turn.Betting.Act:FireClient(_player.Player, _player.Stars)

        self.Timer:Stop()
        self.Timer:Reset()
        self.Timer:Start(21)

        -- NOTE: this blocks process.
        --       pass this event, the player should have acted.
        acted.Event:Wait()
        Events.Match.Turn.Betting.Acted:FireClient(_player.Player, _player.Stars)

        self.Timer:Stop()
        self.Timer:Reset()

        -- NOTE: check from `connections.Timer`
        if Native.Player.Disconnected(_player.Player) then
            __disconnect()
            continue
        end

        -- NOTE: set action text to billboard
        local __labelText = lastAction.Type
        if lastAction.Type ~= "ALL IN" then
            if lastAction.Type == "BET" then
                __labelText = lastAction.Type .. " " .. lastAction.Amount .. " ★"
            end
            if lastAction.Type == "RAISE" then
                __labelText = lastAction.Type .. " TO " .. lastAction.Amount .. " ★"
            end
        end
        Billboard.Set(_player.Player, Billboard.Types.Floating, __labelText)
        Billboard.Set(_player.Player, Billboard.Types.Stars, _player.Stars .. " ★")

        for _, p in ipairs(self.Table.Players) do
            if p.Id == _player.Id then continue end
            Events.Match.Turn.Betting.Action:FireClient(p.Player, _player.Player, lastAction)
        end

        __disconnect()
        self.__last = self.Table:Index(_player.Player)
    end

    -- NOTE: should jump into showdown
    if isEveryoneExceptOneFolded() then
        self.State = "Everyone Folded"
        return
    end

    if isEveryoneAllIn() then
        self.State = "Everyone All In"
        return
    end

    if isEveryoneExceptOneAlive() then
        -- idk, should go off
        self.State = "Everyone Except One Alive"
        return
    end
end

function Match:_TurnShowdown()
    -- NOTE: ended by folds
    if self.State == "Everyone Folded" then
        for _, _player in ipairs(self.Table.Players) do
            if not _player.Status["Folded"] then
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
        if _player.Status["Folded"] then continue end

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
