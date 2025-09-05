--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage:WaitForChild("Modules")
local Card = require(Modules.Poker.Card)
local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)

local Match = require(Modules.Match)
local Managers = {
    Match = require(ServerStorage:WaitForChild("Managers").Match),
}

local __players = {}

Players.PlayerAdded:Connect(function(player)
    -- local match = Match.new({player, {UserId = 666}})
    -- Managers.Match.Add(match)

    -- match:Start()



    -- local Timer = require(Modules.Common.Timer)

    -- local timer = Timer.new()
    -- timer:Start(20, player)



    table.insert(__players, player)
    if #__players < 2 then return end

    task.wait(2)
    
    local p2 = table.remove(__players)
    local p1 = table.remove(__players)

    local match = Match.new({p1, p2})
    Managers.Match.Add(match)

    match:Start()



    -- local match = Match.new({player, {UserId = 666}})
    -- Managers.Match.Add(match)

    -- match.Table.Cards.Community:Push(Card.new("6", "Spades"))
    -- match.Table.Cards.Community:Push(Card.new("4", "Hearts"))
    -- match.Table.Cards.Community:Push(Card.new("4", "Clubs"))
    -- match.Table.Cards.Community:Push(Card.new("8", "Clubs"))
    -- match.Table.Cards.Community:Push(Card.new("8", "Spades"))

    -- local _player1 = match.Table:GetPlayer(player)
    -- _player1.Hand:Push(Card.new("A", "Clubs"))
    -- _player1.Hand:Push(Card.new("3", "Spades"))

    -- local _player2 = match.Table:GetPlayer({UserId = 666})
    -- _player2.Hand:Push(Card.new("2", "Hearts"))
    -- _player2.Hand:Push(Card.new("7", "Hearts"))

    -- print(_player1.Hand:Best(match.Table.Cards.Community.Cards))
    -- local pile1 = Pile.new(_player1.Hand:Best(match.Table.Cards.Community.Cards))
    -- print(pile1:Rank(), pile1:Score())

    -- print(_player2.Hand:Best(match.Table.Cards.Community.Cards))
    -- local pile2 = Pile.new(_player2.Hand:Best(match.Table.Cards.Community.Cards))
    -- print(pile2:Rank(), pile2:Score())
end)
