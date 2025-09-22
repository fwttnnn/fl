--!strict
-- matches storage, keep track of all the matchs (local server scope)
local Storage = {}

function Storage.Find(player: Player): Match
    for _, match in ipairs(Storage) do
        local p = match.Table:Get(player)
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
