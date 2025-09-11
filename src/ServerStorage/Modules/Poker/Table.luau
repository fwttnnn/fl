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

local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
    },
}

function Table.new(players: {[number]: Player})
    local _players = {}
    for _, player in ipairs(players) do
        local p = player.Player

        table.insert(_players, {
            Id = p.UserId,
            Player = p,
            Active = true,
            Health = 100,
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
    local inner = Instance.new("Part")
    inner.Name = "Gugugaga"
    inner.Color = Color3.fromRGB(200, 0, 100)
    inner.Transparency = 1
    inner.Anchored = true
    inner.Position = _board.CommunityCardsLine.Position
    inner.Rotation = Vector3.new(0, -180, 0)
    inner.Size = Vector3.new((Cards.Blank.Size.X + 0.03) * 5, 0, Cards.Blank.Size.Z + 0.05)

    local outer = Instance.new("Part")
    outer.Name = "outer"
    outer.Anchored = true
    outer.Size = inner.Size + Vector3.new(0.05, 0, 0.05)
    outer.Position = inner.Position
    outer.Parent = _board

    outer.Color = Color3.fromRGB(202, 191, 163) -- beige
    outer.Material = Enum.Material.Concrete

    local union = outer:SubtractAsync({inner})
    union.Name = "CommunityCardsUnion"
    union.Position -= Vector3.new(0, 0.0007, 0) -- NOTE: so the lines goes inside the board a little
    union.Parent = _board

    inner.Parent = union
    outer:Destroy()
    print(union)

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
    local inner = _board.CommunityCardsUnion.Gugugaga
    
    local nCards = #self.Cards.Community.Cards
    local slotWidth = card.Part.Size.X + 0.03

    card.Part.Face.Texture = Cards.Poker[card.Suit][card.Rank].Face.Texture
    card.Part.Face.Transparency = 0

    card.Part.Anchored = true
    card.Part.Parent = inner
    card.Part.Rotation = Vector3.new(0, -180, 0)

    local leftEdge = inner.Position + Vector3.new(inner.Size.X / 2, 0, 0)
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
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = billboard

        local container = Instance.new("Frame")
        container.Size = UDim2.fromScale(.5, 1)
        container.BackgroundTransparency = 1
        container.Parent = billboard

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        local house = Storages.Global.House.Suits[string.sub(card.Suit, 1, -2)]

        local suitLabel = Instance.new("TextLabel")
        suitLabel.AutomaticSize = Enum.AutomaticSize.X
        suitLabel.Size = UDim2.fromScale(0, .9)
        suitLabel.AnchorPoint = Vector2.new(.5, .5)
        suitLabel.BackgroundTransparency = 1
        suitLabel.Text = house.Symbol
        suitLabel.TextScaled = true
        suitLabel.TextColor3 = house.Color.Primary
        suitLabel.TextStrokeColor3 = house.Color.Secondary
        suitLabel.TextStrokeTransparency = 0.5
        suitLabel.LayoutOrder = 1
        suitLabel.Parent = container

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
