--!strict
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Modules = ServerStorage:WaitForChild("Modules")
local Match = require(Modules.Match)

local Storages = {
    Memory = {
        Matches = require(ServerStorage:WaitForChild("Storages").Memory.Matches),
        Players = require(ServerStorage:WaitForChild("Storages").Memory.Players),
    },
}

local __players = {}
Players.PlayerAdded:Connect(function(player)
    table.insert(__players, player)

    -- NOTE: so that when player respawn, they would be re-loaded.
    player.CharacterAdded:Connect(function(character)
        Storages.Memory.Players.Load(player)
    end)
end)

while true do
    task.wait(0.5)
    if #__players < 2 then continue end

    local p2 = table.remove(__players)
    local p1 = table.remove(__players)

    task.spawn(function()
        -- TODO: remove this, just wait for it to load on some script
        Storages.Memory.Players.Load(p1)
        Storages.Memory.Players.Load(p2)

        local match = Match.new({p1, p2})
        Storages.Memory.Matches.Add(match)

        local function _start()
            match:Start()

            -- NOTE: players disconnected
            if #match.Table.Players <= 1 then
                Storages.Memory.Matches.Remove(match)
                match.Table:Destroy() -- TODO: ...
                return
            end

            task.wait(3)
            local players = match:Rematch()
            if #players <= 1 then
                Storages.Memory.Matches.Remove(match)
                match.Table:Destroy() -- TODO: ...
                return
            end

            match:Reset(players)
            _start()
        end

        _start()
    end)
end
