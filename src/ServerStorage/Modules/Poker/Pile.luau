--!strict
local Pile = {}
Pile.__index = Pile

function Pile.new(cards: Cards?)
    cards = cards or {}

    return setmetatable({
        Cards = cards
    }, Pile)
end

function Pile:__tostring()
    local str = ""

    str = str .. "("
    for i = 1, #self.Cards do
        local card = self.Cards[i]
        str = str .. card.Rank .. " " .. card.Suit

        if i ~= #self.Cards then
            str = str .. ", "
        end
    end
    str = str .. ")"

    return str
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

function Pile:__RankedNOfAKind(n: number): {[number]: Card}?
    local kinds = {}

    for _, card in ipairs(self.Cards) do
        kinds[card.Rank] = kinds[card.Rank] or {}
        table.insert(kinds[card.Rank], card)
    end

    for _, cards in pairs(kinds) do
        if #cards == n then
            return cards
        end
    end

    return nil
end

function Pile:_RankedHighCard(): {[number]: Card}?
    local highest = self.Cards[1]

    for i = 2, #self.Cards do
        local card = self.Cards[i]

        if card:RankAsNumeric() > highest:RankAsNumeric() then
            highest = card
        end
    end

    return {highest}
end

function Pile:_RankedOnePair(): {[number]: Card}?
    return self:__RankedNOfAKind(2)
end

function Pile:_RankedTwoPair(): {[number]: Card}?
    local kinds = {}
    for _, card in ipairs(self.Cards) do
        kinds[card.Rank] = kinds[card.Rank] or {}
        table.insert(kinds[card.Rank], card)
    end

    local _pairs = {}
    for _, cards in pairs(kinds) do
        if #cards == 2 then
            table.insert(_pairs, cards)
        end
    end

    if #_pairs == 2 then
        local _cards = {}

        for _, cards in ipairs(_pairs) do
            -- I HATE THIS, FFS MAKE A LUA STANDARD LIBRARY.
            for _, card in ipairs(cards) do
                table.insert(_cards, card)
            end
        end

        return _cards
    end

    return nil
end

function Pile:_RankedThreeOfAKind(): {[number]: Card}?
    return self:__RankedNOfAKind(3)
end

function Pile:_RankedStraight(): {[number]: Card}?
    local prevRank = self.Cards[1]:RankAsNumeric()
    local cards = {self.Cards[1]} -- NOTE: redundant `cards` var, but.. that's what it is.

    for i = 2, #self.Cards do
        local card = self.Cards[i]
        local currentRank = card:RankAsNumeric()

        -- NOTE: this assumes the cards are sorted in descending order
        if currentRank ~= prevRank - 1 then
            return nil
        end

        prevRank = currentRank
        table.insert(cards, card)
    end

    return cards
end

function Pile:_RankedFlush(): {[number]: Card}?
    local suit: string = self.Cards[1].Suit
    local cards = {self.Cards[1]} -- NOTE: redundant, but we need a shallow copy

    for _, card in ipairs(self.Cards) do
        if card.Suit ~= suit then
            return nil
        end

        table.insert(cards, card)
    end

    return cards
end

function Pile:_RankedFullHouse(): {[number]: Card}?
    local kinds = {}
    for _, card in ipairs(self.Cards) do
        if not kinds[card.Rank] then
            kinds[card.Rank] = {}
        end
        table.insert(kinds[card.Rank], card)
    end

    local threeOfAKind = nil
    local pair = nil

    for _, cards in pairs(kinds) do
        if #cards == 3 and not threeOfAKind then
            threeOfAKind = cards
        elseif #cards == 2 and not pair then
            pair = cards
        end
    end

    if threeOfAKind and pair then
        local cards = {}

        for _, card in ipairs(threeOfAKind) do
            table.insert(cards, card)
        end

        for _, card in ipairs(pair) do
            table.insert(cards, card)
        end

        return cards
    end

    return nil
end

function Pile:_RankedFourOfAKind(): {[number]: Card}?
    return self:__RankedNOfAKind(4)
end

