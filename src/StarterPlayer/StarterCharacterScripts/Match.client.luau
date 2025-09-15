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
        Events.Match.Act:FireServer({Type = "ALL IN"})
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
        Events.Match.Act:FireServer({Type = "ALL IN"})
    end)

    Buttons.Right.GUI.Text = "RAISE"
    setButtonCallback(Buttons.Right, function()
        -- TODO: create a user input
        assert(actions.Last.Amount ~= nil)
        local amount = 10

        if health < actions.Last.Amount + amount then
            print("[client/raise] cannot raise, you don't have enough health")
            return
        end

        Events.Match.Act:FireServer({Type = "RAISE", Amount = amount})
    end)

    Buttons.Upper.Right.GUI.Text = "FOLD"
    setButtonCallback(Buttons.Upper.Right, function()
        Events.Match.Act:FireServer({Type = "FOLD"})
    end)
end

buttonLayouts.Fold = function() buttonLayouts[actions.Last.Type or "Default"]() end
buttonLayouts.Bet = buttonLayouts.Call
buttonLayouts["All In"] = buttonLayouts.Bet
buttonLayouts["Raise"] = buttonLayouts.Bet
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
    -- NOTE: why the hell doesn't lua have a standard library duddd..
    -- SEE: http://lua-users.org/wiki/SciteTitleCase
    local function capitalize(str: string): string
        local buf = {}
        local inWord = false

        for i = 1, #str do
            local c = string.sub(str, i, i)
            if inWord then
                table.insert(buf, string.lower(c))
                if string.find(c, '%s') then
                    inWord = false
                end
            else
                table.insert(buf, string.upper(c))
                inWord = true
            end
        end

        return table.concat(buf)
    end

    action.Type = capitalize(action.Type)
    buttonLayouts[action.Type]()

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
