local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local hours = 0
local bet = 10
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

Buttons.Arrows = {}
for _, obj in PlayerGui.ScreenGui.Buttons.Arrows:GetDescendants() do 
    if not obj:IsA("TextButton") then continue end

    local button: Button = obj
    local name: string = button.Parent.Name

    Buttons.Arrows[name] = {
        GUI = button,
        Connection = nil,
    }
end

local function _first_word(str: string): string
    local space_index = string.find(str, " ")
    if space_index then
        return string.sub(str, 1, space_index - 1)
    end
    
    return str 
end

setButtonCallback(Buttons.Arrows.Increase, function()
    local _type = _first_word(Buttons.Right.GUI.Text)
    local handlers = {
        ["BET"] = function()
            bet = math.min(bet + 10, hours)
            Buttons.Right.GUI.Text = _type .. " " .. bet .. "H"
        end,
        ["RAISE"] = function()
            bet += 10

            if actions.Last.Amount + bet > hours then
                bet = math.max(0, hours - actions.Last.Amount)
            end

            Buttons.Right.GUI.Text = _type .. " TO " .. actions.Last.Amount + bet .. "H"
        end,
    }

    handlers[_type]()
end)

setButtonCallback(Buttons.Arrows.Decrease, function()
    local _type = _first_word(Buttons.Right.GUI.Text)
    local handlers = {
        ["BET"] = function()
            bet = math.max(bet - 5, 10)
            Buttons.Right.GUI.Text = _type .. " " .. bet .. "H"
        end,
        ["RAISE"] = function()
            bet = math.max(bet - 5, 10)
            Buttons.Right.GUI.Text = _type .. " TO " .. actions.Last.Amount + bet .. "H"
        end,
    }

    handlers[_type]()
end)

-- NOTE: naming based on last action
local buttonLayouts = {}

buttonLayouts.CHECK = function()
    Buttons.Left.GUI.Text = "CHECK"
    setButtonCallback(Buttons.Left, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "CHECK"})
    end)

    Buttons.Middle.GUI.Text = "ALL IN"
    setButtonCallback(Buttons.Middle, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "ALL IN"})
    end)

    Buttons.Right.GUI.Text = "BET " .. bet .. "H"
    setButtonCallback(Buttons.Right, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "BET", Amount = bet})
        bet = 10
    end)

    Buttons.Upper.Right.GUI.Text = "FOLD"
    setButtonCallback(Buttons.Upper.Right, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "FOLD"})
    end)
end

buttonLayouts.CALL = function()
    assert(actions.Last.Amount ~= nil)

    Buttons.Left.GUI.Text = "CALL"
    setButtonCallback(Buttons.Left, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "CALL"})
    end)

    Buttons.Middle.GUI.Text = "ALL IN"
    setButtonCallback(Buttons.Middle, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "ALL IN"})
    end)

    Buttons.Right.GUI.Text = "RAISE TO " .. actions.Last.Amount + bet .. "H"
    setButtonCallback(Buttons.Right, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "RAISE", Amount = bet})
        bet = 10
    end)

    Buttons.Upper.Right.GUI.Text = "FOLD"
    setButtonCallback(Buttons.Upper.Right, function()
        Events.Match.Turn.Betting.Act:FireServer({Type = "FOLD"})
    end)
end

buttonLayouts.FOLD      = function() buttonLayouts[actions.Last.Type or "DEFAULT"]() end
buttonLayouts.BET       = buttonLayouts.CALL
buttonLayouts["ALL IN"] = buttonLayouts.BET
buttonLayouts["RAISE"]  = buttonLayouts.BET
buttonLayouts.DEFAULT   = buttonLayouts.CHECK

disableButtons()
buttonLayouts.DEFAULT()

--
-- Events
--

