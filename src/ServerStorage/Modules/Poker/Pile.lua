--!strict
local Pile = {}
Pile.__index = Pile

function Pile.new(cards: Cards?)
    cards = cards or {}

    return setmetatable({
        Cards = cards
    }, Pile)
end

function Pile:Push(card: Card)
    table.insert(self.Cards, card)
end

function Pile:Pop(): Card
    return table.remove(self.Cards)
end

function Pile:ChangeAces(ace: number)
    assert(ace == 1 or ace == 14)

	for _, card in ipairs(self.Cards) do
        card.Ace = ace
	end
end

function Pile:Copy(): Pile
    local pile = Pile.new()

	for _, card in ipairs(self.Cards) do
        pile:Push(card:Copy())
	end

	return pile
end

function Pile:Sort()
    self:SortByRank()
end

function Pile:SortByRank()
    table.sort(self.Cards, function(a, b)
        -- NOTE: descending (high to low)
        return a:RankAsNumeric() > b:RankAsNumeric()
    end)
end

function Pile:SortBySuit()
    table.sort(self.Cards, function(a, b)
        if a.Suit == b.Suit then
            return a:RankAsNumeric() > b:RankAsNumeric()
        end

        return a.Suit < b.Suit
    end)
end

function Pile:__RankedNOfAKind(n: number): boolean
    local counts = {}
    for _, card in ipairs(self.Cards) do
        counts[card.Rank] = (counts[card.Rank] or 0) + 1
    end

    for _, count in pairs(counts) do
        if count == n then
            return true
        end
    end

    return false
end

function Pile:_RankedRoyalFlush(): boolean
    if self.Cards[1].Rank ~= "A" or self.Cards[2].Rank ~= "K" then
        return false
    end

    return self:_RankedStraight() and self:_RankedFlush()
end

function Pile:_RankedStraightFlush(): boolean
    return self:_RankedStraight() and self:_RankedFlush()
end

function Pile:_RankedFourOfAKind(): boolean
    return self:__RankedNOfAKind(4)
end

function Pile:_RankedFullHouse(): boolean
    local counts = {}
    for _, card in ipairs(self.Cards) do
        counts[card.Rank] = (counts[card.Rank] or 0) + 1
    end

    local hasThreeOfAKind = false
    local hasOnePair = false
    for _, count in pairs(counts) do
        if count == 3 then
            hasThreeOfAKind = true
        elseif count == 2 then
            hasOnePair = true
        end
    end

    return hasThreeOfAKind and hasOnePair
end

function Pile:_RankedFlush(): boolean
    local suit: string = self.Cards[1].Suit

    for _, card in ipairs(self.Cards) do
        if card.Suit ~= suit then
            return false
        end
    end

    return true
end

function Pile:_RankedStraight(): boolean
    -- Not enough cards to form a straight
    if #self.Cards < 2 then
        return false
    end

    local prevRank = self.Cards[1]:RankAsNumeric()

    for i = 2, #self.Cards do
        local card = self.Cards[i]
        local currentRank = card:RankAsNumeric()

        -- NOTE: this assumes the cards are sorted in descending order
        if currentRank ~= prevRank - 1 then
            return false
        end

        prevRank = currentRank
    end

    return true
end

function Pile:_RankedThreeOfAKind(): boolean
    return self:__RankedNOfAKind(3)
end

function Pile:_RankedTwoPair(): boolean
    local counts = {}
    for _, card in ipairs(self.Cards) do
        counts[card.Rank] = (counts[card.Rank] or 0) + 1
    end

    local pairCount = 0
    for _, count in pairs(counts) do
        if count == 2 then
            pairCount += 1
        end
    end

    return pairCount == 2
end

function Pile:_RankedOnePair(): boolean
    return self:__RankedNOfAKind(2)
end

function Pile:_RankedHighCard(): boolean
    -- WARNING: this function is not gonna be used.
    assert(false)
    return false
end

function _slice(tbl, start, stop)
    assert(start <= stop and stop <= #tbl)
    local sliced = {}

    for i = start, stop do
        table.insert(sliced, tbl[i])
    end

    return sliced
end

function _combinations(tbl, n)
    assert(n >= 0 and n <= #tbl)
    local combinations = {}

    for i = 1, #tbl do
        if (i - 1) + n > #tbl then
            break
        end

        table.insert(combinations, _slice(tbl, i, (i - 1) + n))
    end

    return combinations
end

function Pile:Score(): number
    local score = 0

    for _, card in ipairs(self.Cards) do
        score += card:RankAsNumeric()
    end

    return score
end

function Pile:Best(cards: {Card}): {Card}
    assert(#self.Cards + #cards >= 5, "need to have at least 5 cards to calculate the best pile")

    local pile = self:Copy()
    for _, card in ipairs(cards) do
        pile:Push(card)
    end

    local pileAces14SortedByRank = pile:Copy()
    local pileAces14SortedBySuit = pile:Copy()
    local pileAces1SortedByRank  = pile:Copy()
    local pileAces1SortedBySuit  = pile:Copy()

    pileAces14SortedByRank:ChangeAces(14)
    pileAces14SortedBySuit:ChangeAces(14)
    pileAces1SortedByRank:ChangeAces(1)
    pileAces1SortedBySuit:ChangeAces(1)

    pileAces14SortedByRank:SortByRank()
    pileAces14SortedBySuit:SortBySuit()
    pileAces1SortedByRank:SortByRank()
    pileAces1SortedBySuit:SortBySuit()

    local function bestPile(combinations)
        local best = { pile = nil, rank = 0 }

        for _, cards in ipairs(combinations) do
            -- TODO: THIS SUCKS, I ONLY NEED :RANK()
            -- BUT, I HAVE TO CREATE A WHOLE NEW OBJECT.
            local pile = Pile.new(cards)
            local rank = pile:Rank()

            if rank > best.rank then
                best.pile = pile
                best.rank = rank
            end
        end

        return best
    end

    local pileAces14SortedByRankBest = bestPile(_combinations(pileAces14SortedByRank.Cards, 5))
    local pileAces14SortedBySuitBest = bestPile(_combinations(pileAces14SortedBySuit.Cards, 5))
    local pileAces1SortedByRankBest  = bestPile(_combinations(pileAces1SortedByRank.Cards, 5))
    local pileAces1SortedBySuitBest  = bestPile(_combinations(pileAces1SortedBySuit.Cards, 5))

    local best = pileAces14SortedByRankBest

    for _, candidate in ipairs({
        pileAces14SortedByRankBest,
        pileAces14SortedBySuitBest,
        pileAces1SortedByRankBest,
        pileAces1SortedBySuitBest,
    }) do
        if candidate.rank > best.rank then
            best = candidate
        end
    end

    return best.pile.Cards
end

function Pile:Rank(): number
    -- TODO: RETURN THE VALUE OF RANKED HAND (FROM _RANKED* FN), IN CASE A PLAYER HAVE THE SAME RANK.
    -- NOTE: must be sorted, and pile size must be 5.
    assert(#self.Cards == 5, "Pile must have exactly 5 cards")

    if self:_RankedRoyalFlush()    then return 10 end
    if self:_RankedStraightFlush() then return 9 end
    if self:_RankedFourOfAKind()   then return 8 end
    if self:_RankedFullHouse()     then return 7 end
    if self:_RankedFlush()         then return 6 end
    if self:_RankedStraight()      then return 5 end
    if self:_RankedThreeOfAKind()  then return 4 end
    if self:_RankedTwoPair()       then return 3 end
    if self:_RankedOnePair()       then return 2 end
    return 1 -- NOTE: ranked high card
end

return Pile
