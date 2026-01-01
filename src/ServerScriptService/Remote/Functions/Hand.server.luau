--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Objects = ReplicatedStorage:WaitForChild("Objects")
local Cards = Objects.Cards

local Functions = {
    Hand = {
        Equip = ReplicatedStorage.Functions.Hand.Equip,
        Unequip = ReplicatedStorage.Functions.Hand.Unequip,
    },
}

local Modules = ServerStorage:WaitForChild("Modules")
local Card = require(Modules.Poker.Card)

local Storages = {
    Memory = {
        Matches = require(ServerStorage.Storages.Memory.Matches),
        Players = require(ServerStorage.Storages.Memory.Players),
    },
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

        local card = Cards.Blank:Clone()
        card.Name = i
        card.Anchored = false
        card.CanCollide = false
        card.Massless = true
        card.Face.Texture = ""
        card.Face.Transparency = 0
        card.Decal.Transparency = 0
        card.Transparency = 0
        card.Parent = handle

        local offset = Vector3.new(
            math.sin(angleRad) * radius,
            0,
            math.cos(angleRad) * radius
        )

        local position = center - offset + Vector3.new(0, i * card.Size.Y, 0)
        card.Position = position
        card.CFrame = CFrame.lookAt(position, center)

        local weld = Instance.new("WeldConstraint")
        weld.Parent = card
        weld.Part0 = card
        weld.Part1 = handle
    end
end

Functions.Hand.Equip.OnServerInvoke = function(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rightArm = character:FindFirstChild("Right Arm")

    -- NOTE: quick fix for the race condition problem
    for _, child in ipairs(rightArm:GetChildren()) do
        if child.Name == "Handle" or child.Name == "Right Arm Motor6D" then
            child:Destroy()
        end
    end

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Parent = rightArm
    handle.Size = Vector3.new(0.5, 0.5, 0.5)
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    handle.Transparency = 1
    Instance.new("Highlight", handle)

    local house = Storages.Memory.Players.Get(player).House
    local suit = (house and house.Name) or "Club"

    local cards = {}
    table.insert(cards, Card.new("5", suit .. 's'))
    table.insert(cards, Card.new("A", suit .. 's'))

    local match = Storages.Memory.Matches.Find(player)
    if match then
        local _player = match.Table:Get(player)
        cards = _player.Hand.Cards
    end

    buildCards(handle, cards, 0.19)

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
    
    return cards
end

Functions.Hand.Unequip.OnServerInvoke = function(player: Player): nil
    local character = player.Character or player.CharacterAdded:Wait()
    local rightArm = character:FindFirstChild("Right Arm")

    for _, child in ipairs(rightArm:GetChildren()) do
        if child.Name == "Handle" or child.Name == "Right Arm Motor6D" then
            child:Destroy()
        end
    end
end
