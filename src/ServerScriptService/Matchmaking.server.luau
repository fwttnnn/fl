--!strict
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage:WaitForChild("Modules")
local Matchmaking = require(Modules.Matchmaking)

-- NOTE: spawn matchmaking listener
-- task.spawn(Matchmaking.Listen)