function Pile:_RankedStraightFlush(): {[number]: Card}?
    local straight = self:_RankedStraight()
    if not straight then return nil end

    local flush = self:_RankedFlush()
    if not flush then return nil end

    -- NOTE: either returning flush or straight works (assuming #self.Cards is always 5).
    --       although, if #self.Cards > 5 then we need to re-check by creating a new pile from straight.
    return flush
end

function Pile:_RankedRoyalFlush(): {[number]: Card}?
    if self.Cards[1].Rank ~= "A" or self.Cards[2].Rank ~= "K" then
        return nil
    end

    return self:_RankedStraightFlush()
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

    local function isHandBetter(handA, handB): boolean
        local rankA, rankB = handA.Rank, handB.Rank

        if rankA.Tier ~= rankB.Tier then
            return rankA.Tier > rankB.Tier
        end

        assert(#rankA.Cards == #rankB.Cards)
        local n = #rankA.Cards

        for i = 1, n do
            local a = rankA.Cards[i]:RankAsNumeric()
            local b = rankB.Cards[i]:RankAsNumeric()

            if a ~= b then
                return a > b
            end
        end

        -- NOTE: get cards that's unused for rankings
        local function kickers(pile, used)
            local _used = {}
            for _, c in ipairs(used) do
                _used[c] = true
            end

            local _kickers = {}
            for _, c in ipairs(pile.Cards) do
                if not _used[c] then
                    table.insert(_kickers, c)
                end
            end

            -- NOTE: sadly, we need to sort it.
            table.sort(_kickers, function(a, b)
                return a:RankAsNumeric() > b:RankAsNumeric()
            end)

            return _kickers
        end

        local kickersA = kickers(handA.Pile, rankA.Cards)
        local kickersB = kickers(handB.Pile, rankB.Cards)

        assert(#kickersA == #kickersB)
        local n = #kickersA

        for i = 1, n do
            local a = kickersA[i]:RankAsNumeric()
            local b = kickersB[i]:RankAsNumeric()

            if a ~= b then
                return a > b
            end
        end

        return false -- NOTE: ties
    end

    local function bestPile(combinations)
        local best = {Pile = nil, Rank = {Tier = 0, Cards = {}}}

        for _, cards in ipairs(combinations) do
            -- NOTE: function :Rank() requires the cards to be sorted,
            --       function isHandBetter() requires pile to be sorted too anyway.
            --       although, this is not too concerning.
            table.sort(cards, function(a, b) return a:RankAsNumeric() > b:RankAsNumeric() end)

            local hand = Pile.new(cards)
            local candidate = {Pile = hand,
                               Rank = hand:Rank()}

            if isHandBetter(candidate, best) then
                best = candidate
            end
        end

        return best
    end

    local function _combinations(tbl, n)
        assert(n >= 0 and n <= #tbl)
        local results = {}

        local function backtrack(start, combo)
            if #combo == n then
                table.insert(results, {table.unpack(combo)})
                return
            end

            for i = start, #tbl do
                table.insert(combo, tbl[i])
                backtrack(i + 1, combo)
                table.remove(combo)
            end
        end

        backtrack(1, {})
        return results
    end

    local pileAces14SortedByRankBest = bestPile(_combinations(pileAces14SortedByRank.Cards, 5))
    local pileAces14SortedBySuitBest = bestPile(_combinations(pileAces14SortedBySuit.Cards, 5))
    local pileAces1SortedByRankBest  = bestPile(_combinations(pileAces1SortedByRank.Cards, 5))
    local pileAces1SortedBySuitBest  = bestPile(_combinations(pileAces1SortedBySuit.Cards, 5))

    local best = {Pile = nil, Rank = {Tier = 0, Cards = {}}}
    for _, candidate in ipairs({
        pileAces14SortedByRankBest,
        pileAces14SortedBySuitBest,
        pileAces1SortedByRankBest,
        pileAces1SortedBySuitBest,
    }) do
        local _ = isHandBetter(candidate, best)
        if _ then
            best = candidate
        end
    end

    return best.Pile.Cards
end

function Pile:Rank(): {Tier: number, Cards: {Card}}
    -- NOTE: must be sorted, and pile size must be 5.
    assert(#self.Cards == 5, "Pile must have exactly 5 cards")

    -- NOTE: rank order should be sorted by index (lowest to highest)
    local ranks = {
        self._RankedHighCard,      -- 1:  High Card
        self._RankedOnePair,       -- 2:  One Pair
        self._RankedTwoPair,       -- 3:  Two Pair
        self._RankedThreeOfAKind,  -- 4:  Three of a Kind
        self._RankedStraight,      -- 5:  Straight
        self._RankedFlush,         -- 6:  Flush
        self._RankedFullHouse,     -- 7:  Full House
        self._RankedFourOfAKind,   -- 8:  Four of a Kind
        self._RankedStraightFlush, -- 9:  Straight Flush
        self._RankedRoyalFlush,    -- 10: Royal Flush
    }

    for i = #ranks, 1, -1 do
        local cards = ranks[i](self)
        if not cards then continue end

        return {Tier = i,
                Cards = cards}
    end

    assert(false, "this should not trigger.")
    return nil
end

return Pile
