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
    Act = ReplicatedStorage.Events.Match.Act,
    Acted = ReplicatedStorage.Events.Match.Acted,
}

function Match.new(players: {[number]: Player})
    local function onTimerFinished()
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

    return setmetatable({
        Turns = turns,
        Table = Table.new(players),
        Timer = Timer.new(),
        Last = #players, -- last player to move
    }, Match)
end

function Match:Start()
    self:_Turn()
end

function Match:_Turn()
    while not self.Turns:IsEmpty() do
        local turn = self.Turns:Pop()
        local handlers = {
            DP = function() self:_TurnPlayerDealing() end,
            DT = function() self:_TurnTableDealing(turn.Count) end,
            BT = function() self:_TurnBetting() end,
            SD = function() self:_TurnShowdown() end,
        }

        handlers[turn.Type]()
    end
end

function Match:_TurnPlayerDealing()
    local queue = Queue.new()
    for i = 1, #self.Table.Players do
        local p = self.Table.Players[((self.Last + i - 1) % #self.Table.Players) + 1]
        queue:Push(p)
    end

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
    local queue = Queue.new()
    for i = 1, #self.Table.Players do
        local p = self.Table.Players[((self.Last + i - 1) % #self.Table.Players) + 1]
        queue:Push(p)
    end

    local highestBet = 0
    local lastAction = {
        Type = nil,
        Amount = nil,
    }

    while not queue:IsEmpty() do
        local _player = queue:Pop()
        if not _player.Active then continue end

        local acted = Instance.new("BindableEvent")

        local connection
        connection = Events.Act.OnServerEvent:Connect(function(player, action)
            if player ~= _player.Player then return end

            local handlers = {
                BET = function()
                    local amount = action.Amount
                    if amount <= 0 then return false end
                    if _player.Chips < amount then return false end
                    if lastAction.Type == "BET" and amount <= lastAction.Amount then return false end

                    highestBet = amount
                    _player.Chips -= amount
                    self.Table.Pot += amount

                    if _player.Chips <= 0 then
                        _player.Active = false
                    end

                    -- NOTE: if a player past the first player bets
                    -- then, we go around.
                    local playerIndex = self.Table:PlayerIndex(player)
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

                    print("[bet] pot increased", _player.Chips, self.Table.Pot)
                    return true
                end,

                CALL = function()
                    if not (lastAction.Type == "BET" or lastAction.Type == "CALL") then return false end

                    local amount = math.min(_player.Chips, highestBet)
                    if amount <= 0 then return false end

                    action.Amount = amount
                    _player.Chips -= amount
                    self.Table.Pot += amount

                    if _player.Chips <= 0 then
                        _player.Active = false
                    end

                    print("[call] pot increased", _player.Chips, self.Table.Pot)
                    return true
                end,

                CHECK = function()
                    if lastAction.Type == "BET" or lastAction.Type == "CALL" then return false end

                    print("[check] game continues", _player.Chips, self.Table.Pot)
                    return true
                end,

                FOLD = function()
                    _player.Active = false
                    print("[fold] player out", _player.Chips, self.Table.Pot)
                    return true
                end,
            }

            local handler = handlers[action.Type]
            if not handler then return end

            local accepted = handler()
            if not accepted then return end

            lastAction = {
                Type = action.Type,
                Amount = action.Amount,
            }

            print("fired")
            acted:Fire()
            Events.Acted:FireClient(_player.Player)

            connection:Disconnect()
        end)

        Events.Act:FireClient(_player.Player)
        assert(not self.Timer.Running)
        -- self.Timer:Reset()
        -- self.Timer:Start(15)

        print("waiting " .. _player.Player.DisplayName .. " to act")
        acted.Event:Wait()
        print("player: " .. _player.Player.DisplayName .. " acted")
        -- self.Timer:Stop()
        -- self.Timer:Reset()

        self.Last = self.Table:PlayerIndex(_player.Player)
    end
end

function Match:_TurnShowdown()
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

    local winner = hands[1]
    print("[end] match ended, winner: (" .. winner.Player.DisplayName .. ") :: " .. winner.Rank)

    for i = 2, #hands do
        print("[end] others: (" .. hands[i].Player.DisplayName .. ") :: " .. hands[i].Rank)
    end
end

return Match
