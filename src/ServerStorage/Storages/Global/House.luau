--!strict
local House = {
    Suits = {
        Spade = {
            Name = "Spade",
            Symbol = "♠",
            Color = {
                Primary = Color3.fromRGB(0, 0, 0),
                Secondary = Color3.fromRGB(255, 255, 255),
            },
        },
        Club = {
            Name = "Club",
            Symbol = "♣",
            Color = {
                Primary = Color3.fromRGB(0, 0, 0),
                Secondary = Color3.fromRGB(255, 255, 255),
            }
        },
        Diamond = {
            Name = "Diamond",
            Symbol = "♦",
            Color = {
                Primary = Color3.fromRGB(255, 0, 0),
                Secondary = Color3.fromRGB(0, 0, 0),
            }
        },
        Heart = {
            Name = "Heart",
            Symbol = "♥",
            Color = {
                Primary = Color3.fromRGB(255, 0, 0),
                Secondary = Color3.fromRGB(0, 0, 0),
            }
        },
    },
}

local DataStoreService = game:GetService("DataStoreService")
local Stores = {
    House = DataStoreService:GetDataStore("House"),
    Counter = DataStoreService:GetDataStore("Counter"),
}

function House.Join(player: Player, house: string): boolean
    if not House.Suits[house] then return false end

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

    return House.Suits[house]
end

return House
