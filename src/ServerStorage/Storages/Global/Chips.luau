--!strict
local Chips = {}

local DataStoreService = game:GetService("DataStoreService")
local Stores = {
    Chips = DataStoreService:GetDataStore("Chips"),
}

function Chips.Gain(player: Player, amount: number): number
    local chips = Chips.Get(player)

    local success = pcall(function()
        chips += amount
        Stores.Chips:SetAsync(player.UserId, chips)
    end)

    return chips
end

function Chips.Lose(player: Player, amount: number): number
    local chips = Chips.Get(player)

    local success = pcall(function()
        chips -= amount
        Stores.Chips:SetAsync(player.UserId, chips)
    end)

    return chips
end

function Chips.Get(player: Player): number
    local success, chips = pcall(function()
        return Stores.Chips:GetAsync(player.UserId)
    end)

    return chips or 0
end

function Chips.Has(player: Player, amount: number): boolean
    local chips = Chips.Get(player)
    return chips >= amount
end

return Chips
