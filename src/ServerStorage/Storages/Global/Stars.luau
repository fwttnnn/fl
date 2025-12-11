--!strict
local Stars = {}

local DataStoreService = game:GetService("DataStoreService")
local Stores = {
    Stars = DataStoreService:GetDataStore("--stars"),
}

function Stars.Get(player: Player)
    local success, stars = pcall(function()
        return Stores.Stars:GetAsync(player.UserId)
    end)

    -- NOTE: initialize (first comer)
    if success and stars == nil then
        stars = 500
        pcall(function()
            Stores.Stars:SetAsync(player.UserId, stars)
        end)
    end

    return stars
end

function Stars.Gain(player: Player, n: number): boolean
    local success = pcall(function()
        Stores.Stars:UpdateAsync(player.UserId, function(stars)
            stars = stars or 0
            return math.min(999, stars + n)
        end)
    end)

    return success
end

function Stars.Lose(player: Player, n: number): boolean
    local success = pcall(function()
        Stores.Stars:UpdateAsync(player.UserId, function(stars)
            stars = stars or 0
            return math.max(0, stars - n)
        end)
    end)

    return success
end

return Stars
