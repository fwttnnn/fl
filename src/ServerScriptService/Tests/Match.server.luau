--!strict
local Test = {}

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Card = require(Modules.Poker.Card)
local Match = require(Modules.Match)

function Test.IDontKnow()
    local _p1 = {UserId = 1, DisplayName = "A"}
    local _p2 = {UserId = 2, DisplayName = "B"}

    local match = Match.new({_p1, _p2})
    match.Table.Cards.Community:Push(Card.new("4", "Clubs"))
    match.Table.Cards.Community:Push(Card.new("Q", "Diamonds"))
    match.Table.Cards.Community:Push(Card.new("J", "Spades"))
    match.Table.Cards.Community:Push(Card.new("10", "Spades"))
    match.Table.Cards.Community:Push(Card.new("J", "Hearts"))

    local _player1 = match.Table:GetPlayer(_p1)
    _player1.Hand:Push(Card.new("6", "Clubs"))
    _player1.Hand:Push(Card.new("6", "Hearts"))

    local _player2 = match.Table:GetPlayer(_p2)
    _player2.Hand:Push(Card.new("6", "Hearts"))
    _player2.Hand:Push(Card.new("3", "Diamonds"))

    local winners = match:_TurnShowdown()

    local draw = #winners > 1
    local winner = winners[1].Player

    assert(not draw, "expected to not draw")
    assert(winner.UserId == _p1.UserId, "expected p1 to win")
end

function Test.All()
    -- TODO: gather all functions (automatically) and fire it all here.
    Test.IDontKnow()
end

Test.All()
