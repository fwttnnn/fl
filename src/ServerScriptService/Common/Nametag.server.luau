--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Storages = {
    Memory = {
        Players = require(ServerStorage:WaitForChild("Storages").Memory.Players),
    },
}

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local head: Head = character:WaitForChild("Head")
        local humanoid: Humanoid = character:WaitForChild("Humanoid")

        -- NOTE: remove default display name
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

        local tag = Instance.new("BillboardGui")
        tag.Size = UDim2.new(3, 0, 1, 0)
        tag.StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0)
        tag.AlwaysOnTop = false
        tag.Name = "Nametag"
        tag.Adornee = head
        tag.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.DisplayName

        local house = Storages.Memory.Players.Get(player).House
        if house then
            label.Text = "[" .. house.Symbol .. "] " .. label.Text
        end

        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.TextScaled = true
        label.Parent = tag
    end)
end)
