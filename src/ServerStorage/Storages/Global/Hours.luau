--!strict
-- stores how many hours (the economy) a player has.
local Hours = {
    INITIAL = 730,
    MIN = 0,
    MAX = 100000,
}

local DataStoreService = game:GetService("DataStoreService")
local Stores = {
    Hours = DataStoreService:GetDataStore("--hours"),
}

function Hours.Get(player: Player)
    local success, hours = pcall(function()
        return Stores.Hours:GetAsync(player.UserId)
    end)

    -- NOTE: initialize (first comer)
    if success and hours == nil then
        hours = Hours.INITIAL,
        pcall(function()
            Stores.Hours:SetAsync(player.UserId, hours)
        end)
    end

    return hours
end

function Hours.Gain(player: Player, n: number): boolean
    local success = pcall(function()
        Stores.Hours:UpdateAsync(player.UserId, function(hours)
            hours = hours or 0
            return math.min(Hours.MAX, hours + n)
        end)
    end)

    return success
end

function Hours.Lose(player: Player, n: number): boolean
    local success = pcall(function()
        Stores.Hours:UpdateAsync(player.UserId, function(hours)
            hours = hours or 0
            return math.max(Hours.MIN, hours - n)
        end)
    end)

    return success
end

return Hours
