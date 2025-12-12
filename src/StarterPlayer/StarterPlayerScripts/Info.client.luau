--!strict
local TextChatService = game:GetService("TextChatService")

TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
task.wait(3)

TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage("info -> press q (or 1) to check your cards")
