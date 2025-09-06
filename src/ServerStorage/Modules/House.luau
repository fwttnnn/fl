--!strict
local House = {}

local DataStoreService = game:GetService("DataStoreService")
local Stores = {
    House = DataStoreService:GetDataStore("House"),
    Counter = DataStoreService:GetDataStore("Counter"),
}

local Houses = {
    Spade = {
        Name = "Spade",
        Symbol = "♠",
    },
    Club = {
        Name = "Club",
        Symbol = "♣",
    },
    Diamond = {
        Name = "Diamond",
        Symbol = "♦",
    },
    Heart = {
        Name = "Heart",
        Symbol = "♥",
    },
}

function House.Join(player: Player, house: string): boolean
    if not Houses[house] then return false end

    local success = pcall(function()
        Stores.House:SetAsync(player.UserId, house)
    end)

    return success
end

function House.Leave(player: Player): boolean
    local success = pcall(function()
        Stores.House:RemoveAsync(player.UserId)
    end)

    return success
end

function House.Get(player: Player) -- TODO: return typeof house
    local success, house = pcall(function()
        return Stores.House:GetAsync(player.UserId)
    end)

    return Houses[house]
end

return House
