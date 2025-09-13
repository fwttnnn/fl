local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = {
    Match = {
        Act = ReplicatedStorage.Events.Match.Act,
        Acted = ReplicatedStorage.Events.Match.Acted,
        Action = ReplicatedStorage.Events.Match.Action,
        Turn = {
            Started = ReplicatedStorage.Events.Match.Turn.Started,
            Betting = {
                Started = ReplicatedStorage.Events.Match.Turn.Betting.Started,
            },
        },
        Winner = ReplicatedStorage.Events.Match.Winner,
    },
    Timer = {
        Start = ReplicatedStorage.Events.Timer.Start,
        Progress = ReplicatedStorage.Events.Timer.Progress,
        End = ReplicatedStorage.Events.Timer.End,
    },
}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local health = 0
local actions = {
    -- NOTE: action 'Fold' will never appear here.
    Last = {
        Type = nil,
        Amount = nil,
    },
}

function disableButtons()
    for _, obj in PlayerGui.ScreenGui.Buttons:GetDescendants() do
        if not obj:IsA("TextButton") then continue end

        local button: TextButton = obj
        button.Active = false
        button.Interactable = false

        local frame: Frame = button.Parent
        frame.Visible = false
    end
end

function enableButtons()
    for _, obj in PlayerGui.ScreenGui.Buttons:GetDescendants() do
        if not obj:IsA("TextButton") then continue end

        local button: TextButton = obj
        button.Active = true
        button.Interactable = true

        local frame: Frame = button.Parent
        frame.Visible = true
    end
end

function setButtonCallback(button, fn)
    if button.Connection then
        button.Connection:Disconnect()
    end

    button.Connection = button.GUI.MouseButton1Click:Connect(fn)
end

--
-- Buttons
--

local Buttons = {}
for _, obj in PlayerGui.ScreenGui.Buttons:GetDescendants() do 
    if not obj:IsA("TextButton") then continue end

    local button: Button = obj
    local name: string = button.Parent.Name

    Buttons[name] = {
        GUI = button,
        Connection = nil,
    }
end

Buttons.Upper = {}
for _, obj in PlayerGui.ScreenGui.Buttons.Upper:GetDescendants() do 
    if not obj:IsA("TextButton") then continue end

    local button: Button = obj
    local name: string = button.Parent.Name

    Buttons.Upper[name] = {
        GUI = button,
        Connection = nil,
    }
end

-- NOTE: naming based on last action
local buttonLayouts = {}

buttonLayouts.Check = function()
    Buttons.Left.GUI.Text = "CHECK"
    setButtonCallback(Buttons.Left, function()
        Events.Match.Act:FireServer({Type = "CHECK"})
    end)

    Buttons.Middle.GUI.Text = "ALL IN"
    setButtonCallback(Buttons.Middle, function()
        assert(health > 0)
        Events.Match.Act:FireServer({Type = "BET", Amount = health})
    end)

    Buttons.Right.GUI.Text = "BET"
    setButtonCallback(Buttons.Right, function()
        -- TODO: create a user input
        local amount = 10

        if health < amount then
            print("[client/bet] cannot bet, you don't have enough health")
            return
        end

        Events.Match.Act:FireServer({Type = "BET", Amount = amount})
    end)

    Buttons.Upper.Right.GUI.Text = "FOLD"
    setButtonCallback(Buttons.Upper.Right, function()
        Events.Match.Act:FireServer({Type = "FOLD"})
    end)
end

