local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Act = ReplicatedStorage.Events.Match.Act,
    Acted = ReplicatedStorage.Events.Match.Acted,
    Timer = {
        Start = ReplicatedStorage.Events.Match.Timer.Start,
        Progress = ReplicatedStorage.Events.Match.Timer.Progress,
        End= ReplicatedStorage.Events.Match.Timer.End,
    },
}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

function disableButtons()
    for _, button in PlayerGui.ScreenGui.Buttons:GetChildren() do
        button.Visible = false
        button.Active = false
        button.Interactable = false
    end
end

function enableButtons()
    for _, button in PlayerGui.ScreenGui.Buttons:GetChildren() do
        button.Visible = true
        button.Active = true
        button.Interactable = true
    end
end

local Buttons = {}
for _, button in PlayerGui.ScreenGui.Buttons:GetChildren() do Buttons[button.Name] = button end
disableButtons()

Buttons.Left.MouseButton1Click:Connect(function()
    Events.Act:FireServer({Type = "CHECK"})
end)

Buttons.Middle.MouseButton1Click:Connect(function()
    -- NOTE: should be ALL IN
    Events.Act:FireServer({Type = "CALL" })
end)

Buttons.Right.MouseButton1Click:Connect(function()
    Events.Act:FireServer({Type = "BET", Amount = 100})
end)

Events.Act.OnClientEvent:Connect(function()
    enableButtons()
end)

Events.Acted.OnClientEvent:Connect(function()
    disableButtons()
end)

local BarUI = PlayerGui.ScreenGui.Timer.Wrapper.Bar

Events.Timer.Start.OnClientEvent:Connect(function()
    BarUI.BackgroundTransparency = 0
    BarUI.Size = UDim2.new(1, 0, 1, 0)
end)

Events.Timer.Progress.OnClientEvent:Connect(function(progress)
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    print(progress)

    -- BarUI.Size = BarUI.Size:Lerp(UDim2.new(progress, 0, 1, 0), 0.1)
    BarUI.Size = UDim2.new(progress, 0, 1, 0)
end)

Events.Timer.End.OnClientEvent:Connect(function()
    BarUI.BackgroundTransparency = 1
    BarUI.Size = UDim2.new(0, 0, 1, 0)
end)
