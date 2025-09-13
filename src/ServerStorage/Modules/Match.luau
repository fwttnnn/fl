--!strict
local Match = {}
Match.__index = Match

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)

local Timer = require(Modules.Common.Timer)
local Queue = require(Modules.Common.Queue)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Match = {
        Act = ReplicatedStorage.Events.Match.Act,
        Acted = ReplicatedStorage.Events.Match.Acted,
        Action = ReplicatedStorage.Events.Match.Action,
        Turn = {
            Started = ReplicatedStorage.Events.Match.Turn.Started,
            Betting = {
                Started = ReplicatedStorage.Events.Match.Turn.Betting.Started,
            },
        },
        Winner = ReplicatedStorage.Events.Match.Winner,
    },
    Timer = {
        Start = ReplicatedStorage.Events.Timer.Start,
        Progress = ReplicatedStorage.Events.Timer.Progress,
        End = ReplicatedStorage.Events.Timer.End,
    },
}

function Match.new(players: {[number]: Player})
    return setmetatable({
        Table = Table.new(players),
        Turns = Queue.new(),
        Timer = Timer.new(),
        Last = #players, -- last player to move
        Locked = false,
        -- TODO: as enum
        Status = "Going"
    }, Match)
end

function Match:Start()
    if self.Locked then return end

    self.Turns = Queue.new()
    self.Turns:Push({Type = "DP"})
    self.Turns:Push({Type = "BT"})
    self.Turns:Push({Type = "DT", Count = 3})
    self.Turns:Push({Type = "BT"})
    self.Turns:Push({Type = "DT", Count = 1})
    self.Turns:Push({Type = "BT"})
    self.Turns:Push({Type = "DT", Count = 1})
    self.Turns:Push({Type = "BT"})
    self.Turns:Push({Type = "SD"})

    local winners = self:_Turn()
    local draw = #winners > 1

    local winner: Player = winners[1].Player
    if draw then winner = nil end

    for _, p in ipairs(self.Table.Players) do
        -- NOTE: client checks if the player is the same as their own uid.
        Events.Match.Winner:FireClient(p.Player, winner)
    end

    self.Locked = true

    -- TODO: ehh, do we remove it this quick? players can't view their hand anymore.
    -- Storages.Memory.Matches.Remove(self)
end

