local camera = workspace.Camera
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")

local screenGui: ScreenGui = player.PlayerGui.ScreenGui

local Menu = {}

local button = Instance.new("TextButton", screenGui)
button.TextTransparency = 1
button.BackgroundTransparency = 1
button.Name = "Deck"
button.Text = "Deck"
button.TextScaled = true
button.BorderSizePixel = 0
button.BackgroundColor3 = Color3.fromHex("#fff")
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Position = UDim2.fromScale(0.5, 0.5)
button.Size = UDim2.fromScale(0.09, 0.046)

local offset = {
	X = -100,
	Y = 0,
}


local button2 = Instance.new("TextButton", screenGui)
button2.TextTransparency = 1
button2.BackgroundTransparency = 1
button2.Name = "Close"
button2.Text = "Close"
button2.TextScaled = true
button2.BorderSizePixel = 0
button2.BackgroundColor3 = Color3.fromHex("#fff")
button2.AnchorPoint = Vector2.new(0.5, 0.5)
button2.Position = UDim2.fromScale(0.5, 0.5)
button2.Size = UDim2.fromScale(0.09, 0.046)

local offset2 = {
	X = -100,
	Y = 50,
}

local isMenuOpened = false
local conn

game:GetService("UserInputService").InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end -- checks if another script had already processed the input, so this one gets ignored.
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.Q then
        isMenuOpened = not isMenuOpened

        if isMenuOpened then
            conn = rs.RenderStepped:Connect(function()
                local hrp2D, _ = camera:WorldToScreenPoint(hrp.Position)
                local tween = ts:Create(button,
                                        TweenInfo.new(0.25),
                                        {Position = UDim2.new(-button.Size.X.Scale/2,
                                                            (hrp2D.X - button.Size.X.Offset/2) + offset.X,
                                                            -button.Size.Y.Scale/2,
                                                            (hrp2D.Y - button.Size.Y.Offset/2) + offset.Y),
                                         BackgroundTransparency = 0,
                                         TextTransparency = 0,
                                         })
                tween:Play()

                local tween2 = ts:Create(button2,
                                        TweenInfo.new(0.25),
                                        {Position = UDim2.new(-button2.Size.X.Scale/2,
                                                            (hrp2D.X - button2.Size.X.Offset/2) + offset2.X,
                                                            -button2.Size.Y.Scale/2,
                                                            (hrp2D.Y - button2.Size.Y.Offset/2) + offset2.Y),
                                         BackgroundTransparency = 0,
                                         TextTransparency = 0,
                                         })
                tween2:Play()
            end)
        else
            conn:Disconnect()

            -- make button visible = false

            local tween = ts:Create(button,
                                    TweenInfo.new(0.25),
                                    {Position = UDim2.fromScale(0.5, 0.5),
                                     BackgroundTransparency = 1,
                                     TextTransparency = 1})
            tween:Play()

            local tween2 = ts:Create(button2,
                                    TweenInfo.new(0.25),
                                    {Position = UDim2.fromScale(0.5, 0.5),
                                     BackgroundTransparency = 1,
                                     TextTransparency = 1})
            tween2:Play()
        end
    end
end)
