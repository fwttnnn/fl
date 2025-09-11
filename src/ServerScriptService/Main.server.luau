--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage:WaitForChild("Modules")
local Card = require(Modules.Poker.Card)
local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)
local Match = require(Modules.Match)

local Storages = {
    Memory = {
        Matches = require(ServerStorage:WaitForChild("Storages").Memory.Matches),
        Players = require(ServerStorage:WaitForChild("Storages").Memory.Players),
    },
}

local __players = {}
Players.PlayerAdded:Connect(function(player)
    table.insert(__players, player)
    Storages.Memory.Players.Load(player)

    -- local match = Match.new({player, {UserId = 666}})
    -- Storages.Memory.Matches.Add(match)

    -- match.Table:Deal()
    -- match.Table:Deal()
    -- match.Table:Deal()
    -- match.Table:Deal()
    -- match.Table:Deal()

    -- match.Table.Cards.Community:Push(Card.new("4", "Clubs"))
    -- match.Table.Cards.Community:Push(Card.new("Q", "Diamonds"))
    -- match.Table.Cards.Community:Push(Card.new("J", "Spades"))
    -- match.Table.Cards.Community:Push(Card.new("10", "Spades"))
    -- match.Table.Cards.Community:Push(Card.new("J", "Hearts"))

    -- local _player1 = match.Table:GetPlayer(player)
    -- _player1.Hand:Push(Card.new("6", "Clubs"))
    -- _player1.Hand:Push(Card.new("6", "Hearts"))

    -- local _player2 = match.Table:GetPlayer({UserId = 666})
    -- _player2.Hand:Push(Card.new("6", "Hearts"))
    -- _player2.Hand:Push(Card.new("3", "Diamonds"))

    -- local hands = {}
    -- for _, _player in ipairs(match.Table.Players) do
    --     if not _player.Active then continue end

    --     local hand = Pile.new(_player.Hand:Best(match.Table.Cards.Community.Cards))
    --     table.insert(hands, {Player = _player.Player,
    --                          Hand = hand,
    --                          Rank = hand:Rank(),
    --                          Score = hand:Score()})
    -- end

    -- table.sort(hands, function(a, b)
    --     if a.Rank == b.Rank then
    --         return a.Score > b.Score
    --     end

    --     return a.Rank > b.Rank
    -- end)

    -- print("table ::", match.Table.Cards.Community)

    -- local winner = hands[1]
    -- print("[end] match ended, winner: " .. winner.Rank .. " @ " ..  winner.Score)
    -- print(winner.Hand)

    -- for i = 2, #hands do
    --     print("[end] others: " .. hands[i].Rank .. " @ " .. hands[i].Score)
    --     print(hands[i].Hand)
    -- end
end)

-- NOTE: listen for players to join, for testing purposes.
task.spawn(function()
    while true do
        task.wait(0.5)
        if #__players < 2 then continue end
        task.wait(4)

        local p2 = table.remove(__players)
        local p1 = table.remove(__players)

        local match = Match.new({p1, p2})
        Storages.Memory.Matches.Add(match)
        match:Start()
    end
end)