function Match:_Turn(): {[number]: Player}
    local winners = {}

    for _, p in ipairs(self.Table.Players) do
        Events.Match.Turn.Started:FireClient(p.Player, p.Health)
    end

    while not self.Turns:IsEmpty() do
        local turn = self.Turns:Pop()
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
        local p = self.Table.Players[((self.Last + i - 1) % #self.Table.Players) + 1]
        queue:Push(p)
    end

    return queue
end

function Match:_TurnPlayerDealing()
    local queue = self:_BuildQueue()

    for _ = 1, queue:Size() do
        local _player = queue:Pop()
        assert(_player.Status == "Alive")

        self.Table:Deal(_player.Player)
        task.wait(4)
        self.Table:Deal(_player.Player)
    end
end

function Match:_TurnTableDealing(count: number)
    for i = 1, count do
        self.Table:Deal()
        task.wait(.65)
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

    for _, _player in ipairs(self.Table.Players) do
        if not _player.Status == "Alive" then continue end
        Events.Match.Turn.Betting.Started:FireClient(_player.Player)
    end

    while not queue:IsEmpty() do
        -- NOTE: should jump into showdown
        if isEveryoneExceptOneFolded() then
            self.Status = "Everyone Folded"
            return
        end

        -- NOTE: just to be sure
        if isEveryoneAllIn() then
            self.Status = "Everyone All In"
            return
        end

        local _player = queue:Pop()
        if not _player.Status == "Alive" then continue end

        local actionHandlers = {
            BET = function(action)
                local amount = action.Amount
                if amount <= 0 then return false end
                if _player.Health < amount then return false end

                if (lastAction.Type == "BET" or lastAction.Type == "CALL") and amount <= lastAction.Amount then return false end
                if highestBet ~= 0 and amount <= highestBet then return false end

                highestBet = amount
                _player.Health -= amount
                self.Table.Pot += amount

                if _player.Health <= 0 then
                    _player.Status = "All In"
                end

                -- NOTE: if a player bets (will always be higher than `highestBet`), we go around.
                queue = Queue.new()
                local playerIndex = self.Table:PlayerIndex(_player.Player)

                for i = playerIndex + 1, #self.Table.Players do
                    local p = self.Table.Players[i]
                    if not p.Status == "Alive" then continue end

                    queue:Push(p)
                end

                for i = 1, playerIndex - 1 do
                    local p = self.Table.Players[i]
                    if not p.Status == "Alive" then continue end

                    queue:Push(p)
                end

                print(queue:IsEmpty())
                print(queue:Size())

                print("[bet] pot increased", _player.Health, self.Table.Pot)
                return true
            end,

            CALL = function(action)
                -- if not (lastAction.Type == "BET" or lastAction.Type == "CALL") then return false end
                if lastAction.Type ~= "BET" and lastAction.Type ~= "CALL" then return false end

                local amount = math.min(_player.Health, highestBet)
                if amount <= 0 then return false end

                action.Amount = amount
                _player.Health -= amount
                self.Table.Pot += amount

                if _player.Health <= 0 then
                    _player.Status = "All In"
                end

                print("[call] pot increased", _player.Health, self.Table.Pot)
                return true
            end,

            CHECK = function(action)
                if lastAction.Type == "BET" or lastAction.Type == "CALL" then return false end

                print("[check] game continues", _player.Health, self.Table.Pot)
                return true
            end,

            FOLD = function(action)
                _player.Status = "Folded"
                print("[fold] player out", _player.Health, self.Table.Pot)
                return true
            end,
        }

        local acted = Instance.new("BindableEvent")
        local _action = {
            Type = nil,
            Amount = nil,
        }

        local actEventConnection
        local timerFinishedConnection

        actEventConnection = Events.Match.Act.OnServerEvent:Connect(function(player, action)
            if player ~= _player.Player then return end

            local handler = actionHandlers[action.Type]
            if not handler then return end

            local accepted = handler(action)
            if not accepted then return end

            _action = {
                Type = action.Type,
                Amount = action.Amount,
            }

            lastAction = {
                Type = action.Type,
                Amount = action.Amount,
            }

            acted:Fire()
            Events.Match.Acted:FireClient(_player.Player, _player.Health)

            actEventConnection:Disconnect()
            timerFinishedConnection:Disconnect()
        end)
        
        timerFinishedConnection = self.Timer.Finished:Connect(function()
            print("[timeout] auto-act for " .. _player.Player.DisplayName)

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
            Events.Match.Acted:FireClient(_player.Player, _player.Health)

            actEventConnection:Disconnect()
            timerFinishedConnection:Disconnect()
        end)

        Events.Match.Act:FireClient(_player.Player, _player.Health)
        Events.Timer.Start:FireClient(_player.Player)
        assert(not self.Timer.Running)
        self.Timer:Reset()
        self.Timer:Start(20, _player.Player)

        print("waiting " .. _player.Player.DisplayName .. " to act")
        acted.Event:Wait()
        print("player: " .. _player.Player.DisplayName .. " acted")
        Events.Timer.End:FireClient(_player.Player) 
        self.Timer:Stop()
        self.Timer:Reset()

        for _, p in ipairs(self.Table.Players) do
            if p.Id == _player.Id then continue end
            Events.Match.Action:FireClient(p.Player, _player.Player, _action)
        end

        actEventConnection:Disconnect()
        timerFinishedConnection:Disconnect() -- NOTE: make sure timer is disconnected. 
                                             -- this can still be called because of the Timer:Reset() if not done.

        self.Last = self.Table:PlayerIndex(_player.Player)
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

    local function isHandEqual(handA, handB): boolean
        local rankA, rankB = handA.Rank, handB.Rank

        if rankA.Tier ~= rankB.Tier then
            return rankA.Tier > rankB.Tier
        end

        assert(#rankA.Cards == #rankB.Cards)
        local n = #rankA.Cards

        for i = 1, n do
            local a = rankA.Cards[i]:RankAsNumeric()
            local b = rankB.Cards[i]:RankAsNumeric()

            if a ~= b then
                return false
            end
        end

        -- NOTE: get cards that's unused for rankings
        local function kickers(pile, used)
            local _used = {}
            for _, c in ipairs(used) do
                _used[c] = true
            end

            local _kickers = {}
            for _, c in ipairs(pile.Cards) do
                if not _used[c] then
                    table.insert(_kickers, c)
                end
            end

            -- NOTE: sadly, we need to sort it.
            table.sort(_kickers, function(a, b)
                return a:RankAsNumeric() > b:RankAsNumeric()
            end)

            return _kickers
        end

        local kickersA = kickers(handA.Pile, rankA.Cards)
        local kickersB = kickers(handB.Pile, rankB.Cards)

        assert(#kickersA == #kickersB)
        local n = #kickersA

        for i = 1, n do
            local a = kickersA[i]:RankAsNumeric()
            local b = kickersB[i]:RankAsNumeric()

            if a ~= b then
                return false
            end
        end

        return true
    end

        local function isHandBetter(handA, handB): boolean
        local rankA, rankB = handA.Rank, handB.Rank

        if rankA.Tier ~= rankB.Tier then
            return rankA.Tier > rankB.Tier
        end

        assert(#rankA.Cards == #rankB.Cards)
        local n = #rankA.Cards

        for i = 1, n do
            local a = rankA.Cards[i]:RankAsNumeric()
            local b = rankB.Cards[i]:RankAsNumeric()

            if a ~= b then
                return a > b
            end
        end

        -- NOTE: get cards that's unused for rankings
        local function kickers(pile, used)
            local _used = {}
            for _, c in ipairs(used) do
                _used[c] = true
            end

            local _kickers = {}
            for _, c in ipairs(pile.Cards) do
                if not _used[c] then
                    table.insert(_kickers, c)
                end
            end

            -- NOTE: sadly, we need to sort it.
            table.sort(_kickers, function(a, b)
                return a:RankAsNumeric() > b:RankAsNumeric()
            end)

            return _kickers
        end

        local kickersA = kickers(handA.Pile, rankA.Cards)
        local kickersB = kickers(handB.Pile, rankB.Cards)

        assert(#kickersA == #kickersB)
        local n = #kickersA

        for i = 1, n do
            local a = kickersA[i]:RankAsNumeric()
            local b = kickersB[i]:RankAsNumeric()

            if a ~= b then
                return a > b
            end
        end

        return false -- NOTE: ties
    end

    local hands = {}
    for _, _player in ipairs(self.Table.Players) do
        if not _player.Status == "Alive" then continue end

        local hand = Pile.new(_player.Hand:Best(self.Table.Cards.Community.Cards))
        table.insert(hands, {Player = _player.Player,
                             Pile = hand,
                             Rank = hand:Rank()})
    end

    table.sort(hands, function(a, b)
        return isHandBetter(a, b)
    end)

    local winners = {hands[1]}
    for i = 2, #hands do
        if not isHandEqual(hands[i], winners[1]) then
            break
        end

        table.insert(winners, hands[i])
    end

    print("table ::", self.Table.Cards.Community)

    for _, h in ipairs(winners) do
        print("[end/w] match ended, winner: (" .. h.Player.DisplayName .. ") :: " .. h.Rank.Tier .. " @", h.Rank.Cards)
        print(h.Pile)
    end

    for i = #winners + 1, #hands do
        local h = hands[i]
        print("[end/o] match ended, others: (" .. h.Player.DisplayName .. ") :: " .. h.Rank.Tier .. " @", h.Rank.Cards)
        print(h.Pile)
    end

    return winners
end

return Match
