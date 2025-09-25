--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _table = require(ReplicatedStorage.Modules.Extension.Table)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Dialog = require(Modules.Dialog)

local Match = require(Modules.Match)
local Table = require(Modules.Poker.Table)

local Storages = {
    Memory = {
        Matches = require(ServerStorage:WaitForChild("Storages").Memory.Matches),
        Players = require(ServerStorage:WaitForChild("Storages").Memory.Players),
    },
}

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        Storages.Memory.Players.Load(player, true)
    end)
end)

-- NOTE: COMMENT ON PROD
-- if true then return end

local tables: Folder = workspace.Development.Tables
for _, t in ipairs(tables:GetChildren()) do
    local board: Folder = t
    local seats: Folder = board.Seats
    local billboard: BillboardGui = t.Billboard

    local anims = {}
    local players = {}

    local match

    local function setModelTransparency(model, transparency)
        for _, part in ipairs(model:GetDescendants()) do
            if not (part:IsA("BasePart") or part:IsA("Decal")) then
                continue
            end

            part.Transparency = transparency
        end
    end

    local _board = workspace.Development.Tables.Board
    local _dealer = _board.Dealer
    local _head = _dealer.Head

    local _rings = {}
    local _bell = _board.Bell
    _bell.ClickDetector.MouseClick:Connect(function(player: Player)
        _rings[player] = true
        workspace.Invisible.SFX.Bell:Play()

        local count = 0
        for k, v in pairs(_rings) do
            count += 1
        end

        if count < 2 then return end
        if #players < 2 then return end

        if match then return end
        _rings = {}

        task.spawn(function()
            setModelTransparency(_dealer.Hands.Pointing, 1)
            setModelTransparency(_dealer.Hands.Resting, 0)

            for _, p in ipairs(players) do
                Storages.Memory.Players.Load(p)
            end

            match = Match.new(players)
            Storages.Memory.Matches.Add(match)

            match:Start()
            Storages.Memory.Matches.Remove(match)

            -- NOTE: players that is already in the match disconnected,
            --       and there is no more player on the table to start a new game.
            if #match.Table.Players == 0 then
                match.Table:Destroy()
                match = nil
                return
            end

            -- NOTE: there's still players on the table,
            --       starting the game again, soon.
            match.Table:Destroy()
            match = nil
        end)
    end)

    -- axis can be "X", "Y", or "Z"
    local function createHover(part, hoverHeight, hoverTime, axis)
        hoverHeight = hoverHeight or 0.145
        hoverTime = hoverTime or 2
        axis = axis or "Y"  -- default to vertical hover

        if part:IsA("BasePart") then
            local originalCFrame = part.CFrame

            -- Determine hover offset vector based on axis
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
                -1,  -- repeat infinitely
                true  -- reverse automatically
            )
            local goal = {CFrame = originalCFrame * CFrame.new(offset)}
            local tween = TweenService:Create(part, tweenInfo, goal)
            tween:Play()
            return tween
        end
    end

    for _, part in ipairs(_head:GetChildren()) do
        createHover(part, 0.145, 2, "Y")
    end

    for _, part in ipairs(_dealer.Hands.Pointing:GetChildren()) do
        createHover(part, 0.145, 2, "Z")
    end

    Players.PlayerRemoving:Connect(function(player: Player)
        table.remove(players, _table.index(players, function(p) return p == player end))
        local empty = #players == 0

        setModelTransparency(_dealer.Hands.Pointing, 1)
        setModelTransparency(_dealer.Hands.Resting, 0)
    end)

    for _, model in ipairs(seats:GetChildren()) do
        local seat = model.Seat

        seat.ChildAdded:Connect(function(child)
            if child.ClassName ~= "Weld" then return end
            
            local humanoid = child.Part1.Parent:FindFirstChild("Humanoid")
            if not humanoid then return end

            local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
            if not player then return end

            workspace.Invisible.SFX.Dash:Play()

            local empty = #players == 0
            table.insert(players, player)

            local full = #players == 2
            if full then
                _rings = {}
                setModelTransparency(_dealer.Hands.Pointing, 0)
                setModelTransparency(_dealer.Hands.Resting, 1)

                local _label = _head.Dialog.Frame.Label
                Dialog.Show(_label, "Ring the bell..")
            end

            local animator = humanoid:WaitForChild("Animator")
            anims[player.UserId] = animator:LoadAnimation(ReplicatedStorage.Animations.Sit:FindFirstChild("Lean"))
            anims[player.UserId]:Play()
        end)

        seat.ChildRemoved:Connect(function(child)
            if child.ClassName ~= "Weld" then return end

            local humanoid = child.Part1.Parent:FindFirstChild("Humanoid")
            if not humanoid then return end

            local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
            if not player then return end
            
            table.remove(players, _table.index(players, function(p) return p == player end))
            local empty = #players == 0

            setModelTransparency(_dealer.Hands.Pointing, 1)
            setModelTransparency(_dealer.Hands.Resting, 0)

            anims[player.UserId]:Stop()
            anims[player.UserId]:Remove()
            anims[player.UserId] = nil
        end)
    end
end
