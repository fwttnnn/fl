--!strict
local Deck = {}
Deck.__index = Deck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Cards = Objects.Cards

function Deck.new(tbl: Folder)
    -- TODO(priority): this clones a card, we need the pos.
    local part: Part = tbl.Template.Deck:Clone()

    part.Name = "Deck"
    part.CanQuery = true
    part.Parent = tbl

    return setmetatable({
        Part = part,
        Cards = {},
    }, Deck)
end

function Deck:Destroy()
    self.Part:Destroy()
end

function Deck:IsEmpty(): boolean
    return #self.Cards <= 0
end

function Deck:Shuffle()
    local shuffles = {
        ["?"] = function()
            for i = #self.Cards, 2, -1 do
                local j = math.random(1, i)
                self.Cards[i], self.Cards[j] = self.Cards[j], self.Cards[i]
            end
        end,
    }

    for _ = 1, 5 do
        shuffles["?"]()
    end
end

function Deck:Push(card: Card)
    local n = #self.Cards

    local _blank: Part = Cards.Blank:Clone()
    _blank.Parent = self.Part

    _blank.Name = tostring(n + 1)
    _blank.CFrame = self.Part.CFrame + Vector3.new(0, n * _blank.Size.Y, 0)

    _blank.Decal.Transparency = 0
    _blank.Face.Transparency = 0
    _blank.Transparency = 0

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

    local _card = self.Part:FindFirstChild(tostring(#self.Cards))
    if _card then _card:Destroy() end

    return table.remove(self.Cards)
end

return Deck
