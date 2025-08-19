local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local equipAnimation = animator:LoadAnimation(ReplicatedStorage.Animations.Hand:FindFirstChild("Equip"))

local player = game.Players.LocalPlayer
local cardGUI = player.PlayerGui.ScreenGui.ViewportFrame
cardGUI.Visible = false

local Functions = {
    Equip = ReplicatedStorage.Functions.Hand.Equip,
    Unequip = ReplicatedStorage.Functions.Hand.Unequip,
}

local Objects = ReplicatedStorage:WaitForChild("Objects")
local Cards = Objects.Cards.Poker

character.ChildAdded:Connect(function(child)
    if not child:IsA("Tool") then return end

    equipAnimation:Play()
    local cards = Functions.Equip:InvokeServer()
    local rightArm = character:FindFirstChild("Right Arm")

    local cardSpacing = 0.8
    local totalCards = #cards
    local middleOffset = (totalCards - 1) * cardSpacing / 2

    for i, card in ipairs(cards) do
        rightArm.Handle[i].Face.Texture = Cards[card.Suit][card.Rank].Face.Texture

        local xOffset = (i - 1) * cardSpacing - middleOffset
        local part = Cards[card.Suit][card.Rank]:Clone()

        part.Name = "Card"
        part.Parent = cardGUI
        part.Position = Vector3.new(xOffset, 0, 0)
        part.Orientation = Vector3.new(-90, 180, 0)

        local TweenService = game:GetService("TweenService")

        -- TODO: how do i stop this task when i delete the cards?
        task.spawn(function()
            local originalPosition = part.Position

            while true do
                local upTween = TweenService:Create(part, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, (i - 1) * 0.05), {
                    Position = originalPosition  + Vector3.new(0, 0.15, 0)
                })

                local downTween = TweenService:Create(part, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, (i - 1) * 0.05), {
                    Position = originalPosition
                })

                upTween:Play()
                upTween.Completed:Wait()
                
                downTween:Play()
                downTween.Completed:Wait()
            end
        end)

        -- print(part)
    end

    cardGUI.Visible = true
end)

character.ChildRemoved:Connect(function(child)
    if not child:IsA("Tool") then return end

    equipAnimation:Stop()
    Functions.Unequip:InvokeServer()

    cardGUI.Visible = false
    for _, part: Part in ipairs(cardGUI:GetChildren()) do
        if part.Name ~= "Card" then continue end
        part:Destroy()
    end
end)