buttonLayouts.Call = function()
    Buttons.Left.GUI.Text = "CALL"
    setButtonCallback(Buttons.Left, function()
        Events.Match.Act:FireServer({Type = "CALL"})
    end)

    Buttons.Middle.GUI.Text = "ALL IN"
    setButtonCallback(Buttons.Middle, function()
        assert(health > 0)
        Events.Match.Act:FireServer({Type = "BET", Amount = health})
    end)

    Buttons.Right.GUI.Text = "RAISE"
    setButtonCallback(Buttons.Right, function()
        -- TODO: create a user input
        assert(actions.Last.Amount ~= nil)
        local amount = actions.Last.Amount + 10

        if health < amount then
            print("[client/raise] cannot raise, you don't have enough health")
            return
        end

        Events.Match.Act:FireServer({Type = "BET", Amount = amount})
    end)

    Buttons.Upper.Right.GUI.Text = "FOLD"
    setButtonCallback(Buttons.Upper.Right, function()
        Events.Match.Act:FireServer({Type = "FOLD"})
    end)
end

buttonLayouts.Fold = function() buttonLayouts[actions.Last.Type or "Default"]() end
buttonLayouts.Bet = buttonLayouts.Call
buttonLayouts.Default = buttonLayouts.Check
buttonLayouts.Default()

disableButtons()

--
-- Events
--

Events.Match.Turn.Started.OnClientEvent:Connect(function(_health)
    health = _health
    actions.Last = {
        Type = nil,
        Amount = nil,
    }
end)

Events.Match.Act.OnClientEvent:Connect(function(_health)
    enableButtons()

    health = _health
end)

Events.Match.Acted.OnClientEvent:Connect(function(_health)
    disableButtons()

    health = _health
end)

Events.Match.Action.OnClientEvent:Connect(function(player, action)
    if not action.Type then return print("[action]", player.DisplayName .. " did not acted") end

    -- NOTE: only a word, why the hell doesn't lua have a standard library
    local function capitalize(word: string): string
        return (word:sub(1,1):upper() .. word:sub(2):lower())
    end

    action.Type = capitalize(action.Type)
    buttonLayouts[action.Type]()

    print("[action]", player.DisplayName .. " acted " .. action.Type, action.Amount)

    if action.Type == "Fold" then
        return
    end

    actions.Last = action
end)

Events.Match.Turn.Betting.Started.OnClientEvent:Connect(function()
    actions.Last = {
        Type = nil,
        Amount = nil,
    }

    buttonLayouts.Default()
end)

Events.Match.Winner.OnClientEvent:Connect(function(player)
    local function _handleWin()
        local me = Player
        local winner = player.UserId == me.UserId and "You" or player.DisplayName

        local label = PlayerGui.ScreenGui.Broadcast
        label.Text = winner .. " won the match."
        label.TextTransparency = 0

        local tweenInfo = TweenInfo.new(
            2, -- seconds
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out,
            0, -- repeat count
            false, -- reverses?
            5 -- delay before tween starts
        )

        local tween = TweenService:Create(label, tweenInfo, {TextTransparency = 1})
        tween:Play()
    end

    local function _handleDraw()
        local label = PlayerGui.ScreenGui.Broadcast
        label.Text = "The match ended in a draw."
        label.TextTransparency = 0

        local tweenInfo = TweenInfo.new(
            2, -- seconds
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out,
            0, -- repeat count
            false, -- reverses?
            5 -- delay before tween starts
        )

        local tween = TweenService:Create(label, tweenInfo, {TextTransparency = 1})
        tween:Play()
    end

    if not player then
        return _handleDraw()
    end

    _handleWin()
end)

--
-- Timer GUI
--

local BarGUI = PlayerGui.ScreenGui.Timer.Wrapper.Bar

Events.Timer.Start.OnClientEvent:Connect(function()
    BarGUI.BackgroundTransparency = 0
    BarGUI.Size = UDim2.new(1, 0, 1, 0)
end)

Events.Timer.Progress.OnClientEvent:Connect(function(progress)
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    -- print(progress)

    -- BarGUI.Size = BarGUI.Size:Lerp(UDim2.new(progress, 0, 1, 0), 0.1)
    BarGUI.Size = UDim2.new(progress, 0, 1, 0)
end)

Events.Timer.End.OnClientEvent:Connect(function()
    BarGUI.BackgroundTransparency = 1
    BarGUI.Size = UDim2.new(0, 0, 1, 0)
end)
