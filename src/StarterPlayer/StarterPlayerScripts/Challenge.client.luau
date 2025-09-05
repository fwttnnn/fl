--!strict
local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.CharacterAdded:Connect(function(character: Model)
    character.ChildAdded:Connect(function(child)
        if not child:IsA("ProximityPrompt") then return end

        local prompt = child
        prompt.Enabled = false
    end)

    for _, descendant in ipairs(character:GetDescendants()) do
        if not descendant:IsA("ProximityPrompt") then continue end

        local prompt = descendant
        prompt.Enabled = false
    end
end)
