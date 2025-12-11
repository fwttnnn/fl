--!strict

-- NOTE: should be an Enum
local Billboard = {
    Types = {
        Stars = "Stars",
        Floating = "Floating",
    }
}

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
        Stars = require(ServerStorage:WaitForChild("Storages").Global.Stars),
    },
}

-- maybe merge dis with Add
function Billboard.Attach(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
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
    billboard.Size = UDim2.new(3, 0, 2.5, 0)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = false
    billboard.Name = "Billboard"
    billboard.Adornee = head
    billboard.Parent = head

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", frame)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 7)

    local wrapper = Instance.new("Frame")
    wrapper.Name = "Wrapper"
    wrapper.BackgroundTransparency = 1
    wrapper.Size = UDim2.fromScale(1, .5)

    local layout = layout:Clone()
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalFlex = Enum.UIFlexAlignment.SpaceAround
    -- layout.ItemLineAlignment = 
    layout.Padding = UDim.new(0, 8)
    layout.Parent = wrapper

    local floatingWrapper = wrapper:Clone()
    floatingWrapper.Size = UDim2.fromScale(1, .20)
    floatingWrapper.Name = "Floating"
    floatingWrapper.Parent = frame

    local floatingLabel = Instance.new("TextLabel", floatingWrapper)
    floatingLabel.Name = "Label"
    floatingLabel.Size = UDim2.fromScale(1, 1)
    floatingLabel.BackgroundTransparency = 1
    floatingLabel.Text = ""
    -- #ddff00
    floatingLabel.TextColor3 = Color3.fromRGB(221, 255, 0)
    floatingLabel.TextStrokeTransparency = .3
    floatingLabel.Font = Enum.Font.GothamBold
    floatingLabel.TextScaled = true

    local starsWrapper = wrapper:Clone()
    starsWrapper.Size = UDim2.fromScale(1, .22)
    starsWrapper.Name = "Stars"
    starsWrapper.Parent = frame

    local stars = Storages.Global.Stars.Get(player)
    local starsLabel = Instance.new("TextLabel", starsWrapper)
    starsLabel.Name = "Label"
    starsLabel.Size = UDim2.fromScale(1, 1)
    starsLabel.BackgroundTransparency = 1
    starsLabel.Text = stars .. " ★"
    starsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    starsLabel.TextStrokeTransparency = .3
    starsLabel.Font = Enum.Font.GothamBold
    starsLabel.TextScaled = true

    local nametagWrapper = wrapper:Clone()
    nametagWrapper.Size = UDim2.fromScale(1, .30)
    nametagWrapper.Name = "Nametag"
    nametagWrapper.Parent = frame

    local nametagLabel = Instance.new("TextLabel", nametagWrapper)
    nametagLabel.Name = "Label"
    nametagLabel.Size = UDim2.fromScale(1, 1)
    nametagLabel.BackgroundTransparency = 1
    nametagLabel.Text = player.DisplayName

    local house = Storages.Global.House.Get(player)
    if house then
        nametagLabel.Text = "[" .. house.Symbol .. "] " .. nametagLabel.Text
    end

    nametagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nametagLabel.TextStrokeTransparency = .3
    nametagLabel.Font = Enum.Font.GothamBold
    nametagLabel.TextScaled = true

    -- local unusedWrapper = wrapper:Clone()
    -- unusedWrapper.Name = "Unused"
    -- unusedWrapper.Parent = frame
end

function Billboard.Root(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local head: Head = character:WaitForChild("Head")
    return head:WaitForChild("Billboard")
end

function Billboard.Wrapper(player: Player)
    return Billboard.Root(player).Frame
end

function Billboard.Detach(player: Player)
    Billboard.Wrapper(player):Destroy()
    Billboard.Root(player):Destroy()
end

function Billboard.Set(player: Player, _type, text: string)
    local _types = {
        [Billboard.Types.Floating] = function()
            Billboard.Wrapper(player):FindFirstChild(_type).Label.Text = text
        end,
        [Billboard.Types.Stars] = function()
            Billboard.Wrapper(player):FindFirstChild(_type).Label.Text = text
        end
    }

    local fn = _types[_type]
    if not fn then return end

    fn(arg)
end

return Billboard
