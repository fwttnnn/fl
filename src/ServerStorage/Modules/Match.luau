--!strict
local Match = {}
Match.__index = Match

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)

local Timer = require(Modules.Common.Timer)
local Queue = require(Modules.Common.Queue)

local Storages = {
    Global = {
        Chips = require(ServerStorage:WaitForChild("Storages").Global.Chips),
    },
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Match = {
        Act = ReplicatedStorage.Events.Match.Act,
        Acted = ReplicatedStorage.Events.Match.Acted,
        Action = ReplicatedStorage.Events.Match.Action,
        Turn = {
            Betting = {
                Started = ReplicatedStorage.Events.Match.Turn.Betting.Started,
            },
        },
    },
    Timer = {
        Start = ReplicatedStorage.Events.Timer.Start,
        Progress = ReplicatedStorage.Events.Timer.Progress,
        End = ReplicatedStorage.Events.Timer.End,
    },
}

function Match.new(players: {[number]: Player})
    -- NOTE: minimum chips to enter
    local stake = 500
    local _players = {}

    -- TODO: check if player can join before calling Match.new()
    for _, player in ipairs(players) do
        if Storages.Global.Chips.Get(player) - stake < 0 then
            return nil
        end
    end

    for _, player in ipairs(players) do
        -- NOTE: cached remaining chips.
        --       before entering, player should have enough chips to enter.
        --       the script that calls Match.new() should check first.
        local remaining = Storages.Global.Chips.Lose(player, stake)

        table.insert(_players, {
            Player = player,
            Chips = {
                Remaining = remaining,
                Stake = stake,
            },
        })
    end

    return setmetatable({
        Table = Table.new(_players),
        Turns = Queue.new(),
        Timer = Timer.new(),
        Last = #_players, -- last player to move
        Locked = false,
        Terminated = false, -- forced terminated, e.g. one player left
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

    local winner = self:_Turn()
    Storages.Global.Chips.Gain(winner, self.Table.Pot)

    -- NOTE: gain back chips on table.
    --       at this point, the match should be disposed (wip, later we can restart)
    for _, p in ipairs(self.Table.Players) do
        Storages.Global.Chips.Gain(p.Player, p.Chips.Stake)
    end

    self.Locked = true
    -- TODO: ehh, do we remove it this quick? players can't view their hand anymore.
    -- Storages.Memory.Matches.Remove(self)
end

function Match:_Turn(): Player
    local winner = nil

    while not self.Turns:IsEmpty() do
        local turn = self.Turns:Pop()
        local handlers = {
            DP = function() self:_TurnPlayerDealing() end,
            DT = function() self:_TurnTableDealing(turn.Count) end,
            BT = function() self:_TurnBetting() end,
            SD = function() winner = self:_TurnShowdown() end,
        }

        if self.Terminated then
            handlers["SD"]()
            break
        end

        handlers[turn.Type]()
    end

    return winner
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
        assert(_player.Active)

        self.Table:Deal(_player.Player)
        task.wait(4)
        self.Table:Deal(_player.Player)
    end
end

function Match:_TurnTableDealing(count: number)
    for i = 1, count do
        self.Table:Deal()
        task.wait(0.25)
    end
end

function Match:_TurnBetting()
    local queue = self:_BuildQueue()
    local highestBet = 0
    local lastAction = {
        Type = nil,
        Amount = nil,
    }

    local function playerLeft(): number
        local count = 0

        for _, _player in ipairs(self.Table.Players) do
            if not _player.Active then continue end
            count += 1
        end

        return count
    end

    -- NOTE: should jump into showdown
    if playerLeft() <= 1 then
        self.Terminated = true
        return
    end

    for _, _player in ipairs(self.Table.Players) do
        if not _player.Active then continue end
        Events.Match.Turn.Betting.Started:FireClient(_player.Player)
    end

    while not queue:IsEmpty() do
        -- NOTE: should jump into showdown
        if playerLeft() <= 1 then
            self.Terminated = true
            return
        end

        local _player = queue:Pop()
        if not _player.Active then continue end

        local actionHandlers = {
            BET = function(action)
                local amount = action.Amount
                if amount <= 0 then return false end
                if _player.Chips.Stake < amount then return false end
                if lastAction.Type == "BET" and amount <= lastAction.Amount then return false end

                highestBet = amount
                _player.Chips.Stake -= amount
                self.Table.Pot += amount

                if _player.Chips.Stake <= 0 then
                    _player.Active = false
                end

                -- NOTE: if a player past the first player bets
                -- then, we go around.
                local playerIndex = self.Table:PlayerIndex(_player.Player)
                if playerIndex > 1 then
                    print("[debug] looping, rebuilding queue")
                    queue = Queue.new()

                    for i = playerIndex + 1, #self.Table.Players do
                        local p = self.Table.Players[i]
                        if not p.Active then continue end

                        queue:Push(p)
                    end

                    for i = 1, playerIndex - 1 do
                        local p = self.Table.Players[i]
                        if not p.Active then continue end

                        queue:Push(p)
                    end
                end

                print("[bet] pot increased", _player.Chips.Stake, self.Table.Pot)
                return true
            end,

            CALL = function(action)
                -- if not (lastAction.Type == "BET" or lastAction.Type == "CALL") then return false end
                if lastAction.Type ~= "BET" and lastAction.Type ~= "CALL" then return false end

                local amount = math.min(_player.Chips.Stake, highestBet)
                if amount <= 0 then return false end

                action.Amount = amount
                _player.Chips.Stake -= amount
                self.Table.Pot += amount

                if _player.Chips.Stake <= 0 then
                    _player.Active = false
                end

                print("[call] pot increased", _player.Chips.Stake, self.Table.Pot)
                return true
            end,

            CHECK = function(action)
                if lastAction.Type == "BET" or lastAction.Type == "CALL" then return false end

                print("[check] game continues", _player.Chips.Stake, self.Table.Pot)
                return true
            end,

            FOLD = function(action)
                _player.Active = false
                print("[fold] player out", _player.Chips.Stake, self.Table.Pot)
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
            Events.Match.Acted:FireClient(_player.Player)

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
            Events.Match.Acted:FireClient(_player.Player)

            actEventConnection:Disconnect()
            timerFinishedConnection:Disconnect()
        end)

        Events.Match.Act:FireClient(_player.Player)
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
    if playerLeft() <= 1 then
        self.Terminated = true
        return
    end
end

function Match:_TurnShowdown(): Player
    -- NOTE: ended by folds
    if self.Terminated and #self.Table.Cards.Community.Cards < 5 then
        for _, _player in ipairs(self.Table.Players) do
            if _player.Active then
                print("[end] match ended by force, winner: (" .. _player.Player.DisplayName .. ")")
                return _player.Player
            end
        end

        assert(false, "there should be 1 active player")
    end

    local hands = {}
    for _, _player in ipairs(self.Table.Players) do
        if not _player.Active then continue end

        local hand = Pile.new(_player.Hand:Best(self.Table.Cards.Community.Cards))
        table.insert(hands, {Player = _player.Player,
                                Hand = hand,
                                Rank = hand:Rank(),
                                Score = hand:Score()})
    end

    table.sort(hands, function(a, b)
        if a.Rank == b.Rank then
            return a.Score > b.Score
        end

        return a.Rank > b.Rank
    end)

    -- TODO: check for draws
    local winner = hands[1]
    print("[end] match ended, winner: (" .. winner.Player.DisplayName .. ") :: " .. winner.Rank .. " @ " ..  winner.Score)

    for i = 2, #hands do
        print("[end] others: (" .. hands[i].Player.DisplayName .. ") :: " .. hands[i].Rank .. " @ " .. hands[i].Score)
    end

    return winner.Player
end

return Match
