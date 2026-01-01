--!strict
local Match = {
    ENTRY_MIN = 100,
    ENTRY_MAX = 5000,
}
Match.__index = Match

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Hand = require(Modules.Poker.Hand)
local Table = require(Modules.Poker.Table)

local Timer = require(Modules.Extension.Common.Timer)
local Queue = require(Modules.Extension.Common.Queue)

local Native = {
    Player = require(Modules.Extension.Native.Player),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events

local Storages = {
    Memory = {
        Players = require(ServerStorage.Storages.Memory.Players),
    },
    Global = {
        Hours = require(ServerStorage.Storages.Global.Hours),
    },
}

local _table = require(ReplicatedStorage.Modules.Extension.Table)

function Match.new(players: {[number]: Player}, entry: number, tbl: Folder)
    assert(#players >= Table.PLAYERS_MIN and #players <= Table.PLAYERS_MAX)
    assert((entry   >= Match.ENTRY_MIN   and entry    <= Match.ENTRY_MAX) or
           (entry <= 0))

    local match = setmetatable({}, Match)

    match.Entry  = entry
    match.Casual = entry <= 0

    local hours = match.Casual and
                  Match.ENTRY_MIN or
                  entry

    match.Table = Table.new(_players, hours, tbl)
    match.Timer = Timer.new()

    -- TODO: as enum.
    match.State = "Going"

    -- NOTE: the last player to move.
    match.Last = #_players

    -- NOTE(priority): when it's our turn and someone disconnected, we can
    --                 still bet and everything, so.. this is a thing to keep in mind.
    match.Conn = Players.PlayerRemoving:Connect(function(player: Player)
        _table.remove(match.Table.Players, function(p)
            return p.Id == player.Id
        end)
    end)

    return match
end

function Match:Destroy()
    self.Table:Destroy()
    self.Conn:Disconnect()
end

function Match:Start()
    local players = self.Table.Players
    for _, p in ipairs(players) do
        Events.Match.Started:FireClient(p.Player,
                                        players)
    end

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

    for _, p in ipairs(players) do
        Events.Match.Ended:FireClient(p.Player,
                                      winners)
    end

    for _, w in ipairs(winners) do
        Storages.Global.Hours.Gain(w.Player, self.Table.Pot / #winners)
    end
end

function Match:_Turn(turns: Queue): {[number]: Player}
    local winners = {}

    for _, p in ipairs(self.Table.Players) do
        Events.Match.Turn.Started:FireClient(p.Player, p.Hours)
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
        local p = self.Table.Players[((self.Last + i - 1) % #self.Table.Players) + 1]
        if not p.Status["Alive"] then continue end

        queue:Push(p)
    end

    return queue
end

function Match:_RebuildQueue(from: Player): Queue
    local queue = Queue.new()

    local playerIndex = _table.index(self.Table.Players, function(p)
        return p.Id == from.UserId
    end)
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
        Events.Match.Turn.Betting.Started:FireClient(_player.Player)
    end

    while not queue:IsEmpty() do
        local _player = queue:Pop()
        if not _player.Status["Alive"] then continue end

        -- NOTE: should jump into showdown
        if isEveryoneExceptOneFolded() then
            self.State = "Everyone Folded"
            return
        end

        if isEveryoneAllIn() then
            self.State = "Everyone All In"
            return
        end

        local actionHandlers = {
            BET = function(action)
                local amount = action.Amount

                if amount <= highestBet then return false end
                if amount <= 0 then return false end

                if _player.Hours < amount then return false end

                highestBet = amount
                _player.Hours -= amount
                self.Table.Pot += amount

                if _player.Hours <= 0 then
                    action.Type = "ALL IN"

                    _player.Status["Alive"] = false
                    _player.Status["All In"] = true
                end

                -- NOTE: if a player bets (will always be higher than `highestBet`), we go around.
                queue = self:_RebuildQueue(_player.Player)

                return true
            end,

            CALL = function(action)
                -- NOTE: prevent calling first turn.
                if not lastAction.Type then return false end

                if lastAction.Type == "CHECK" then return false end

                local amount = math.min(_player.Hours, highestBet)
                if amount <= 0 then return false end

                action.Amount = amount
                _player.Hours -= amount
                self.Table.Pot += amount

                if _player.Hours <= 0 then
                    action.Type = "ALL IN"

                    _player.Status["Alive"] = false
                    _player.Status["All In"] = true
                end

                return true
            end,

            CHECK = function(action)
                if lastAction.Type and lastAction.Type ~= "CHECK" then return false end

                return true
            end,

            FOLD = function(action)
                _player.Status["Alive"] = false
                _player.Status["Folded"] = true

                return true
            end,
        }

        -- NOTE: we have to do these nasty out of the object thing whatever dood..
        actionHandlers["ALL IN"] = function(action)
            -- NOTE: we can just use BET, but it won't go through cuz
            --       we can't BET the same as `highestBet`.
            if _player.Hours <= highestBet then
                return actionHandlers["CALL"](action)
            end

            action.Amount = _player.Hours
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

        connections.Timer.Progression = self.Timer.Progression.Tick:Connect(function(remaining: number)
            if Native.Player.Disconnected(_player.Player) then
                self.Timer:Stop()
                self.Timer:Reset()

                -- just to continue off.
                acted:Fire()
            end

            for _, p in ipairs(self.Table.Players) do
                Events.Match.Turn.Betting.Timer:FireClient(p.Player,
                                                           _player.Player,
                                                           remaining / self.Timer.Duration)
            end
        end)

        if Native.Player.Disconnected(_player.Player) then
            __disconnect()
            continue
        end
        Events.Match.Turn.Betting.Act:FireClient(_player.Player, _player.Hours)

        self.Timer:Stop()
        self.Timer:Reset()
        self.Timer:Start(21)

        -- NOTE: this blocks process.
        --       pass this event, the player should have acted.
        acted.Event:Wait()
        Events.Match.Turn.Betting.Acted:FireClient(_player.Player,
                                                   lastAction,
                                                   _player.Hours,
                                                   self.Table.Pot)

        self.Timer:Stop()
        self.Timer:Reset()

        if Native.Player.Disconnected(_player.Player) then
            __disconnect()
            continue
        end

        for _, p in ipairs(self.Table.Players) do
            if p.Id == _player.Id then continue end
            Events.Match.Turn.Betting.Action:FireClient(p.Player,
                                                        _player.Player,
                                                        lastAction,
                                                        -- NOTE: a bit unorganized, but this is better than
                                                        --       firing multiple events
                                                        _player.Hours,
                                                        self.Table.Pot)
        end

        __disconnect()
        self.Last = _table.index(self.Table.Players, function(p)
            return p.Id == _player.Player.UserId
        end)
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
