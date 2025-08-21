--!strict
local Session = {}
Session.__index = Session

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)
local Timer = require(Modules.Timer)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Act = ReplicatedStorage.Events.Session.Act,
}

function Session.new(players: {[number]: Player})
    return setmetatable({
        Table = Table.new(players),
        Timer = Timer.new(),
        State = {
            _HandledTimer = false,
            Loop = false,
            Started = false,
            Turn = 0,
            Player = {
                Current = {
                    Acted = false,
                    Index = 0,
                },
            },
            Last = {
                Action = {
                    Type = nil,
                    Amount = nil,
                },
            },
        },
    }, Session)
end

function Session:_HandleTimerFinished()
    if self.State._HandledTimer then return end
    self.State._HandledTimer = true

    self.Timer.Finished:Connect(function()
        print("[timer] finished")
        if self.State.Player.Current.Acted then return end

        local _player = self:GetTurnPlayer()
        print("[timer] " .. _player.Player.DisplayName .. " took too long")

        -- TODO: ...
        local lastAction = self.State.Last.Action
        if lastAction.Type == nil or lastAction.Type == "CHECK" then
            self:Act(_player.Player, { Type = "CHECK" })
            return
        elseif lastAction.Type == "BET" or lastAction.Type == "CALL" then
            self:Act(_player.Player, { Type = "CALL" })
            return
        end

        -- NOTE: should not trigger
        assert(false, "[timer] player should have acted")
    end)
end

function Session:Start()
    self:_HandleTimerFinished()

    for _, _player in ipairs(self.Table.Players) do
        self.Table:Deal(_player.Player)
        task.wait(4)
        self.Table:Deal(_player.Player)
    end

    self.State.Started = true
    self:StartNextTurn()
end

function Session:StartNextTurn()
    -- NOTE: can go up to 4 turns because the players need to act.
    self.State.Turn += 1

    self:ResetTurnCycle()
    self.State.Last.Action = {
        Type = nil,
        Amount = nil,
    }

    print("[start] turn " .. self.State.Turn .. " started")

    for _, _player in ipairs(self.Table.Players) do
        _player.Active = true
    end

    self:PromptNextPlayerAct()
end

function Session:IsActive(): boolean
    local actives = 0

    for _, player in ipairs(self.Table.Players) do
        if player.Active then
            actives += 1
        end
    end

    return actives > 0
end

function Session:ResetTurnCycle()
    self.State.Player.Current.Index = 0
end

function Session:GetTurnPlayer()
    return self.Table.Players[self.State.Player.Current.Index]
end

function Session:SetNextPlayer(): boolean
    -- NOTE: just a heads up, clean this later
    if not self:IsActive() then return true end

    self.State.Player.Current.Index += 1
    if self.State.Player.Current.Index > #self.Table.Players then
        if self.State.Loop then
            self.State.Loop = false
            self:ResetTurnCycle()
            return self:SetNextPlayer()
        end

        return true
    end

    while not self.Table.Players[self.State.Player.Current.Index].Active do
        self.State.Player.Current.Index += 1
        if self.State.Player.Current.Index > #self.Table.Players then
            if self.State.Loop then
                self.State.Loop = false
                self:ResetTurnCycle()
                return self:SetNextPlayer()
            end

            return true
        end
    end

    return false
end

function Session:IsPlayerTurn(player: Player): boolean
    return player.UserId == self.Table.Players[self.State.Player.Current.Index].Id
end

function Session:Act(player: Player, action): boolean
    if not self.State.Started then return false end
    if not self:IsPlayerTurn(player) then return false end

    local _player = self:GetTurnPlayer()
    local handlers = {
        BET = function()
            local amount = action.Amount
            if amount <= 0 then return false end
            if _player.Chips < amount then return false end

            local lastAction = self.State.Last.Action
            if lastAction.Type == "BET" and amount <= lastAction.Amount then return false end

            _player.Chips -= amount
            self.Table.Pot += amount

            if _player.Chips <= 0 then
                _player.Active = false
            end

            -- NOTE: if a player past the first player bets
            -- then, we go around.
            if self.State.Player.Current.Index > 1 then
                -- TODO: this is shit. do queue
                print("[debug] looping " .. self.State.Player.Current.Index)
                self.State.Loop = true
            end

            print("[bet] pot increased", _player.Chips, self.Table.Pot)
            return true
        end,

        CALL = function()
            local lastAction = self.State.Last.Action
            if lastAction.Type ~= "BET" then return false end

            local amount = math.min(_player.Chips, lastAction.Amount)
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
            local lastAction = self.State.Last.Action
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
    if not handler then return false end

    local accepted = handler()
    if accepted then
        self.State.Player.Current.Acted = true
        self.State.Last.Action = {
            Type = action.Type,
            Amount = action.Amount,
        }

        self.Timer:Stop()
        self.Timer:Reset()

        self:PromptNextPlayerAct()
    end

    return accepted
end

function Session:PromptNextPlayerAct()
    local turnEnded = self:SetNextPlayer()
    if turnEnded then
        local turn = self.State.Turn

        if turn == 1 then
            self.Table:Deal()
            task.wait(0.5)
            self.Table:Deal()
            task.wait(0.5)
            self.Table:Deal()
        elseif turn == 2 then
            self.Table:Deal()
        elseif turn == 3 then
            self.Table:Deal()
        elseif turn == 4 then
            -- NOTE: match ended
            self.State.Started = false

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

            return
        else assert(false, "cannot be possible") end

        self:StartNextTurn()
        return
    end

    local _player = self:GetTurnPlayer()

    self.State.Player.Current.Acted = false
    Events.Act:FireClient(_player.Player)

    self.Timer:Start(15)
end

return Session
