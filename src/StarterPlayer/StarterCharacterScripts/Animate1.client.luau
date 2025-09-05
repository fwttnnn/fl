return

-- local player = game.Players.LocalPlayer
-- local character = player.Character or player.CharacterAdded:Wait()
-- local humanoid = character:WaitForChild("Humanoid")
-- local hrp = character:WaitForChild("HumanoidRootPart")
-- local uis = game:GetService("UserInputService")
-- local camera = workspace.CurrentCamera

-- humanoid.JumpHeight = 0
-- humanoid.UseJumpPower = false
-- humanoid.AutoJumpEnabled = false

-- -- Charge jump config
-- local minCharge = 0.1          -- Minimum time to charge jump (in seconds)
-- local maxCharge = 2.0          -- Maximum time to charge jump (in seconds)
-- local minForce = 50            -- Minimum jump strength
-- local maxForce = 80           -- Maximum jump strength
-- local forwardBoost = 80        -- Forward velocity multiplier

-- local canJump = true

-- local charging = false
-- local chargeStart = 0

-- local isJumping = false

-- local defaultWalkSpeed = humanoid.WalkSpeed

-- local groundedStates = {
-- 	-- [Enum.HumanoidStateType.Running] = true,
-- 	[Enum.HumanoidStateType.Landed] = true,
-- 	[Enum.HumanoidStateType.GettingUp] = true,

-- 	[Enum.HumanoidStateType.Climbing] = true, -- TODO: this should not be proc'ed on parts that isn't climable.
-- }

-- local function onBeganJumpRequest(input: InputObject)
--     if isJumping then return end

-- 	if not charging and canJump then
-- 		charging = true
-- 		chargeStart = tick()
--         humanoid.WalkSpeed = 0
-- 	end
-- end

-- local function onEndedJumpRequest(input: InputObject)
-- 	if charging and canJump then
--         isJumping = true
--     end

-- 	-- if charging and canJump then
-- 	-- 	charging = false
--     --     canJump = false

-- 	-- 	local chargeTime = tick() - chargeStart

-- 	-- 	-- Clamp charge time
-- 	-- 	chargeTime = math.clamp(chargeTime, minCharge, maxCharge)

-- 	-- 	-- Map chargeTime to force
-- 	-- 	local chargePercent = (chargeTime - minCharge) / (maxCharge - minCharge)
-- 	-- 	-- local upwardForce = minForce + (maxForce - minForce) * chargePercent

--     --     local force = minForce + (maxForce - minForce) * chargePercent
--     --     local forwardForce = force * 1.8  -- more horizontal push
--     --     local upwardForce = force * 1.2   -- natural upward hop

--     --     -- Get direction
--     --     local forwardDir = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit

--     --     -- Rotate character
--     --     hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + forwardDir)

--     --     -- More forward than upward = smoother arc
--     --     local jumpVector = forwardDir * forwardForce + Vector3.new(0, upwardForce, 0)
--     --     print(jumpVector)

-- 	-- 	-- Jump state (optional)
-- 	-- 	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

-- 	-- 	-- Apply velocity
-- 	-- 	hrp.AssemblyLinearVelocity = jumpVector
-- 	-- end
-- end

-- ---

-- RunService = game:GetService("RunService")
-- RunService.RenderStepped:Connect(function()
-- 	if isJumping and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
-- 		-- Sustain horizontal movement
-- 		local vel = hrp.AssemblyLinearVelocity
-- 		hrp.AssemblyLinearVelocity = Vector3.new(
-- 			currentJumpForward.X,
-- 			vel.Y,
-- 			currentJumpForward.Z
-- 		)
-- 	end
-- end)

-- -- ...
-- -- ...
-- -- ...

-- humanoid.StateChanged:Connect(function(_, newState)
-- 	if groundedStates[newState] then
-- 		humanoid.WalkSpeed = defaultWalkSpeed
--         canJump = true
--         isJumping = false
-- 	end
-- end)

-- uis.InputBegan:Connect(function(input, gameProcessed)
-- 	if gameProcessed then return end
--     if input.KeyCode ~= Enum.KeyCode.Space then return end

--     onBeganJumpRequest(input)
-- end)

-- uis.InputEnded:Connect(function(input, gameProcessed)
-- 	if gameProcessed then return end
--     if input.KeyCode ~= Enum.KeyCode.Space then return end

--     onEndedJumpRequest(input)
-- end)

-- if uis.TouchEnabled then
-- 	local mobileJumpButton: ImageButton = player.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
	
-- 	mobileJumpButton.InputBegan:Connect(function(input, gameProcessed)
--         if gameProcessed then return end
--         if input.UserInputType ~= Enum.UserInputType.Touch then return end

--         onBeganJumpRequest(input)
-- 	end)

-- 	mobileJumpButton.InputEnded:Connect(function(input, gameProcessed)
--         if gameProcessed then return end
--         if input.UserInputType ~= Enum.UserInputType.Touch then return end

--         onEndedJumpRequest(input)
-- 	end)
-- end
