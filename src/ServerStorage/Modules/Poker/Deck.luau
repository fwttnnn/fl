--!strict
local Deck = {}
Deck.__index = Deck

function Deck.new()
    local template: Part = workspace:WaitForChild("Board").DECKEXAMPLE
    local part: Part = template:Clone()
    local clickDetector: ClickDetector = Instance.new("ClickDetector", part)

    -- Instance.new("Highlight", part)

    part.Name = "Deck"
    part.CanQuery = true
    part.Parent = workspace

    return setmetatable({
        Part = part,
        Cards = {},
    }, Deck)
end

function Deck:IsEmpty(): boolean
    return #self.Cards <= 0
end

function Deck:Resize()
    if self:IsEmpty() then
        self.Part.Size = Vector3.new(0, 0, 0)
        return
    end

    self.Part.Size = Vector3.new(self.Part.Size.X, (#self.Cards * self:Top().Part.Size.Y), self.Part.Size.Z)
    -- TODO: not actually on center, calculate the center from the top and bottom pos instead.
    self.Part.Position = self.Cards[math.floor(#self.Cards / 2 + 1)].Part.Position
end

function Deck:Shuffle()
    for i = #self.Cards, 2, -1 do
        local j = math.random(1, i)
        self.Cards[i], self.Cards[j] = self.Cards[j], self.Cards[i]
    end
end

function Deck:Push(card: Card)
    if not self:IsEmpty() then
        local topCard: Card = self:Top()
        card.Part.CFrame = topCard.Part.CFrame + Vector3.new(0, topCard.Part.Size.Y, 0)
    end

    card.Part.Parent = self.Part
    card.Part.Transparency = 0
    card.Part.Decal.Transparency = 0
    card.Part.Face.Transparency = 1

    table.insert(self.Cards, card)
end

function Deck:Top(): Card
    if self:IsEmpty() then
        error("Deck is empty.")
    end

    return self.Cards[#self.Cards]
end

function Deck:Bottom(): Card
    if self:IsEmpty() then
        error("Deck is empty.")
    end

    return self.Cards[1]
end

function Deck:Pop(): Card
    if self:IsEmpty() then
        error("Deck is empty.")
    end

    return table.remove(self.Cards)
end

function Deck:Deal(player: Player, cardInHandPosition: Vector3, __NPLAYERHAND: number)
    local _Board = workspace:WaitForChild("Board").Board
    local direction: Vector3 = (cardInHandPosition - _Board.Position).Unit
    direction = Vector3.new(direction.X, 0, direction.Z)
    -- direction = Vector3.new((direction.X >= 0 and 1 or -1), 0, (direction.Z >= 0 and 1 or -1))

    local card = self:Pop()
    -- card.Part.Face.Transparency = 0
    card.Part.Position = self:Bottom().Part.Position

    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        1, -- Time
        Enum.EasingStyle.Quad, -- EasingStyle
        Enum.EasingDirection.Out -- EasingDirection
    )

    local cardSpacing = card.Part.Size.X * 0.4
    local offset = direction * -(__NPLAYERHAND * cardSpacing)
    local targetPosition = cardInHandPosition + offset

    local tween = TweenService:Create(card.Part, tweenInfo, {
        Position = targetPosition,
        Orientation = card.Part.Orientation + Vector3.new(0, math.random(60, 120), 0)
        -- Orientation = Vector3.new(0, math.random(0, 120), 0)
    })
    tween:Play()

    workspace.Invisible.Sound:Play()
end

return Deck
