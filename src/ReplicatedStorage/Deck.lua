local Deck = {}
Deck.__index = Deck

function Deck.new()
    local template: Part = workspace:WaitForChild("DECKEXAMPLE")
    local part: Part = template:Clone()
    local clickDetector: ClickDetector = Instance.new("ClickDetector", part)

    Instance.new("Highlight", part)

    part.Name = "Deck"
    part.CanQuery = true
    part.Parent = workspace

    local deck = setmetatable({
        Part = part,
        Cards = {},
        MAXSIZE = 40
    }, Deck)

    clickDetector.MouseClick:Connect(function()
        local card = deck:pop()
        card.Part:Destroy()

        workspace.Invisible.Sound:Play()

        deck:Resize()
    end)

    return deck
end

function Deck:setTransparency(transparency: number)
    self.Part.Transparency = transparency
end

function Deck:isFull(): boolean
    return #self.Cards >= self.MAXSIZE
end

function Deck:isEmpty(): boolean
    return #self.Cards <= 0
end

function Deck:Resize()
    if self:isEmpty() then
        self.Part.Size = Vector3.new(0, 0, 0)
        return
    end

    self.Part.Size = Vector3.new(self.Part.Size.X, (#self.Cards * self:top().Part.Size.Y), self.Part.Size.Z)
    -- TODO: not actually on center, calculate the center from the top and bottom pos instead.
    self.Part.Position = self.Cards[math.floor(#self.Cards / 2 + 1)].Part.Position
end

function Deck:push(card: Card)
    if self:isFull() then
        error("Deck is full.")
    end

    if not self:isEmpty() then
        local topCard: Card = self:top()
        card.Part.CFrame = topCard.Part.CFrame + Vector3.new(0, topCard.Part.Size.Y, 0)
    end

    card.Part.Parent = self.Part
    card:setTransparency(0)
    card.Part.face.Transparency = 1

    table.insert(self.Cards, card)

    self:Resize()
end

function Deck:top(): Card
    if self:isEmpty() then
        error("Deck is empty.")
    end

    return self.Cards[#self.Cards]
end

function Deck:pop(): Card
    if self:isEmpty() then
        error("Deck is empty.")
    end

    return table.remove(self.Cards)
end

return Deck
