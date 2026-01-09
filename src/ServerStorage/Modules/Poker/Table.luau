--!strict
local Table = {
    PLAYERS_MIN = 2,
    PLAYERS_MAX = 9,
}
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
        House = require(ServerStorage.Storages.Global.House),
    },
}

function Table.new(players: {[number]: Player}, health: number, part: Folder)
    assert(#players >= Table.PLAYERS_MIN and #players <= Table.PLAYERS_MAX)

    local _players = {}
    for _, player in ipairs(players) do
        table.insert(_players, {
            Id = player.UserId,
            Player = player,

            -- TODO: make this an enum
            Status = {
                ["Alive"]  = true,
                ["Folded"] = false,
                ["All In"] = false,
            },

            Health = health,
            Hand = Hand.new(), 
        })
    end

    local deck = Deck.new(part)
    for _, suit: Folder in ipairs(Cards.Poker:GetChildren()) do
        for _, rank: Part in ipairs(suit:GetChildren()) do
            deck:Push(Card.new(rank.Name, suit.Name))
        end
    end
    deck:Shuffle()

    -- NOTE: create line visualization for the community cards
    local inner = Instance.new("Part")
    inner.Name = "Line"
    inner.Color = Color3.fromRGB(200, 0, 100)
    inner.Transparency = 1
    inner.Anchored = true
    inner.Position = part.Template.Community.Position
    inner.Rotation = Vector3.new(0, -180, 0)
    inner.Size = Vector3.new((Cards.Blank.Size.X + 0.03) * 5, 0, Cards.Blank.Size.Z + 0.05)

    local outer = Instance.new("Part")
    outer.Name = "Outer"
    outer.Anchored = true
    outer.Size = inner.Size + Vector3.new(0.05, 0, 0.05)
    outer.Position = inner.Position
    outer.Transparency = 1
    outer.Parent = part.Template.Community

    -- outer.Color = Color3.fromRGB(202, 191, 163) -- beige
    outer.Color = Color3.fromRGB(196, 40, 28) -- beige
    outer.Material = Enum.Material.Concrete

    local union = outer:SubtractAsync({inner})
    union.Name = "Community"
    union.Position -= Vector3.new(0, 0.0007, 0) -- NOTE: so the lines goes inside the board a little
    union.Parent = part

    inner.Parent = union
    outer:Destroy()

    -- 0 TO DEBUG
    inner.Transparency = 1
    union.Transparency = 1

    return setmetatable({
        Part = part,
        Deck = deck,
        Pot = 0,
        Players = _players,
        Cards = {
            Community = Hand.new(),
            Burned = Hand.new(),
        }
    }, Table)
end

function Table:Destroy()
    self.Deck:Destroy()
    self.Part.Community.Line:Destroy()
    self.Part.Community:Destroy()
end

function Table:Get(player: Player)
    return _table.find(self.Players, function(p)
        return p.Id == player.UserId
    end)
end

function Table:Deal(player: Player)
    local dealings = {
        ["Community"] = function()
            local card: Card = self.Deck:Pop()
            self.Cards.Community:Push(card)

            local inner = self.Part.Community.Line
            local _blank = Cards.Blank:Clone()
            
            local nCards = #self.Cards.Community.Cards
            local slotWidth = _blank.Size.X + 0.03

            _blank.Face.Texture = Cards.Poker[card.Suit][card.Rank].Face.Texture
            _blank.Face.Transparency = 0

            _blank.Anchored = true
            _blank.Parent = inner

            _blank.Position = self.Deck.Part:FindFirstChild("1").Position
            -- _blank.Rotation = Vector3.new(0, -180, 0)
            _blank.Rotation = Vector3.new(0, 90, 0)

            local leftEdge = inner.Position + Vector3.new(inner.Size.X / 2, 0, 0)
            local targetPos = leftEdge - Vector3.new(slotWidth * (nCards - 1) + (slotWidth / 2), 0, 0)

            local TweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local tween = TweenService:Create(_blank, tweenInfo, { Position = targetPos, Rotation = Vector3.new(0, 0, 0) })

            tween:Play()
            workspace.Invisible.SFX.Card.Slide:Play()

            tween.Completed:Once(function()
                local billboard = Instance.new("BillboardGui")
                billboard.Size = UDim2.new(1.25, 0, 0.5, 0)
                billboard.StudsOffsetWorldSpace = Vector3.new(0, .8, 0)
                billboard.Adornee = _blank
                billboard.Parent = _blank

                -- local billboard = Instance.new("Part", _blank)
                -- billboard.Name = "Billboard"
                -- billboard.Size = Vector3.new(1, .5, 0.001)
                -- billboard.Anchored = true
                -- billboard.Massless = true
                -- billboard.CanCollide = false
                -- billboard.Transparency = 1
                -- billboard.CFrame = _blank.CFrame + Vector3.new(0, .8, 0)
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
            local _player = _table.find(self.Players, function(p) return p.Id == player.UserId end)
            local _index = _table.index(self.Players, function(p) return p.Id == player.UserId end)

            local line = self.Part.Template.Lines:FindFirstChild(tostring(_index))
            if not line then warn("cannot find line for", _index) end

            local _blank = Cards.Blank:Clone()
            _blank.Parent = line

            local pos: Vector3 = line.Position
            _blank.CFrame = self.Deck.Part:FindFirstChild("1").CFrame

            local nCards = #_player.Hand.Cards
            local cardSpacing = _blank.Size.X * 0.2

            local targetPos = pos + Vector3.new((nCards * cardSpacing), 0, 0)

            local TweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            local _rot = Vector3.new(_blank.Rotation.X, math.random(0, 120), _blank.Rotation.Z)
            local tween = TweenService:Create(_blank, tweenInfo, { Position = targetPos, Rotation = _rot })

            local tweenT = TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, .6)
            local tweenT1 = TweenService:Create(_blank, tweenT, { Transparency = 1 })
            local tweenT2 = TweenService:Create(_blank.Decal, tweenT, { Transparency = 1 })

            tween:Play()
            tween.Completed:Once(function()
                tweenT1:Play()
                tweenT2:Play()
            end)
            workspace.Invisible.SFX.Card.Slide:Play()

            local card = self.Deck:Pop()
            _player.Hand:Push(card)
        end,
    }

    if player then
        dealings["Player"](player, index)
        return
    end
    dealings["Community"]()
end

return Table
