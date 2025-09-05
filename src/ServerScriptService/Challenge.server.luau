--!strict
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Character)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Challenge"
        prompt.ObjectText = player.DisplayName
        prompt.MaxActivationDistance = 10
        prompt.HoldDuration = 1
        prompt.RequiresLineOfSight = false
        prompt.Parent = character:WaitForChild("HumanoidRootPart")
        
        prompt.Triggered:Connect(function(challenger: Player)
            -- ...
        end)
    end)
end)
