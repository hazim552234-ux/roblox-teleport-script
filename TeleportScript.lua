-- LocalScript: StarterPlayer > StarterPlayerScripts
-- Teleport and freeze your body ON TOP of the target player's body
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportCycleGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 180, 0, 110)
main.Position = UDim2.new(0.5, -90, 0.5, -55)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
main.BackgroundTransparency = 0.15
main.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local dragBar = Instance.new("TextButton")
dragBar.Size = UDim2.new(1, 0, 0, 24)
dragBar.BackgroundTransparency = 1
dragBar.Text = ""
dragBar.BorderSizePixel = 0
dragBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 18)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "TP Cycle"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 38)
button.Position = UDim2.new(0, 10, 0, 34)
button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
button.BorderSizePixel = 0
button.Text = "Next Player"
button.TextColor3 = Color3.fromRGB(255,255,255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Parent = main

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

-- Dragging logic
local dragging = false
local dragStart
local startPos

local function updateDrag(input)
	if dragging then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end

dragBar.MouseButton1Down:Connect(function(input)
	dragging = true
	dragStart = input.Position
	startPos = main.Position
end)

dragBar.MouseButton1Up:Connect(function()
	dragging = false
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		updateDrag(input)
	end
end)

local targetIndex = 1

local function getPlayerList()
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(list, plr)
		end
	end
	return list
end

local function freezePlayerOnTarget(targetPlayer)
	local char = player.Character
	if not char then return end

	local targetChar = targetPlayer.Character
	if not targetChar then return end

	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Disable movement and rotation
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.AutoRotate = false
	end

	-- Stop velocity
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

	-- Teleport to the exact same position as target
	root.CFrame = targetRoot.CFrame

	-- Align all body parts to the target's position
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CFrame = targetRoot.CFrame
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end

	-- Keep your body frozen ON the target for 1 second
	task.wait(1)

	-- Re-enable movement after freeze
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
		hum.AutoRotate = true
	end

	-- Allow collision again
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

button.MouseButton1Click:Connect(function()
	local players = getPlayerList()
	if #players == 0 then
		button.Text = "No players"
		task.delay(1, function()
			button.Text = "Next Player"
		end)
		return
	end

	targetIndex = targetIndex % #players + 1
	local chosen = players[targetIndex]

	freezePlayerOnTarget(chosen)

	button.Text = "To: " .. chosen.DisplayName
	task.delay(1.2, function()
		button.Text = "Next Player"
	end)
end)
