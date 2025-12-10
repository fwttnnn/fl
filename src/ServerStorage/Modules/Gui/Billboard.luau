--!strict

-- NOTE: should be an Enum
local Billboard = {
    Types = {
        Stars = "Stars",
        Action = "Action",
        Timer = "Timer",
        Winner = "Winner",
        Health = "Health",
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
    billboard.Size = UDim2.new(3, 0, 1.5, 0)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
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
    layout.Padding = UDim.new(0, 0)

    local wrapper = Instance.new("Frame", frame)
    wrapper.Name = "Wrapper"
    wrapper.BackgroundTransparency = 1
    wrapper.Size = UDim2.fromScale(1, .5)

    local layout = layout:Clone()
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalFlex = Enum.UIFlexAlignment.SpaceAround
    -- layout.ItemLineAlignment = 
    layout.Padding = UDim.new(0, 8)
    layout.Parent = wrapper

    local nametagWrapper = wrapper:Clone()
    nametagWrapper.Name = "Nametag"
    nametagWrapper.Parent = frame

    local nametag = Instance.new("TextLabel", nametagWrapper)
    nametag.Name = "Label"
    nametag.Size = UDim2.fromScale(1, 1)
    nametag.BackgroundTransparency = 1
    nametag.Text = player.DisplayName

    local house = Storages.Global.House.Get(player)
    if house then
        nametag.Text = "[" .. house.Symbol .. "] " .. nametag.Text
    end

    nametag.TextColor3 = Color3.fromRGB(255, 255, 255)
    nametag.TextStrokeTransparency = .3
    nametag.Font = Enum.Font.GothamBold
    nametag.TextScaled = true

    -- NOTE: add this after we clone the nametag
    local left = Instance.new("Frame")
    left.Name = "Left"
    left.BackgroundTransparency = 1
    left.Size = UDim2.new(0.35, 0, 1, 0)
    left.LayoutOrder = 1
    left.Parent = wrapper

    local stars = Storages.Global.Stars.Get(player)

    local label = nametag:Clone()
    label.Name = Billboard.Types.Stars
    label.Text = stars .. " ★"
    label.Parent = left

    local right = Instance.new("Frame")
    right.Name = "Right"
    right.Visible = false
    right.BackgroundTransparency = 1
    right.Size = UDim2.new(0.5, 0, 1, 0)
    right.LayoutOrder = 2
    right.Parent = wrapper

    local label = nametag:Clone()
    label.Name = "Label"
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(255, 140, 0)
    label.Parent = right
end

function Billboard.Root(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local head: Head = character:WaitForChild("Head")
    return head:WaitForChild("Billboard")
end

function Billboard.Wrapper(player: Player)
    return Billboard.Root(player).Frame.Wrapper
end

function Billboard.Detach(player: Player)
    Billboard.Wrapper(player):Destroy()
    Billboard.Root(player):Destroy()
end

function Billboard.Add(player: Player, _type, arg: any)
    local _types = {
        [Billboard.Types.Action] = function(action)
            local wrapper = Billboard.Wrapper(player)
            wrapper.Right.Visible = true

            local label = wrapper.Right.Label
            label.Text = action.Type

            if action.Type ~= "ALL IN" then
                if action.Type == "BET" then
                    label.Text = action.Type .. " " .. action.Amount .. " ★"
                end
                if action.Type == "RAISE" then
                    label.Text = action.Type .. " TO " .. action.Amount .. " ★"
                end
            end
        end,

        [Billboard.Types.Timer] = function()
            local wrapper = Billboard.Wrapper(player)
            wrapper.Right.Visible = true

            local label = wrapper.Right.Label
            label.Text = ""
            -- local timerWrapper = Instance.new("Frame", wrapper)
            -- timerWrapper.Name = Billboard.Types.Timer
            -- timerWrapper.BackgroundTransparency = 1
            -- timerWrapper.Size = UDim2.fromScale(.7, .1)

            -- local timerProgressBar = Instance.new("Frame", timerWrapper)
            -- timerProgressBar.Name = "Bar"
            -- timerProgressBar.Size = UDim2.fromScale(1, 1)
        end,

        [Billboard.Types.Winner] = function(draw)
            local wrapper: Frame = Billboard.Wrapper(player)
            wrapper.Right.Visible = true

            local label = wrapper.Right.Label
            label.Text = draw and "DRAW" or "WINNER"
        end,

        -- [Billboard.Types.Health] = function()
        --     local wrapper = Billboard.Wrapper(player)
        --     local healthWrapper = Instance.new("Frame", wrapper)
        --     healthWrapper.Name = Billboard.Types.Health
        --     healthWrapper.BackgroundTransparency = 1
        --     healthWrapper.Size = UDim2.fromScale(.7, .3)
        --     healthWrapper.LayoutOrder = 9999 -- this should always be at the bottom

        --     Instance.new("UIStroke", healthWrapper)
        --     Instance.new("UICorner", healthWrapper).CornerRadius = UDim.new(.25)

        --     local healthBar = Instance.new("Frame", healthWrapper)
        --     healthBar.BorderSizePixel = 0
        --     healthBar.BackgroundColor3 = Color3.fromRGB(177, 0, 3)
        --     healthBar.BackgroundTransparency = .3
        --     healthBar.Name = "Bar"
        --     healthBar.Size = UDim2.fromScale(1, 1)

        --     local healthText = Instance.new("TextLabel", healthWrapper)
        --     healthText.Name = "Label"
        --     healthText.TextStrokeTransparency = 0
        --     healthText.BackgroundTransparency = 1
        --     healthText.Text = "100 / 100"
        --     healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
        --     healthText.TextScaled = true
        --     healthText.Size = UDim2.fromScale(1, 1)
        -- end,
    }
    
    local fn = _types[_type]
    if not fn then return end

    fn(arg)
end

function Billboard.Remove(player: Player, _type, arg: any)
    local _types = {
        [Billboard.Types.Action] = function()
            local wrapper = Billboard.Wrapper(player)
            local frame: Frame = wrapper.Right
            frame.Visible = false
        end,

        [Billboard.Types.Stars] = function()
            local wrapper = Billboard.Wrapper(player)
            local frame: Frame = wrapper.Left
            frame.Visible = false
        end,

        [Billboard.Types.Timer] = function()
            local wrapper = Billboard.Wrapper(player)
            local frame: Frame = wrapper.Right
            frame.Visible = false

            -- local timerWrapper: Frame = wrapper:FindFirstChild(Billboard.Types.Timer)
            -- if not timerWrapper then return end

            -- timerWrapper:Destroy()
        end,

        [Billboard.Types.Winner] = function()
            local wrapper = Billboard.Wrapper(player)
            local frame: Frame = wrapper.Right
            frame.Visible = false
        end,

        -- [Billboard.Types.Health] = function()
        --     local wrapper = Billboard.Wrapper(player)
        --     local healthWrapper: Frame = wrapper:FindFirstChild(Billboard.Types.Health)
        --     if not healthWrapper then return end

        --     healthWrapper:Destroy()
        -- end,
    }

    local fn = _types[_type]
    if not fn then return end

    fn(arg)
end

function Billboard.Update(player: Player, _type, arg: any)
    local _types = {
        [Billboard.Types.Action] = function()
        end,

        [Billboard.Types.Stars] = function(stars: number)
            local wrapper = Billboard.Wrapper(player)
            local label = wrapper.Left:FindFirstChild(Billboard.Types.Stars)
            label.Text = stars .. " ★"
        end,

        [Billboard.Types.Timer] = function(sec: number)
            local wrapper = Billboard.Wrapper(player)

            local label = wrapper.Right.Label
            label.Text = sec .. "s left"

            -- local timerWrapper: Frame = wrapper:FindFirstChild(Billboard.Types.Timer)
            -- if not timerWrapper then return end

            -- local bar = timerWrapper.Bar
            -- bar.Size = UDim2.fromScale(progress, 1)
        end,

        [Billboard.Types.Winner] = function()
        end,

        -- [Billboard.Types.Health] = function(health)
        --     local wrapper = Billboard.Wrapper(player)

        --     local healthWrapper: Frame = wrapper:FindFirstChild(Billboard.Types.Health)
        --     if not healthWrapper then return end

        --     local healthBar = healthWrapper.Bar
        --     healthBar.Size = UDim2.fromScale(health / 100, 1)

        --     local healthText = healthWrapper.Label
        --     healthText.Text = health .. " / 100"
        -- end,
    }

    local fn = _types[_type]
    if not fn then return end

    fn(arg)
end

return Billboard
