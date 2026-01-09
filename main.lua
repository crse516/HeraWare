-- HeraWare: Educational Tester for TPS Ultimate
-- Visible on execution, toggle with RightControl

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Utilities
local function getPingMs()
    local item = Stats.Network.ServerStatsItem["Data Ping"]
    return item and item:GetValue() or 0
end

local function safeFireTouch(part, ball)
    if not (part and ball and part:IsA("BasePart") and ball:IsA("BasePart")) then return end
    pcall(function()
        firetouchinterest(part, ball, 0)
        task.wait()
        firetouchinterest(part, ball, 1)
    end)
end

local function findServerBall()
    local sys = Workspace:FindFirstChild("TPSSystem")
    if sys then
        local tps = sys:FindFirstChild("TPS")
        if tps and tps:IsA("BasePart") then return tps end
    end
    local prac = Workspace:FindFirstChild("Practice")
    if prac then
        for _, c in ipairs(prac:GetChildren()) do
            if c:IsA("BasePart") and (c.Name == "PSoccerBall" or c.Name == "Ball") then
                return c
            end
        end
    end
    for _, n in ipairs({"TPS","PSoccerBall","Ball","SoccerBall","Football"}) do
        local b = Workspace:FindFirstChild(n)
        if b and b:IsA("BasePart") then return b end
    end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():find("ball") then return d end
    end
    return nil
end

-- Firetouch config
local Reach = {
    EnabledLegs = false,
    EnabledHead = false,
    DistLegs = 3,
    DistHead = 5,
    UseRightLeg = true,
    UseLeftLeg = true,
}

local function runLegReach()
    if not Reach.EnabledLegs then return end
    local ball = findServerBall()
    if not ball then return end
    local char = LP.Character
    if not char then return end

    if Reach.UseRightLeg then
        local rl = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg")
        if rl and (ball.Position - rl.Position).Magnitude <= Reach.DistLegs then
            safeFireTouch(rl, ball)
        end
    end
    if Reach.UseLeftLeg then
        local ll = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftLowerLeg")
        if ll and (ball.Position - ll.Position).Magnitude <= Reach.DistLegs then
            safeFireTouch(ll, ball)
        end
    end
end

local function runHeadReach()
    if not Reach.EnabledHead then return end
    local ball = findServerBall()
    if not ball then return end
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head and (ball.Position - head.Position).Magnitude <= Reach.DistHead then
        safeFireTouch(head, ball)
    end
end

RunService.RenderStepped:Connect(function()
    runLegReach()
    runHeadReach()
end)

-- Time-Resolution Delay Reducer
local TimeRes = {
    Enabled = false,
    OffsetMs = 20,
    PredictiveCue = true,
    Connection = nil
}

local function timeResStep()
    if not TimeRes.PredictiveCue then return end
    local ball = findServerBall()
    if not (HRP and ball and ball:IsA("BasePart")) then return end

    local ping = getPingMs()
    local early = (ping / 2 + TimeRes.OffsetMs) / 1000
    local v = ball.AssemblyLinearVelocity
    local predicted = ball.Position + v * early
    local dist = (predicted - HRP.Position).Magnitude

    if dist <= 4.2 and _G.HeraFlash then
        TweenService:Create(_G.HeraFlash, TweenInfo.new(0.08), { BackgroundTransparency = 0.3 }):Play()
        task.delay(0.08, function()
            if _G.HeraFlash then
                TweenService:Create(_G.HeraFlash, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
            end
        end)
    end
end

local function setTimeRes(state)
    TimeRes.Enabled = state
    if state and not TimeRes.Connection then
        TimeRes.Connection = RunService.Heartbeat:Connect(timeResStep)
    elseif not state and TimeRes.Connection then
        TimeRes.Connection:Disconnect()
        TimeRes.Connection = nil
    end
end

-- Teleporter
local function tpGreen()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0, 175, 179) end
end
local function tpBlue()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0.4269, 175.29, 377.40) end
end

-- Elemental React (preview)
local function triggerElementalReact()
    if _G.HeraToast then
        _G.HeraToast.Text = "Elemental React triggered (preview)"
        _G.HeraToast.Visible = true
        task.delay(1.2, function() if _G.HeraToast then _G.HeraToast.Visible = false end end)
    end
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "HeraWareGUI"
gui.ResetOnSpawn = false
gui.Enabled = true -- always visible on execution
gui.IgnoreGuiInset = true
gui.Parent = LP:WaitForChild("PlayerGui")

-- Toggle UI with RightControl
local ToggleKey = Enum.KeyCode.RightControl
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == ToggleKey then
        gui.Enabled = not gui.Enabled
    end
end)

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 400)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "HeraWare"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

-- Buttons
local function makeButton(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    b.TextColor3 = Color3.fromRGB(235, 235, 245)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    b.Parent = mainFrame
    b.MouseButton1Click:Connect(callback)
    return b
end

makeButton("Toggle Leg Firetouch", 60, function()
    Reach.EnabledLegs = not Reach.EnabledLegs
end)
makeButton("Toggle Head Firetouch", 100, function()
    Reach.EnabledHead = not Reach.EnabledHead
end)
makeButton("Enable Delay Reducer", 140, function()
    setTimeRes(true)
end)
makeButton("Disable Delay Reducer", 180, function()
    setTimeRes(false)
end)
makeButton("Trigger Elemental React", 220, triggerElementalReact)
makeButton("Teleport Green Side", 260, tpGreen)
makeButton("Teleport Blue Side", 300, tpBlue)

-- Flash overlay for delay reducer cues
local flash = Instance.new("Frame")
flash.Size = UDim2.new(1, 0, 0, 3)
flash.Position = UDim2.new(0, 0, 0, 0)
flash.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent =
