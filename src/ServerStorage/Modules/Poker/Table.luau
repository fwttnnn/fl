--!strict
local Table = {}
Table.__index = Table

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _table = require(ReplicatedStorage.Modules.Extension.Table)

local Objects = ReplicatedStorage:WaitForChild("Objects")
local Cards = Objects.Cards

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local Deck = require(Modules.Poker.Deck)
local Card = require(Modules.Poker.Card)
local Hand = require(Modules.Poker.Hand)

local Storages = {
    Global = {
        House = require(ServerStorage:WaitForChild("Storages").Global.House),
    },
}

function Table.new(players: {[number]: Player})
    assert(#players >= 2, "are you 5?")

    local _players = {}
    for _, player in ipairs(players) do
        table.insert(_players, {
            Id = player.UserId,
            Player = player,
            -- TODO: make this an enum
            Status = "Alive",
            Health = 100,
            Hand = Hand.new(), 
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

    return setmetatable({
        Players = _players,
        Deck = deck,
        Pot = 0,
        Cards = {
            Community = Hand.new(),
            Burned = Hand.new(),
        }
    }, Table)
end

-- TODO: this *should* destroy the whole board, currently, it doesn't.
function Table:Destroy()
    local _board = workspace.Development.Board

    _board.Deck:Destroy()
    _board.CommunityCardsUnion.Gugugaga:Destroy()
    _board.CommunityCardsUnion:Destroy()
end

function Table:Get(player: Player)
    return _table.find(self.Players, function(p)
        return p.Id == player.UserId
    end)
end

function Table:Index(player: Player)
    return _table.index(self.Players, function(p)
        return p.Id == player.UserId
    end)
end

function Table:Remove(player: Player)
    local index = self:Index(player)
    if index <= 0 then return end

    table.remove(self.Players, index)
end

function Table:Deal(player: Player?)
    local dealings = {
        ["Community"] = function()
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

            card.Part.Position = _board.CARDEXAMPLE.Position
            -- card.Part.Rotation = Vector3.new(0, -180, 0)
            card.Part.Rotation = Vector3.new(0, 90, 0)

            local leftEdge = inner.Position + Vector3.new(inner.Size.X / 2, 0, 0)
            local targetPos = leftEdge - Vector3.new(slotWidth * (nCards - 1) + (slotWidth / 2), 0, 0)

            local TweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
        end,
        ["Player"] = function(player: Player)
            local _player = self:Get(player)
            local card = self.Deck:Pop()

            -- TODO: assign and get the player's seat
            local _board = workspace.Development.Board
            local seat = nil

            local pos: Vector3 = _board.CARDLINE1.Position
            card.Part.Position = _board.CARDEXAMPLE.Position

            local nCards = #_player.Hand.Cards
            local cardSpacing = card.Part.Size.X * 0.2

            local targetPos = pos + Vector3.new((nCards * cardSpacing), 0, 0)

            local TweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local tween = TweenService:Create(card.Part, tweenInfo, { Position = targetPos, Rotation = Vector3.new(0, math.random(60, 120), 180) })

            local tweenT = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, .6)
            local tweenT1 = TweenService:Create(card.Part, tweenT, { Transparency = 1 })
            local tweenT2 = TweenService:Create(card.Part.Decal, tweenT, { Transparency = 1 })

            tween:Play()

            tweenT1:Play()
            tweenT2:Play()

            workspace.Invisible.Sound:Play()

            _player.Hand:Push(card)
        end,
    }

    local _ =  player and dealings["Player"](player) or dealings["Community"]()
end

return Table
