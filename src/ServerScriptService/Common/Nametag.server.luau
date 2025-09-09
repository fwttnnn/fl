--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
    },
}

Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAdded:Connect(function(character: Model)
        local head: Head = character:WaitForChild("Head")
        local humanoid: Humanoid = character:WaitForChild("Humanoid")

        -- NOTE: remove default display name
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

        -- local billboard = Instance.new("Part", head)
        -- billboard.Name = "Billboard"
        -- billboard.Size = Vector3.new(3, 1, 0.001)
        -- billboard.Anchored = true
        -- billboard.Massless = true
        -- billboard.CanCollide = false
        -- billboard.Transparency = 1
        -- billboard:SetAttribute("Billboard", true)
        -- billboard:SetAttribute("Attached", true)
        -- billboard:SetAttribute("Offset", Vector3.new(0, 1.8, 0))

        -- local gui = Instance.new("SurfaceGui", billboard)
        -- gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        -- gui.PixelsPerStud = 100
        -- gui.Face = Enum.NormalId.Back

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(3, 0, 1, 0)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0)
        billboard.AlwaysOnTop = false
        billboard.Name = "Nametag"
        billboard.Adornee = head
        billboard.Parent = head

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.DisplayName

        local house = Storages.Global.House.Get(player)
        if house then
            label.Text = "[" .. house.Symbol .. "] " .. label.Text
        end

        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
    end)
end)
