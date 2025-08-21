local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remote = {
    Event = {
        Act = ReplicatedStorage.Events.Session.Act,
        Timer = ReplicatedStorage.Events.Session.Timer,
    },
    Function = {
        Act = ReplicatedStorage.Functions.Session.Act,
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
    if not Remote.Function.Act:InvokeServer({Type = "CHECK"}) then return end
    disableButtons()
end)

Buttons.Middle.MouseButton1Click:Connect(function()
    -- NOTE: should be ALL IN
    if not Remote.Function.Act:InvokeServer({Type = "CALL" }) then return end
    disableButtons()
end)

Buttons.Right.MouseButton1Click:Connect(function()
    if not Remote.Function.Act:InvokeServer({Type = "BET", Amount = 100}) then return end
    disableButtons()
end)

Remote.Event.Act.OnClientEvent:Connect(function()
    enableButtons()
end)
