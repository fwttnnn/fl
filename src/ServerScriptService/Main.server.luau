--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage:WaitForChild("Modules")
local Card = require(Modules.Poker.Card)
local Pile = require(Modules.Poker.Pile)
local Table = require(Modules.Poker.Table)

local Chips = require(Modules.Poker.Economy.Chips)
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
end)

-- NOTE: listen for players to join, for testing purposes.
task.spawn(function()
    while true do
        task.wait(0.5)
        if #__players < 2 then continue end
        task.wait(4)

        local p2 = table.remove(__players)
        local p1 = table.remove(__players)

        Chips.Gain(p2, 500)
        Chips.Gain(p1, 500)

        local match = Match.new({p1, p2})
        Storages.Memory.Matches.Add(match)
        match:Start()
    end
end)
