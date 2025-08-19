--!strict
local Session = {}
Session.__index = Session

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Table = require(Modules.Poker.Table)
local Timer = require(Modules.Timer)

function Session.new(players: {[number]: Player})
    assert(#players >= 2) -- TODO: should check on table too

    return setmetatable({
        Table = Table.new(players),
        Timer = Timer.new(),
        State = {
            Turn = 1,
            Player = {
                Current = {
                    Index = 1,
                },
                Last = {
                    Action = {
                        Type = nil,
                        Amount = nil,
                    },
                },
            },
        },
    }, Session)
end

function Session:SetNextPlayer()
    self.State.Player.Current.Index = (self.State.Player.Current.Index % #self.Table.Players) + 1

    while not self.Table.Players[self.State.Player.Current.Index].Active do
        self.State.Player.Current.Index = (self.State.Player.Current.Index % #self.Table.Players) + 1
    end
end

function Session:IsPlayerTurn(player: Player): boolean
    return player.UserId == self.Table.Players[self.State.Player.Current.Index].Id
end

function Session:Act(player: Player, action)
    if not self:IsPlayerTurn(player) then return end

    local _player = self.Table:GetPlayer(player)

    -- TODO(refactor): this is what happens when there is no switch statement, looks like shit.
    if action.Type == "BET" then
        local amount = action.Amount
        if _player.Chips < amount then return end

        _player.Chips -= amount
        self.Table.Pot += amount

        print("[bet] pot increased", _player.Chips, self.Table.Pot)
    elseif action.Type == "CALL" then
        if not (self.State.Player.Last.Action.Type == "BET" or self.State.Player.Last.Action.Type == "RAISE") then return end

        local amount = self.State.Player.Last.Action.Amount
        if _player.Chips < amount then return end

        _player.Chips -= amount
        self.Table.Pot += amount

        print("[call] pot increased", _player.Chips, self.Table.Pot)
    elseif action.Type == "RAISE" then
        if not (self.State.Player.Last.Action.Type == "BET" or self.State.Player.Last.Action.Type == "RAISE") then return end

        local treshold = 20
        local amount = action.Amount

        if self.State.Player.Last.Action.Amount > amount - treshold then return end
        if _player.Chips < amount then return end

        _player.Chips -= amount
        self.Table.Pot += amount

        print("[raise] pot increased", _player.Chips, self.Table.Pot)
    elseif action.Type == "FOLD" then
        _player.Active = false
    end
end

function Session:PromptNextMove()
    local _player = nil

    self.Timer:Start(10)
    self.Timer.Finished.Connect(function()
    end)
end

return Session
