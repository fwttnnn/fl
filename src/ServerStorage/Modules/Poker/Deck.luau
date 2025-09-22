--!strict
local Deck = {}
Deck.__index = Deck

function Deck.new()
    -- TODO(priority): this clones a card, we need the pos.
    local template: Part = workspace.Development.Board.DECKEXAMPLE
    local part: Part = template:Clone()

    part.Name = "Deck"
    part.CanQuery = true
    part.Parent = workspace.Development.Board

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

return Deck
