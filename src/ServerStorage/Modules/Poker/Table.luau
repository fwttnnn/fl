--!strict
local Table = {}
Table.__index = Table

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Cards = Objects.Cards

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Deck = require(Modules.Poker.Deck)
local Card = require(Modules.Poker.Card)
local Pile = require(Modules.Poker.Pile)

function Table.new(players: {[number]: {Player: Player, Chips: {Remaining: number, Stake: number}}})
    local _players = {}
    for _, player in ipairs(players) do
        local p = player.Player

        table.insert(_players, {
            Id = p.UserId,
            Player = p,
            Active = true,
            Chips = {
                Remaining = player.Chips.Remaining,
                Stake = player.Chips.Stake,
            },
            Hand = Pile.new(), 
        })
    end

    local deck = Deck.new()
    for _, suit: Folder in ipairs(Cards.Poker:GetChildren()) do
        for _, rank: Part in ipairs(suit:GetChildren()) do
            deck:Push(Card.new(rank.Name, suit.Name))
        end
    end
    deck:Shuffle()

    local _board = workspace.Development.Board
    local communityCardsLine = Instance.new("Part")
    communityCardsLine.Name = "Gugugaga"
    communityCardsLine.Color = Color3.fromRGB(200, 0, 100)
    communityCardsLine.Transparency = 1
    communityCardsLine.Anchored = true
    communityCardsLine.Parent = _board
    communityCardsLine.Position = _board.CommunityCardsLine.Position
    communityCardsLine.Rotation = Vector3.new(0, -180, 0)
    communityCardsLine.Size = Vector3.new((Cards.Blank.Size.X + 0.03) * 5, 0, Cards.Blank.Size.Z)

    return setmetatable({
        Players = _players,
        Deck = deck,
        Pot = 0,
        Cards = {
            Community = Pile.new(),
            Burned = Pile.new()
        }
    }, Table)
end

function Table:PlayerIndex(player: Player): number
    for index, _player in ipairs(self.Players) do
        if _player.Id == player.UserId then
            return index
        end
    end

    return nil
end

-- NOTE: was O(1), but order matters, so it's ok for an O(n).
-- n will always be a low value anyway.
function Table:GetPlayer(player: Player)
    for _, _player in ipairs(self.Players) do
        if _player.Id == player.UserId then
            return _player
        end
    end

    return nil
end

function Table:DealToCommunity()
    local card: Card = self.Deck:Pop()
    self.Cards.Community:Push(card)

    local _board = workspace.Development.Board

    local communityCardsLine = _board.Gugugaga
    local nCards = #self.Cards.Community.Cards
    local slotWidth = card.Part.Size.X + 0.03

    card.Part.Face.Texture = Cards.Poker[card.Suit][card.Rank].Face.Texture
    card.Part.Face.Transparency = 0

    card.Part.Anchored = true
    card.Part.Parent = communityCardsLine
    card.Part.Rotation = Vector3.new(0, -180, 0)

    local leftEdge = communityCardsLine.Position + Vector3.new(communityCardsLine.Size.X / 2, 0, 0)
    local targetPos = leftEdge - Vector3.new(slotWidth * (nCards - 1) + (slotWidth / 2), 0, 0)

    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local tween = TweenService:Create(card.Part, tweenInfo, { Position = targetPos, Rotation = Vector3.new(0, 0, 0) })

    tween:Play()
    workspace.Invisible.Sound:Play()

    tween.Completed:Once(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0.5, 0, 0.5, 0)
        -- billboard.StudsOffsetWorldSpace = Vector3.new(0, .8 + (.17 * nCards), 0)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, .8, 0)
        billboard.AlwaysOnTop = false
        billboard.Adornee = card.Part
        billboard.Parent = card.Part

        -- TODO: move this somewhere, or use house 
        local symbols = {
            Spades = "♠",
            Clubs = "♣",
            Diamonds = "♦",
            Hearts = "♥",
        }

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = symbols[card.Suit] .. " " .. card.Rank
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.5
        -- label.Font = Enum.Font.GothamBold
        -- label.TextSize = 16
        label.TextScaled = true
        label.Parent = billboard

        print(billboard)
    end)
end

function Table:DealToPlayer(player: Player)
    local _player = self:GetPlayer(player)
    _player.Hand:Push(self.Deck:Pop())
end

function Table:Deal(player: Player?)
    if not player then return self:DealToCommunity() end
    return self:DealToPlayer(player)
end

return Table
