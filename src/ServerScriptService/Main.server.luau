--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _table = require(ReplicatedStorage.Modules.Extension.Table)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Match = require(Modules.Match)
local Table = require(Modules.Poker.Table)

local Storages = {
    Memory = {
        Matches = require(ServerStorage:WaitForChild("Storages").Memory.Matches),
        Players = require(ServerStorage:WaitForChild("Storages").Memory.Players),
    },
}

Players.PlayerAdded:Connect(function(player)
    Storages.Memory.Players.Load(player, true)

    -- player.CharacterAdded:Connect(function(character)
    -- end)
end)

for _, t in ipairs(workspace.Tenants.Tables:GetChildren()) do
    local function setModelTransparency(model, transparency)
        for _, part in ipairs(model:GetDescendants()) do
            if not (part:IsA("BasePart") or part:IsA("Decal")) then
                continue
            end

            part.Transparency = transparency
        end
    end

    local function isTableFull(): boolean
        local seats = t.Seats:GetChildren()

        for _, model in ipairs(seats) do
            if not model.Seat:FindFirstChild("SeatWeld") then
                return false
            end
        end

        return true
    end

    local players  = {}
    local metadata = {}

    local rings = {}
    local match = nil

    for _, model in ipairs(t.Seats:GetChildren()) do
        local anim = nil
        local seat = model.Seat

        seat.ChildAdded:Connect(function(child)
            if child.ClassName ~= "Weld" then return end
            
            local humanoid = child.Part1.Parent:FindFirstChild("Humanoid")
            if not humanoid then return end

            local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
            if not player then return end

            workspace.Invisible.SFX.Dash:Play()
            table.insert(players, player)

            local animator = humanoid:WaitForChild("Animator")
            anim = animator:LoadAnimation(ReplicatedStorage.Animations.Sit:FindFirstChild("Lean"))
            anim:Play()

            if match then return end
            if isTableFull() then
                rings = {}
                setModelTransparency(t.Dealer.Hands.Pointing, 0)
                setModelTransparency(t.Dealer.Hands.Resting, 1)
                t.Dealer.Head.Dialog.Frame.Label.Text = "Ring the bell.."
            end
        end)

        seat.ChildRemoved:Connect(function(child)
            if child.ClassName ~= "Weld" then return end

            local humanoid = child.Part1.Parent:FindFirstChild("Humanoid")
            if not humanoid then return end

            local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
            if not player then return end
            
            table.remove(players, _table.index(players, function(p) return p == player end))
            local empty = #players == 0

            rings[player] = nil
            setModelTransparency(t.Dealer.Hands.Pointing, 1)
            setModelTransparency(t.Dealer.Hands.Resting, 0)
            t.Dealer.Head.Dialog.Frame.Label.Text = ""

            anim:Stop()
            anim:Remove()
        end)
    end

    Players.PlayerRemoving:Connect(function(player: Player)
        local index = _table.index(players, function(p) return p == player end)
        if not index then return end -- NOTE: prob from another table

        table.remove(players, index)
    end)

    t.Bell.ClickDetector.MouseClick:Connect(function(player: Player)
        rings[player] = true
        workspace.Invisible.SFX.Bell:Play()

        for _, p in ipairs(players) do
            if not rings[p] then return end
        end

        if #players < 2 then return end
        if match then return end

        rings = {}
        setModelTransparency(t.Dealer.Hands.Pointing, 1)
        setModelTransparency(t.Dealer.Hands.Resting, 0)
        t.Dealer.Head.Dialog.Frame.Label.Text = ""

        for _, p in ipairs(players) do
            local humanoid = p.Character:FindFirstChild("Humanoid")

            metadata[p] = {
                ["WalkSpeed"] = humanoid.WalkSpeed,
                ["JumpPower"] = humanoid.JumpPower,
                ["UseJumpPower"] = humanoid.UseJumpPower,
            }

            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.UseJumpPower = true
        end

        for _, p in ipairs(players) do
            Storages.Memory.Players.Load(p)
        end

        -- NOTE: we start a new match from here
        --       branch off thread so the main thread won't be blocked by `match:Start()`
        task.spawn(function()
            match = Match.new(players, t)
            Storages.Memory.Matches.Add(match)

            match:Start()
            task.wait(7.6) -- don't ask why it's 7.6 (reverse)
            Storages.Memory.Matches.Remove(match)

            for _, _p in ipairs(match.Table.Players) do
                local p = _p.Player
                local humanoid = p.Character:FindFirstChild("Humanoid")

                humanoid.WalkSpeed = metadata[p]["WalkSpeed"]
                humanoid.JumpPower = metadata[p]["JumpPower"]
                humanoid.UseJumpPower = metadata[p]["UseJumpPower"]
            end

            match:Destroy()
            match = nil
            rings = {}

            if isTableFull() then
                setModelTransparency(t.Dealer.Hands.Pointing, 0)
                setModelTransparency(t.Dealer.Hands.Resting, 1)
                t.Dealer.Head.Dialog.Frame.Label.Text = "Ring the bell.."
            end
        end)
    end)

    -- NOTE: AI generated code
    --       axis can be "X", "Y", or "Z"
    --
    --       -> to animate hovering dealer's hand/head
    local function createHover(part, hoverHeight, hoverTime, axis)
        hoverHeight = hoverHeight or 0.145
        hoverTime = hoverTime or 2
        axis = axis or "Y"

        if part:IsA("BasePart") then
            local originalCFrame = part.CFrame
            local offset = Vector3.new(0, 0, 0)

            if axis == "X" then
                offset = Vector3.new(hoverHeight, 0, 0)
            elseif axis == "Y" then
                offset = Vector3.new(0, hoverHeight, 0)
            elseif axis == "Z" then
                offset = Vector3.new(0, 0, hoverHeight)
            else
                warn("Invalid axis! Use 'X', 'Y', or 'Z'. Defaulting to Y.")
                offset = Vector3.new(0, hoverHeight, 0)
            end

            local tweenInfo = TweenInfo.new(
                hoverTime,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut,
                -1,   -- repeat infinitely
                true  -- reverse automatically
            )
            local goal = {CFrame = originalCFrame * CFrame.new(offset)}
            local tween = TweenService:Create(part, tweenInfo, goal)

            tween:Play()
            return tween
        end
    end

    for _, part in ipairs(t.Dealer.Head:GetChildren()) do           createHover(part, 0.145, 2, "Y") end
    for _, part in ipairs(t.Dealer.Hands.Pointing:GetChildren()) do createHover(part, 0.145, 2, "Z") end
end
