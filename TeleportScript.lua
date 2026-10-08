-- LocalScript inside StarterPlayer > StarterPlayerScripts
-- Auto teleport cycle through all players - freeze on their body for 1.5 sec even if they walk
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "SmallTeleportGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 110)
frame.Position = UDim2.new(0.5, -90, 0.5, -55)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.15
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local dragBar = Instance.new("TextButton")
dragBar.Size = UDim2.new(1, 0, 0, 24)
dragBar.BackgroundTransparency = 1
dragBar.Text = ""
dragBar.BorderSizePixel = 0
dragBar.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -18, 0, 18)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "TP Cycle"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 42)
button.Position = UDim2.new(0, 10, 0, 34)
button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
button.BorderSizePixel = 0
button.Text = "START"
button.TextColor3 = Color3.fromRGB(255,255,255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

-- Dragging
local dragging = false
local dragStart
local startPos

dragBar.MouseButton1Down:Connect(function(input)
    dragging = true
    dragStart = input.Position
    startPos = frame.Position
end)

dragBar.MouseButton1Up:Connect(function()
    dragging = false
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local teleportActive = false
local targetIndex = 1
local currentTarget = nil
local freezeStartTime = 0
local freezeDuration = 1.5

local function getPlayersToTeleport()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, plr)
        end
    end
    return list
end

local function freezeAndLockToPlayer(targetPlayer)
    local myChar = player.Character
    if not myChar then return end

    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        myHum.WalkSpeed = 0
        myHum.JumpPower = 0
        myHum.AutoRotate = false
    end

    -- Stop all movement
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            part.CanCollide = false
        end
    end
end

local function unfreezePlayer()
    local myChar = player.Character
    if not myChar then return end

    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        myHum.WalkSpeed = 16
        myHum.JumpPower = 50
        myHum.AutoRotate = true
    end

    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

local function teleportToPlayerAndFreeze(targetPlayer)
    local myChar = player.Character
    if not myChar or not targetPlayer or not targetPlayer.Character then return end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then return end

    -- Freeze the player
    freezeAndLockToPlayer(targetPlayer)

    -- Teleport to target position
    myRoot.CFrame = targetRoot.CFrame

    -- Move all body parts to exact target position
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CFrame = targetRoot.CFrame
        end
    end

    currentTarget = targetPlayer
    freezeStartTime = tick()
end

-- RenderStepped loop to keep player locked to target while frozen
RunService.RenderStepped:Connect(function()
    if not teleportActive or not currentTarget or not currentTarget.Character then
        return
    end

    local myChar = player.Character
    if not myChar then return end

    local elapsedTime = tick() - freezeStartTime

    -- While still frozen, lock to target
    if elapsedTime < freezeDuration then
        local targetRoot = currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                myRoot.CFrame = targetRoot.CFrame

                -- Keep all body parts on target even while they walk
                for _, part in ipairs(myChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CFrame = targetRoot.CFrame
                        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
    else
        -- Freeze time done, unfreeze and move to next player
        unfreezePlayer()
        currentTarget = nil

        local players = getPlayersToTeleport()
        if #players > 0 then
            targetIndex = targetIndex % #players + 1
            local nextTarget = players[targetIndex]
            teleportToPlayerAndFreeze(nextTarget)
            button.Text = "To: " .. nextTarget.DisplayName
            task.delay(0.2, function()
                if teleportActive then
                    button.Text = "STOP"
                end
            end)
        end
    end
end)

button.MouseButton1Click:Connect(function()
    teleportActive = not teleportActive

    if teleportActive then
        button.Text = "STOP"
        button.BackgroundColor3 = Color3.fromRGB(220, 20, 60) -- Red

        local players = getPlayersToTeleport()
        if #players == 0 then
            button.Text = "No players"
            teleportActive = false
            button.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Blue
            task.delay(1, function()
                button.Text = "START"
            end)
            return
        end

        targetIndex = 1
        local firstTarget = players[targetIndex]
        teleportToPlayerAndFreeze(firstTarget)
        button.Text = "To: " .. firstTarget.DisplayName
        task.delay(0.2, function()
            if teleportActive then
                button.Text = "STOP"
            end
        end)
    else
        button.Text = "START"
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Blue
        
        unfreezePlayer()
        currentTarget = nil
    end
end)

-- Stop teleporting when player dies
player.CharacterAdded:Connect(function()
    teleportActive = false
    button.Text = "START"
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    currentTarget = nil
end)
