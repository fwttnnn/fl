--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage:WaitForChild("Modules")
local Card = require(Modules.Poker.Card)
local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)

local Managers = ServerStorage:WaitForChild("Managers")
local SessionManager = require(Managers.Session)
local Session = require(Modules.Session)

Players.PlayerAdded:Connect(function(player)
    local session = Session.new({player})
    SessionManager.Add(session)

    -- session.Table.Cards.Community:Push(Card.new("9", "Hearts"))
    -- session.Table.Cards.Community:Push(Card.new("4", "Clubs"))
    -- session.Table.Cards.Community:Push(Card.new("J", "Hearts"))
    -- session.Table.Cards.Community:Push(Card.new("4", "Spades"))
    -- session.Table.Cards.Community:Push(Card.new("9", "Clubs"))

    -- local _player1 = session.Table:GetPlayer(player)
    -- _player1.Hand:Push(Card.new("K", "Hearts"))
    -- _player1.Hand:Push(Card.new("4", "Hearts"))

    -- local _player2 = session.Table:GetPlayer({ UserId = 666 })
    -- _player2.Hand:Push(Card.new("A", "Hearts"))
    -- _player2.Hand:Push(Card.new("Q", "Clubs"))


    -- task.wait(1)
    -- session.Table:Deal()
    -- task.wait(1)
    -- session.Table:Deal()
    -- task.wait(1)
    -- session.Table:Deal()
    -- task.wait(1)
    -- session.Table:Deal()
    -- task.wait(1)
    -- session.Table:Deal()

    -- print(Pile.new(_player1.Hand:Best(session.Table.Cards.Community.Cards)):Rank())
    -- print(Pile.new(_player2.Hand:Best(session.Table.Cards.Community.Cards)):Rank())

    session:Start()

    local p1 = player
    local p2 = {UserId = 666}

    -- session.Table:Deal(p1)
    -- session.Table:Deal(p1)

    -- session.Table:Deal(p2)
    -- session.Table:Deal(p2)
end)
