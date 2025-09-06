--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerStorage:WaitForChild("Modules")
local House = require(Modules.House)

local Functions = {
    House = {
        Get = ReplicatedStorage.Functions.House.Get,
    },
}

Functions.House.Get.OnServerInvoke = function(player: Player) -- TODO: typeof house
    return House.Get(player)
end
