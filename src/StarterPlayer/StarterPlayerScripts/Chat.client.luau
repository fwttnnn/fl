--!strict
-- why the hell does the text chat service must be handled through client?
-- also, what the fuck is message properties.

local TextChatService = game:GetService("TextChatService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Functions = {
    House = {
        Get = ReplicatedStorage.Functions.House.Get,
    },
}

-- NOTE: cache
-- TODO: if player changed house then it's stuck
local house = Functions.House.Get:InvokeServer()

-- TODO: investigate on why this ran twice (print)
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
    if not message.TextSource then return end

    local player = Players:GetPlayerByUserId(message.TextSource.UserId)
    if not player then return end

    -- NOTE: see https://create.roblox.com/docs/reference/engine/classes/TextChatMessageProperties
    local properties = TextChatService.ChatWindowConfiguration:DeriveNewMessageProperties()

    properties.PrefixText = player.DisplayName .. ":"
    if house then
        properties.PrefixText = "[" .. house.Symbol .. " " .. house.Name .. "] " .. properties.PrefixText
    end

    message.ChatWindowMessageProperties = properties
    return properties
end
