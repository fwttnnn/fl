--!strict
local Session = {}
Session.__index = Session

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Table = require(Modules.Poker.Table)
local Timer = require(Modules.Timer)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Act = ReplicatedStorage.Events.Session.Act,
}

function Session.new(players: {[number]: Player})
    -- assert(#players >= 2) -- TODO: should check on table too

    return setmetatable({
        Table = Table.new(players),
        Timer = Timer.new(),
        State = {
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

function Session:Start()
    for _, _player in ipairs(self.Table.Players) do
        self.Table:Deal(_player.Player)
        task.wait(4)
        self.Table:Deal(_player.Player)
    end

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

    self.State.Started = true
    self:StartNextTurn()
end

function Session:StartNextTurn()
    self.State.Turn += 1
    if self.State.Turn >= 4 then return end

    self:ResetTurnCycle()
    print("[start] turn " .. self.State.Turn .. " started")

    for _, _player in ipairs(self.Table.Players) do
        _player.Active = true
    end

    self:PromptNextPlayerAct()
end

function Session:IsOver(): boolean
    local actives = 0

    for _, player in ipairs(self.Table.Players) do
        if player.Active then
            actives += 1
        end
    end

    return actives == 1
end

function Session:ResetTurnCycle()
    self.State.Player.Current.Index = 0
end

function Session:GetTurnPlayer()
    return self.Table.Players[self.State.Player.Current.Index]
end

function Session:SetNextPlayer(): boolean
    self.State.Player.Current.Index += 1
    if self.State.Player.Current.Index > #self.Table.Players then return true end

    while not self.Table.Players[self.State.Player.Current.Index].Active do
        self.State.Player.Current.Index += 1
        if self.State.Player.Current.Index > #self.Table.Players then return true end
    end

    return false
end

function Session:IsPlayerTurn(player: Player): boolean
    return player.UserId == self.Table.Players[self.State.Player.Current.Index].Id
end

function Session:Act(player: Player, action): boolean
    if not self.State.Started then return false end
    if not self:IsPlayerTurn(player) then return false end

    local _player = self.Table:GetPlayer(player)
    if not _player then return false end

    local handlers = {
        BET = function()
            local amount = action.Amount
            if amount <= 0 then return false end
            if _player.Chips < amount then return false end

            _player.Chips -= amount
            self.Table.Pot += amount
            print("[bet] pot increased", _player.Chips, self.Table.Pot)

            if self.State.Player.Current.Index > 1 then
                self:ResetTurnCycle()
            end

            return true
        end,

        CALL = function()
            local lastAction = self.State.Last.Action
            if not lastAction.Type == "BET" then return false end

            local amount = lastAction.Amount
            assert(amount > 0)

            action.Amount = amount

            -- TODO: we should be dead here, just go to the next person
            if _player.Chips <= 0 then return false end

            -- NOTE: ALL IN
            if _player.Chips < amount then
                amount = _player.Chips
                -- _player.Active = false
            end

            _player.Chips -= amount
            self.Table.Pot += amount

            print("[call] pot increased", _player.Chips, self.Table.Pot)
            return true
        end,

        CHECK = function()
            local lastAction = self.State.Last.Action
            if lastAction.Type == "BET" then return false end

            print("[check] game continues", _player.Chips, self.Table.Pot)
            return true
        end,

        FOLD = function()
            _player.Active = false
            print("[fold] player dies", _player.Chips, self.Table.Pot)
            return true
        end,
    }

    local handler = handlers[action.Type]
    if not handler then return false end

    local accepted = handler()
    if accepted then
        self.State.Player.Current.Acted = true
        self.State.Last.Action = action

        self.Timer:Stop()
        self.Timer:Reset()

        self:PromptNextPlayerAct()
    end

    return accepted
end

function Session:PromptNextPlayerAct()
    local ended = self:SetNextPlayer()
    if ended then
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
        else assert(false, "[turn end] turn beyond 3 should not be possible") end

        self:StartNextTurn()
        return
    end

    local _player = self:GetTurnPlayer()

    self.State.Player.Current.Acted = false
    Events.Act:FireClient(_player.Player)

    self.Timer:Start(3)
end

return Session
