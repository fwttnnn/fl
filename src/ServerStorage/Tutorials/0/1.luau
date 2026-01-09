--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage:WaitForChild("Modules")
local Match = require(Modules.Match)

return {
    Title = "the taste of poker"
    Start = function(tenant: Folder)
        local player    = Players.LocalPlayer
        local counselor = { UserId = 0 }

        local function dialog(d: string)
            local label = tenant.Dealer.Head.Dialog
            label.Text = d
        end

        -- "Poker is a game of chance, but your skills are also at stake."
        -- "You don't hope hopelessly"

        dialog("Poker is a game of chance, but it also requires a skill set.")
        dialog("You don't just bet good hands, and certainly you don't just push a button.")

        local conn = nil
        local lock = Instance.new("BindableEvent")

        local match = Match.new({player, fake})

        task.wait(0.55)
        match.Table.Cards.Community:Push(Card.new("K", "Diamonds"))
        match.Table:Deal(player)
        task.wait(0.55)
        match.Table.Cards.Community:Push(Card.new("10", "Diamonds"))
        match.Table:Deal(player)

        task.wait(0.55)
        match.Table.Cards.Community:Push(Card.new("J", "Diamonds"))
        match.Table:Deal(counselor)
        task.wait(0.55)
        match.Table.Cards.Community:Push(Card.new("J", "Clubs"))
        match.Table:Deal(counselor)

        dialog("I'll show you where the skills are required, and where the luck comes in.")

        dialog("Since i've got an ok hand, i'll bet some of my health.")
        dialog("You uh, just call.")
        match.Table.Pot += 10
        match.Table:Get(counselor).Health -= 10

        conn = Events.Match.Turn.Betting.Act.OnServerEvent:Connect(function(p: Player, action)
            if p ~= player then return end
            if action.Type ~= "CALL" then return end

            match.Table.Pot += 10
            match.Table:Get(p).Health -= 10

            lock:Fire()
        end)

        Events.Match.Turn.Betting.Act:FireClient(player, match.Table:Get(player).Health)
        lock.Event:Wait()
        conn:Disconnect()

        task.wait(0.65)
        match.Table.Cards.Community:Push(Card.new("Q", "Spades"))
        match.Table:Deal()
        task.wait(0.65)
        match.Table.Cards.Community:Push(Card.new("6", "Diamonds"))
        match.Table:Deal()
        task.wait(0.65)
        match.Table.Cards.Community:Push(Card.new("10", "Clubs"))
        match.Table:Deal()

        dialog("Here comes the flop, does your hand form a pair?")
        dialog("I think you do, then bet some (10) health.")

        conn = Events.Match.Turn.Betting.Act.OnServerEvent:Connect(function(p: Player, action)
            if p ~= player then return end
            if action.Type ~= "BET" and action.Amount ~= 10 then return end

            match.Table.Pot += 10
            match.Table:Get(p).Health -= 10

            lock:Fire()
        end)

        Events.Match.Turn.Betting.Act:FireClient(player, match.Table:Get(player).Health)
        lock.Event:Wait()
        conn:Disconnect()

        dialog("I told you i had an ok hand, so what are the chances of me pairing another card? it's slim.")
        dialog("In this stage of the game, it's basically a guessing game.")
        dialog("Who has the higher cards value? is it me or you?")
        dialog("This is an example of a guessing game buried in Poker. NOT LUCK.")

        dialog("Well, i think i have the lead, i'll raise.")
        match.Table.Pot += (10 + 10)
        match.Table:Get(counselor).Health -= (10 + 10)

        dialog("You do have a good chance to hit a flush or another pair. Take your chances.")
        dialog("GO ALL IN.")

        conn = Events.Match.Turn.Betting.Act.OnServerEvent:Connect(function(p: Player, action)
            if p ~= player then return end
            if action.Type ~= "ALL IN" then return end

            match.Table.Pot += match.Table:Get(p).Health
            match.Table:Get(p).Health = 0

            lock:Fire()
        end)

        Events.Match.Turn.Betting.Act:FireClient(player, match.Table:Get(player).Health)
        lock.Event:Wait()
        conn:Disconnect()

        dialog("I call.")
        match.Table.Pot += match.Table:Get(counselor).Health
        match.Table:Get(counselor).Health = 0

        task.wait(0.65)
        match.Table.Cards.Community:Push(Card.new("2", "Diamonds"))
        match.Table:Deal()

        dialog("A diamond, this is getting intense..")
        dialog("But you don't beat my hand just yet.")

        task.wait(0.65)
        match.Table.Cards.Community:Push(Card.new("K", "Hearts"))
        match.Table:Deal()

        dialog("There you go, you've won a big prize with a two pair.")
        dialog("The feeling of thrills, and the thinking required to play Poker is remarkable.")

        local hand = Hand.new(player.Hand:Best(self.Table.Cards.Community.Cards))
        local rank = hand:Rank()

        assert(rank.Tier == 3)
        assert(hand:Beats(Hand.new(counselor.Hand:Best(self.Table.Cards.Community.Cards)), {_Our = rank}))

        dialog("Truly, one of a kind.")
    end
}
