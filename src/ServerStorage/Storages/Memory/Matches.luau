--!strict
-- matches storage, keep track of all the matchs (local server scope)
local Storage = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Modules.Extensions.Table)

function Storage.Find(player: Player): Match
    for _, match in ipairs(Storage) do
        local p = table._find(match.Table.Players, function(p) return p.Player == player end)
        if not p then continue end

        return match
    end

    return nil
end

function Storage.Add(match: Match)
    table.insert(Storage, match)
end

function Storage.Remove(match: Match)
    table.remove(Storage, table.find(Storage, match))
end

return Storage
