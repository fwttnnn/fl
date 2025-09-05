--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Functions = {
    Equip = ReplicatedStorage.Functions.Hand.Equip,
    Unequip = ReplicatedStorage.Functions.Hand.Unequip,
}

local Managers = {
    Match = require(ServerStorage:WaitForChild("Managers").Match),
}

function buildCards(handle: Part, cards: {[number]: Card}, cardSpacing: number)
    local center = handle.Position

    local radius = 1
    local arcLength = cardSpacing * (#cards - 1)
    local arcRadians = arcLength / radius
    local arcDegrees = math.deg(arcRadians)

    for i, _card in ipairs(cards) do
        local angleDeg = arcDegrees / 2 - (i - 1) * (arcDegrees / math.max(#cards - 1, 1))
        local angleRad = math.rad(angleDeg)

        local card = _card.Part:Clone()
        card.Name = i
        card.Anchored = false
        card.CanCollide = false
        card.Massless = true
        card.Face.Texture = ""
        card.Face.Transparency = 0
        card.Parent = handle

        local offset = Vector3.new(
            math.sin(angleRad) * radius,
            0,
            math.cos(angleRad) * radius
        )

        local position = center - offset + Vector3.new(0, i * card.Size.Y, 0)
        card.Position = position
        card.CFrame = CFrame.lookAt(position, center) * CFrame.Angles(0, math.rad(180), 0)

        local weld = Instance.new("WeldConstraint")
        weld.Parent = card
        weld.Part0 = card
        weld.Part1 = handle
    end
end

Functions.Equip.OnServerInvoke = function(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rightArm = character:FindFirstChild("Right Arm")

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Parent = rightArm
    handle.Size = Vector3.new(0.5, 0.5, 0.5)
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    handle.Transparency = 1
    Instance.new("Highlight", handle)

    local match = Managers.Match.FindPlayerMatch(player)
    if not match then return {} end
    local _player = match.Table:GetPlayer(player)
    buildCards(handle, _player.Hand.Cards, 0.19)

    local rightArmMotor6D = Instance.new("Motor6D")
    rightArmMotor6D.Name = "Right Arm Motor6D"
    rightArmMotor6D.Parent = rightArm
    rightArmMotor6D.Part0 = rightArm
    rightArmMotor6D.Part1 = handle

    -- NOTE: magic number
    rightArmMotor6D.C0 = 
        CFrame.new(-0.5, -0.6, 0.01) *
        CFrame.fromOrientation(
            math.rad(-30),
            math.rad(-60),
            math.rad(65)
        )
    
    return _player.Hand.Cards
end

Functions.Unequip.OnServerInvoke = function(player: Player): nil
    local character = player.Character or player.CharacterAdded:Wait()
    local rightArm = character:FindFirstChild("Right Arm")

    rightArm:FindFirstChild("Handle"):Destroy()
    rightArm:FindFirstChild("Right Arm Motor6D"):Destroy()
end
