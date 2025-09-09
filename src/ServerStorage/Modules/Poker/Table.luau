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
        billboard.Size = UDim2.new(1.25, 0, 0.5, 0)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, .8, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = card.Part
        billboard.Parent = card.Part

        -- local billboard = Instance.new("Part", card.Part)
        -- billboard.Name = "Billboard"
        -- billboard.Size = Vector3.new(1, .5, 0.001)
        -- billboard.Anchored = true
        -- billboard.Massless = true
        -- billboard.CanCollide = false
        -- billboard.Transparency = 1
        -- billboard.CFrame = card.Part.CFrame + Vector3.new(0, .8, 0)
        -- billboard:SetAttribute("Billboard", true)

        -- local gui = Instance.new("SurfaceGui", billboard)
        -- gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        -- gui.PixelsPerStud = 100
        -- gui.Face = Enum.NormalId.Back

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal -- side by side
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = billboard

        local symbols = {
            Spades = "♠",
            Clubs = "♣",
            Diamonds = "♦",
            Hearts = "♥",
        }

        -- Container frame
        local container = Instance.new("Frame")
        container.Size = UDim2.fromScale(.5, 1)
        container.BackgroundTransparency = 1
        container.Parent = billboard

        -- Layout manager
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal -- side by side
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        -- Suit label
        local suitLabel = Instance.new("TextLabel")
        suitLabel.AutomaticSize = Enum.AutomaticSize.X
        suitLabel.Size = UDim2.fromScale(0, .9)
        suitLabel.AnchorPoint = Vector2.new(.5, .5)
        suitLabel.BackgroundTransparency = 1
        suitLabel.Text = symbols[card.Suit]
        suitLabel.TextScaled = true
        suitLabel.TextColor3 = (card.Suit == "Hearts" or card.Suit == "Diamonds")
            and Color3.fromRGB(255, 0, 0)
            or Color3.fromRGB(0, 0, 0)
        suitLabel.TextStrokeColor3 = (card.Suit == "Hearts" or card.Suit == "Diamonds")
            and Color3.fromRGB(0, 0, 0)
            or Color3.fromRGB(255, 255, 255)
        suitLabel.TextStrokeTransparency = 0.5
        suitLabel.LayoutOrder = 1
        suitLabel.Parent = container

        -- Rank label
        local rankLabel = Instance.new("TextLabel")
        rankLabel.AutomaticSize = Enum.AutomaticSize.X
        rankLabel.Size = UDim2.fromScale(0, .9)
        rankLabel.AnchorPoint = Vector2.new(.5, .5)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = card.Rank
        rankLabel.TextScaled = true
        rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        rankLabel.TextStrokeTransparency = 0.5
        rankLabel.LayoutOrder = 2
        rankLabel.Parent = container

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