Events.Match.Started.OnClientEvent:Connect(function(players)
    PlayerGui.ScreenGui.Action.Visible = true

    for i, p in ipairs(players) do
        -- TODO: rename `GUI`
        local GUI = ReplicatedStorage.GUI.Action.Player:Clone()
        GUI.Name = p.Player.UserId
        GUI.Player.Text = p.Player.DisplayName
        GUI.Hours.Text = p.Hours .. "H"

        -- TODO: idk, this feels off
        --       create a public fn?
        local success, url = pcall(function()
            local id = p.Player.UserId
            return Players:GetUserThumbnailAsync(id,
                                                 Enum.ThumbnailType.HeadShot,
                                                 Enum.ThumbnailSize.Size420x420)
        end)

        GUI.Icon.Image.Image = url
        GUI.Parent = PlayerGui.ScreenGui.Action.Wrapper
    end
end)

Events.Match.Ended.OnClientEvent:Connect(function(winners)
    for _, c in ipairs(PlayerGui.ScreenGui.Action.Wrapper:GetChildren()) do
        if not c:IsA("Frame") then continue end
        c.Action.Text = ""
    end

    local draw = #winners > 1
    for _, w in ipairs(winners) do
        local GUI = PlayerGui.ScreenGui.Action.Wrapper[w.Player.UserId]
        GUI.Action.Text = draw and "DRAW" or "WINNER"
    end

    task.wait(7.6)
    for _, c in ipairs(PlayerGui.ScreenGui.Action.Wrapper:GetChildren()) do
        if not c:IsA("Frame") then continue end
        c:Destroy()
    end

    PlayerGui.ScreenGui.Action.Visible = false
end)

Events.Match.Turn.Started.OnClientEvent:Connect(function(_health)
    bet = 10
    hours = _health
    actions.Last = {
        Type = nil,
        Amount = nil,
    }
end)

Events.Match.Turn.Betting.Act.OnClientEvent:Connect(function(_health)
    enableButtons()
    bet = 10
    hours = _health
end)

Events.Match.Turn.Betting.Acted.OnClientEvent:Connect(function(action, _health, pot)
    disableButtons()
    bet = 10
    hours = _health

    PlayerGui.ScreenGui.Action.Pot.Label.Text = "POT: " .. pot .. "H"
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(Player.UserId).Hours.Text = _health .. "H"
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(Player.UserId).Timer.Bar.Transparency = 1

    local labelText = action.Type
    if action.Type ~= "ALL IN" then
        if action.Type == "BET" then
            labelText = action.Type .. " " .. action.Amount .. "H"
        end
        if action.Type == "RAISE" then
            labelText = action.Type .. " TO " .. action.Amount .. "H"
        end
    end
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(Player.UserId).Action.Text = labelText
end)

Events.Match.Turn.Betting.Action.OnClientEvent:Connect(function(player, action, _health, pot)
    if action.Type ~= "FOLD" then
        actions.Last = action
    end

    buttonLayouts[action.Type]()

    PlayerGui.ScreenGui.Action.Pot.Label.Text = "POT: " .. pot .. "H"
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(player.UserId).Hours.Text = _health .. "H"
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(player.UserId).Timer.Bar.Transparency = 1

    local labelText = action.Type
    if action.Type ~= "ALL IN" then
        if action.Type == "BET" then
            labelText = action.Type .. " " .. action.Amount .. "H"
        end
        if action.Type == "RAISE" then
            labelText = action.Type .. " TO " .. action.Amount .. "H"
        end
    end
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(player.UserId).Action.Text = labelText
end)

Events.Match.Turn.Betting.Timer.OnClientEvent:Connect(function(player, progression)
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(player.UserId).Timer.Bar.Transparency = 0
    PlayerGui.ScreenGui.Action.Wrapper:FindFirstChild(player.UserId).Timer.Bar.Size = UDim2.fromScale(progression, 1)
end)

Events.Match.Turn.Betting.Started.OnClientEvent:Connect(function()
    actions.Last = {
        Type = nil,
        Amount = nil,
    }

    buttonLayouts.DEFAULT()

    for _, c in ipairs(PlayerGui.ScreenGui.Action.Wrapper:GetChildren()) do
        if not c:IsA("Frame") then continue end
        c.Action.Text = ""
    end
end)
