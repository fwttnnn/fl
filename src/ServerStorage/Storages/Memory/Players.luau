--!strict
-- players storage, a memory cache for player.
local Storage = {}

local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
        Stars = require(ServerStorage:WaitForChild("Storages").Global.Stars),
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

function Storage.Load(player: Player, reload: boolean)
    if not reload and Storage[player.UserId] then
        return Storage[player.UserId]
    end

    local success, url = pcall(function()
        local id = player.UserId
        if id < 0 then id = 1531539874 end -- NOTE: on test

        return Players:GetUserThumbnailAsync(id,
                                             Enum.ThumbnailType.HeadShot,
                                             Enum.ThumbnailSize.Size420x420)
    end)

    if not success then
        warn("uh, can't fetch " .. player.DisplayName .. " icon")
        warn(url)
    end

    Storage[player.UserId] = {
        House = Storages.Global.House.Get(player),
        Stars = Storages.Global.Stars.Get(player),
        Icon = url,
    }

    return Storage[player.UserId]
end

return Storage
