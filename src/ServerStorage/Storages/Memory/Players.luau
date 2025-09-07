--!strict
-- players storage, a memory cache for player.
local Storage = {}

local ServerStorage = game:GetService("ServerStorage")
local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
        Chips = require(ServerStorage:WaitForChild("Storages").Global.Chips),
    },
}

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
        House = Storages.Global.House.Get(player),
        Chips = Storages.Global.Chips.Get(player),
    }

    return Storage[player.UserId]
end

return Storage
