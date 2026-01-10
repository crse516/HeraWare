-- HeraWare Aqua Edition
-- UI shows immediately; toggle with RightControl
-- Safe features: Leg/Head firetouch (match + practice balls), delay reducer predictive cues,
-- Elemental React trainer (visual cue), teleporters, adjustable distances & offset.
-- Placeholders: 5x stamina per day, level spoofing (non-exploit stubs).

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
    -- Prefer structured locations/names to catch match and practice balls
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

-- Reach config (applies to practice and match balls via findServerBall)
local Reach = {
    EnabledLegs = false,
    EnabledHead = false,
    DistLegs = 3,   -- adjustable 1–10
    DistHead = 5,   -- adjustable 1–10
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
        local ll = char:FindFirstChild("Left Leg") or char:FindChild("LeftLowerLeg")
        ll = ll or char:FindFirstChild("LeftLowerLeg") -- safety
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

-- Delay reducer + Elemental React trainer (visual cues only; no physics manipulation)
local Trainer = {
    ReducerEnabled = false,
    ReactCueEnabled = false,
    OffsetMs = 20,        -- adjustable via UI, clamped 0–100
    Connection = nil
}

local function cueFlash(intensity)
    if _G.HeraFlash then
        local alpha = intensity or 0.3
        TweenService:Create(_G.HeraFlash, TweenInfo.new(0.08), { BackgroundTransparency = 1 - alpha }):Play()
        task.delay(0.08, function()
            if _G.HeraFlash then
                TweenService:Create(_G.HeraFlash, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
            end
        end)
    end
end

local function trainerStep()
    local ball = findServerBall()
    if not (HRP and ball and ball:IsA("BasePart")) then return end

    local ping = getPingMs()
    local early = (ping / 2 + Trainer.OffsetMs) / 1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity * early
    local dist = (predicted - HRP.Position).Magnitude

    if Trainer.ReactCueEnabled and dist <= 4.2 then
        cueFlash(0.4) -- bright flash for react window
    end
    if Trainer.ReducerEnabled and dist <= 6.0 then
        cueFlash(0.2) -- softer flash for reducer assist window
    end
end

local function setTrainerLoop(state)
    if state and not Trainer.Connection then
        Trainer.Connection = RunService.Heartbeat:Connect(trainerStep)
    elseif not state and Trainer.Connection then
        Trainer.Connection:Disconnect()
        Trainer.Connection = nil
    end
end

-- Teleporters
local function tpGreen()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0, 175, 179) end
end
local function tpBlue()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0.4269, 175.29, 377.40) end
end

-- UI setup (Aqua theme + tabs)
local gui = Instance.new("ScreenGui")
gui.Name = "HeraWareGUI"
gui.ResetOnSpawn = false
gui.Enabled = true -- visible immediately
gui.IgnoreGuiInset = true
gui.Parent = LP:WaitForChild("PlayerGui")

-- Toggle UI with RightControl
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
    end
end)

-- Theme
local aquaPrimary = Color3.fromRGB(0, 180, 200)
local aquaSecondary = Color3.fromRGB(0, 120, 140)
local aquaPanel = Color3.fromRGB(20, 45, 55)
local textColor = Color3.fromRGB(240, 255, 255)

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 540)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -270)
mainFrame.BackgroundColor3 = aquaSecondary
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.BackgroundTransparency = 1
title.Text = "HeraWare Aqua"
title.TextColor3 = textColor
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = mainFrame

-- Flash overlay (top bar)
local flash = Instance.new("Frame")
flash.Size = UDim2.new(1, 0, 0, 4)
flash.Position = UDim2.new(0, 0, 0, 0)
flash.BackgroundColor3 = aquaPrimary
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui
_G.HeraFlash = flash

-- Toast label
local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 340, 0, 24)
toast.Position = UDim2.new(0, 14, 0, 80)
toast.BackgroundColor3 = aquaPanel
toast.TextColor3 = textColor
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.Text = ""
toast.Visible = false
toast.Parent = gui
_G.HeraToast = toast

-- Tabs
local tabs = {}
local currentTab

local function makeTab(name, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 140, 0, 32)
    b.Position = UDim2.new(0, x, 0, 56)
    b.BackgroundColor3 = aquaPrimary
    b.TextColor3 = textColor
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = name
    b.Parent = mainFrame

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 1, -110)
    frame.Position = UDim2.new(0, 10, 0, 100)
    frame.BackgroundColor3 = aquaPanel
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = mainFrame
    tabs[name] = frame

    b.MouseButton1Click:Connect(function()
        if currentTab then currentTab.Visible = false end
        frame.Visible = true
        currentTab = frame
    end)
end

makeTab("Main", 10)
makeTab("Misc", 160)
makeTab("Level Spoofer", 310)

