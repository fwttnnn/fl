--!strict
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local Managers = ServerStorage:WaitForChild("Managers")

local Session = require(Modules.Session)
local SessionManager = require(Managers.Session)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipEvent = ReplicatedStorage.Events.Card:FindFirstChild("Equip")
local UnequipEvent = ReplicatedStorage.Events.Card:FindFirstChild("Unequip")

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
        card.Anchored = false
        card.CanCollide = false
        card.Massless = true
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

EquipEvent.OnServerEvent:Connect(function(player: Player)
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

    local session = SessionManager.FindPlayerSession(player)
    local _player = session:GetPlayer(player)
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
end)

UnequipEvent.OnServerEvent:Connect(function(player: Player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rightArm = character:FindFirstChild("Right Arm")

    rightArm:FindFirstChild("Handle"):Destroy()
    rightArm:FindFirstChild("Right Arm Motor6D"):Destroy()
end)

wait(1) 

local Players = game:GetService("Players")
local allPlayers = {}

for _, player in pairs(Players:GetPlayers()) do
    table.insert(allPlayers, player)
end

local me = allPlayers[1]

table.insert(SessionManager, Session.new({me, {UserId = 666}}))
local session = SessionManager.FindPlayerSession(me)

-- session:Deal(me)
-- session:Deal(me)
-- session:Deal(me)
-- session:Deal(me)
-- session:Deal(me)

local Card = require(Modules.Card)

local _player = session:GetPlayer(me)

-- _player.Hand:Push(Card.new("A", "Hearts"))
-- _player.Hand:Push(Card.new("6", "Hearts"))
-- _player.Hand:Push(Card.new("7", "Hearts"))
-- _player.Hand:Push(Card.new("6", "Clubs"))
-- _player.Hand:Push(Card.new("3", "Hearts"))

_player.Hand:Push(Card.new("A", "Hearts"))
_player.Hand:Push(Card.new("2", "Hearts"))
_player.Hand:Push(Card.new("3", "Hearts"))
_player.Hand:Push(Card.new("4", "Hearts"))
_player.Hand:Push(Card.new("5", "Hearts"))

_player.Hand:Sort()
print(_player.Hand:Rank())
