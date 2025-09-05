--!strict
local Card = {}
Card.__index = Card

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Cards = Objects.Cards

local Suit = {
    Spades   = true,
    Hearts   = true,
    Diamonds = true,
    Clubs    = true
}

local Rank = {}
for i = 2, 10 do
	Rank[tostring(i)] = i
end

Rank["J"] = 11
Rank["Q"] = 12
Rank["K"] = 13
Rank["A"] = 14 -- NOTE: this can be either 14 or 1, the default value will be 14.

function Card.new(rank: Rank, suit: Suit, ace: number?)
    assert(Rank[rank])
    assert(Suit[suit])
    assert(not ace or ace == 1 or ace == 14)

    ace = ace or Rank["A"]

    -- TODO: CURRENTLY, HAND CAN COPY ITSELF, WHICH CLONES A NEW CARD PART.
    -- INSTEAD, IT SHOULDN'T CLONE A NEW CARD PART.
    local template: Part = workspace:WaitForChild("Board").CARDEXAMPLE
    local part: Part = Cards.Blank:Clone()

    part.Anchored = true
    part.CFrame = template.CFrame
    part.Parent = nil

    return setmetatable({
        Part = part,
        Rank = rank,
        Suit = suit,
        Ace = ace
    }, Card)
end

-- NOTE: without cloning a new card part
function Card:Copy(): Card
    return setmetatable({
        Part = self.Part,
        Rank = self.Rank,
        Suit = self.Suit,
        Ace = self.Ace
    }, Card)
end

function Card:RankAsNumeric(): number
    if self.Rank == "A" then
        return self.Ace
    end

    return Rank[self.Rank]
end

return Card
