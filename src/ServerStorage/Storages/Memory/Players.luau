--!strict
-- players storage, a memory cache for player.
local Storage = {}

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local House = require(Modules.House)
local Chips = require(Modules.Poker.Economy.Chips)

function Storage.Get(player: Player)
    return Storage[player.UserId]
end

function Storage.Set(player: Player, key: string, val)
    if not Storage[player.UserId] then
        Storage[player.UserId] = {}
    end

    Storage[player.UserId][key] = val
end

function Storage.Load(player: Player)
    Storage[player.UserId] = {
        House = House.Get(player),
        Chips = Chips.Get(player),
    }
end

return Storage
