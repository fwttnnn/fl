--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
    },
}

local Functions = {
    House = {
        Get = ReplicatedStorage.Functions.House.Get,
    },
}

Functions.House.Get.OnServerInvoke = function(player: Player) -- TODO: typeof house
    return Storages.Global.House.Get(player)
end
