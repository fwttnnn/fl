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

function Stars.Add(player: Player, n: number): boolean
    local success = pcall(function()
        StarsStore:UpdateAsync(player.UserId, function(stars)
            stars = stars or 0
            return stars + n
        end)
    end)

    return success
end

function Stars.Subtract(player: Player, n: number): boolean
    local success = pcall(function()
        StarsStore:UpdateAsync(player.UserId, function(stars)
            stars = stars or 0
            return math.max(0, stars - n)
        end)
    end)

    return success
end

return Stars
