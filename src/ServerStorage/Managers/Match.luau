--!strict
-- Match Manager, keep track of all the matchs
local MatchManager = {}

function MatchManager.FindPlayerMatch(player: Player): Match
    for _, match in ipairs(MatchManager) do
        if match.Table:GetPlayer(player) then
            return match
        end
    end

    return nil
end

function MatchManager.Add(match: Match)
    table.insert(MatchManager, match)
end

function MatchManager.Remove(match: Match)
    table.remove(MatchManager, match)
end

return MatchManager
