local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local ball = workspace:WaitForChild("Football")

-------------------------------------------------
-- SETTINGS
-------------------------------------------------

local DEBUG = true
local GK_ENABLED = false

local reactionDistance = 20
local correctionDistance = 2
local correctionAttempts = 5

local shotVelocityThreshold = 25
local shotAccelerationThreshold = 15
local shotReactTime = 0.4

-------------------------------------------------
-- INTERNAL
-------------------------------------------------

local goalZ
local lastVelocity = Vector3.zero
local lastShotTime = 0

-------------------------------------------------
-- DEBUG
-------------------------------------------------

local function dprint(...)
	if DEBUG then
		print("[GK DEBUG]", ...)
	end
end

-------------------------------------------------
-- UI BUTTON
-------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0,120,0,40)
button.Position = UDim2.new(0,20,0,200)
button.Text = "GK OFF"
button.Parent = gui

button.MouseButton1Click:Connect(function()

	GK_ENABLED = not GK_ENABLED

	if GK_ENABLED then
		button.Text = "GK ON"
	else
		button.Text = "GK OFF"
	end

end)

-------------------------------------------------
-- GOAL LINE
-------------------------------------------------

local function detectGoal()

	while not player.Team do
		task.wait()
	end

	goalZ = rootPart.Position.Z

	dprint("Goal line set:", goalZ)

end

detectGoal()

-------------------------------------------------
-- BALL OWNERSHIP
-------------------------------------------------

local function ballIsOwned()

	for _,v in ipairs(ball:GetDescendants()) do
		
		if v:IsA("Weld") or v:IsA("Motor6D") or v:IsA("WeldConstraint") then
			
			local p0 = v.Part0
			local p1 = v.Part1
			
			if p0 and p0.Parent:FindFirstChild("Humanoid") then
				return true
			end
			
			if p1 and p1.Parent:FindFirstChild("Humanoid") then
				return true
			end
			
		end
		
	end

	return false
end

-------------------------------------------------
-- SHOT DETECTION
-------------------------------------------------

local function detectShot()

	local vel = ball.AssemblyLinearVelocity
	local accel = (vel - lastVelocity).Magnitude
	
	lastVelocity = vel
	
	if vel.Magnitude > shotVelocityThreshold and accel > shotAccelerationThreshold then
		
		lastShotTime = tick()
		
		dprint("SHOT DETECTED")

	end

end

-------------------------------------------------
-- MULTI TELEPORT CORRECTION
-------------------------------------------------

local function teleportToBall()

	for i = 1, correctionAttempts do
		
		local ballPos = ball.Position
		
		local target = Vector3.new(
			ballPos.X,
			math.max(ballPos.Y, rootPart.Position.Y),
			goalZ
		)
		
		rootPart.CFrame = CFrame.new(target)
		
		local dist = (ball.Position - rootPart.Position).Magnitude
		
		if dist < correctionDistance then
			break
		end
		
	end
	
	dprint("Teleport corrected")

end

-------------------------------------------------
-- MAIN LOOP
-------------------------------------------------

RunService.RenderStepped:Connect(function()

	if not GK_ENABLED then
		return
	end

	detectShot()

	local reactingToShot = (tick() - lastShotTime) < shotReactTime

	if ballIsOwned() and not reactingToShot then
		return
	end

	local distance = (ball.Position - rootPart.Position).Magnitude

	if distance > reactionDistance then
		return
	end

	teleportToBall()

end)
