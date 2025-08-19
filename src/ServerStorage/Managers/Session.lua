--!strict
-- Session Manager, keep track of all the sessions
local SessionManager = {}

function SessionManager.FindPlayerSession(player: Player): Session
    for _, session in ipairs(SessionManager) do
        if session.Table:GetPlayer(player) then
            return session
        end
    end

    return nil
end

function SessionManager.Add(session: Session)
    table.insert(SessionManager, session)
end

function SessionManager.Remove(session: Session)
    table.remove(SessionManager, session)
end

return SessionManager