-- UI helpers
local function makeButton(parent, text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 34)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = aquaPrimary
    b.TextColor3 = textColor
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    b.Parent = parent
    b.MouseButton1Click:Connect(function() pcall(callback) end)
    return b
end

local function makeStepper(parent, labelText, y, getValue, setValue, minV, maxV, step)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 26)
    label.Position = UDim2.new(0, 10, 0, y)
    label.BackgroundTransparency = 1
    label.TextColor3 = textColor
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Text = labelText .. ": " .. tostring(getValue())
    label.Parent = parent

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 50, 0, 26)
    minus.Position = UDim2.new(0, 10, 0, y + 28)
    minus.BackgroundColor3 = aquaSecondary
    minus.TextColor3 = textColor
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.Text = "-" .. tostring(step)

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 50, 0, 26)
    plus.Position = UDim2.new(0, 70, 0, y + 28)
    plus.BackgroundColor3 = aquaSecondary
    plus.TextColor3 = textColor
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 14
    plus.Text = "+" .. tostring(step)

    minus.Parent = parent
    plus.Parent = parent

    local function refresh() label.Text = labelText .. ": " .. tostring(getValue()) end
    minus.MouseButton1Click:Connect(function()
        local v = getValue()
        setValue(math.max(minV, v - step))
        refresh()
    end)
    plus.MouseButton1Click:Connect(function()
        local v = getValue()
        setValue(math.min(maxV, v + step))
        refresh()
    end)

    return { label = label, minus = minus, plus = plus, refresh = refresh }
end

-- Main tab: real feature wiring
makeButton(tabs["Main"], "Toggle Leg Firetouch", 20, function()
    Reach.EnabledLegs = not Reach.EnabledLegs
    toast.Text = "Leg Firetouch: " .. (Reach.EnabledLegs and "ON" or "OFF")
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeButton(tabs["Main"], "Toggle Head Firetouch", 60, function()
    Reach.EnabledHead = not Reach.EnabledHead
    toast.Text = "Head Firetouch: " .. (Reach.EnabledHead and "ON" or "OFF")
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeStepper(tabs["Main"], "Leg reach (studs)", 100,
    function() return Reach.DistLegs end,
    function(v) Reach.DistLegs = v end,
    1, 10, 1
)

makeStepper(tabs["Main"], "Head reach (studs)", 160,
    function() return Reach.DistHead end,
    function(v) Reach.DistHead = v end,
    1, 10, 1
)

makeButton(tabs["Main"], "Enable Delay Reducer", 210, function()
    Trainer.ReducerEnabled = true
    setTrainerLoop(true)
    toast.Text = "Delay Reducer: ON"
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeButton(tabs["Main"], "Disable Delay Reducer", 250, function()
    Trainer.ReducerEnabled = false
    setTrainerLoop(Trainer.ReactCueEnabled) -- keep loop if react trainer still on
    toast.Text = "Delay Reducer: OFF"
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeStepper(tabs["Main"], "Delay reducer offset (ms)", 290,
    function() return Trainer.OffsetMs end,
    function(v) Trainer.OffsetMs = math.clamp(v, 0, 100) end,
    0, 100, 5
)

makeButton(tabs["Main"], "Toggle Elemental React trainer", 340, function()
    Trainer.ReactCueEnabled = not Trainer.ReactCueEnabled
    setTrainerLoop(Trainer.ReactCueEnabled or Trainer.ReducerEnabled)
    toast.Text = "React Trainer: " .. (Trainer.ReactCueEnabled and "ON" or "OFF")
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeButton(tabs["Main"], "Teleport Green Side", 380, tpGreen)
makeButton(tabs["Main"], "Teleport Blue Side", 420, tpBlue)

-- Misc tab: safe placeholder (no stat manipulation)
makeButton(tabs["Misc"], "Get 5x Stamina (placeholder)", 20, function()
    toast.Text = "5x Stamina is a placeholder (visual only)."
    toast.Visible = true
    task.delay(1.5, function() toast.Visible = false end)
end)

-- Level Spoofer tab: safe placeholder (no server spoofing)
makeButton(tabs["Level Spoofer"], "Spoof Level (placeholder)", 20, function()
    toast.Text = "Level spoofing is a placeholder (visual only)."
    toast.Visible = true
    task.delay(1.5, function() toast.Visible = false end)
end)

-- Show Main tab by default
tabs["Main"].Visible = true
currentTab = tabs["Main"]

-- Startup notice
StarterGui:SetCore("SendNotification", {
    Title = "HeraWare Aqua",
    Text = "Loaded. Toggle UI with RightControl.",
    Duration = 3
})
print("HeraWare Aqua UI loaded. Toggle with RightControl.")
