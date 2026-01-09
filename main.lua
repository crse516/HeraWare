-- HeraWare: Educational Tester for TPS Ultimate
-- UI shows immediately; toggle with RightControl
-- Features: Leg/Head firetouch reach, Delay reducer (time-resolution predictive cues),
-- Elemental React trainer (safe), Teleporter (Green/Blue), adjustable distances and offset.

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

-- Utils
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
    -- Try structured locations first
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
    -- Common names
    for _, n in ipairs({"TPS","PSoccerBall","Ball","SoccerBall","Football"}) do
        local b = Workspace:FindFirstChild(n)
        if b and b:IsA("BasePart") then return b end
    end
    -- Fallback scan
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():find("ball") then return d end
    end
    return nil
end

-- Reach config
local Reach = {
    EnabledLegs = false,
    EnabledHead = false,
    DistLegs = 3,  -- adjustable 1–10
    DistHead = 5,  -- adjustable 1–10
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

-- Time-resolution delay reducer + React trainer (safe cues only)
local Trainer = {
    ReducerEnabled = false,
    ReactCueEnabled = false,
    OffsetMs = 20,        -- adjust ±5ms via UI
    Connection = nil
}

local function cueFlash()
    if _G.HeraFlash then
        TweenService:Create(_G.HeraFlash, TweenInfo.new(0.08), { BackgroundTransparency = 0.25 }):Play()
        task.delay(0.08, function()
            if _G.HeraFlash then
                TweenService:Create(_G.HeraFlash, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
            end
        end)
    end
end

local function trainerStep()
    -- Predictive cue; never changes ball physics
    local ball = findServerBall()
    if not (HRP and ball and ball:IsA("BasePart")) then return end

    local ping = getPingMs()
    local early = (ping / 2 + Trainer.OffsetMs) / 1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity * early
    local dist = (predicted - HRP.Position).Magnitude

    -- React window threshold
    if Trainer.ReactCueEnabled and dist <= 4.2 then
        cueFlash()
    end
    -- Optional: if ReducerEnabled, you could add additional local cues/assist behaviors (visual-only)
    if Trainer.ReducerEnabled and dist <= 6.0 then
        -- Soft flash for reducer window
        if _G.HeraFlash then
            TweenService:Create(_G.HeraFlash, TweenInfo.new(0.06), { BackgroundTransparency = 0.55 }):Play()
            task.delay(0.06, function()
                if _G.HeraFlash then
                    TweenService:Create(_G.HeraFlash, TweenInfo.new(0.10), { BackgroundTransparency = 1 }):Play()
                end
            end)
        end
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

-- Teleporter
local function tpGreen()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0, 175, 179) end
end
local function tpBlue()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0.4269, 175.29, 377.40) end
end

-- UI base
local gui = Instance.new("ScreenGui")
gui.Name = "HeraWareGUI"
gui.ResetOnSpawn = false
gui.Enabled = true -- visible immediately
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

-- Flash overlay (top screen bar for cues)
local flash = Instance.new("Frame")
flash.Size = UDim2.new(1, 0, 0, 3)
flash.Position = UDim2.new(0, 0, 0, 0)
flash.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui
_G.HeraFlash = flash

-- Toast label
local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 296, 0, 22)
toast.Position = UDim2.new(0, 12, 0, 104)
toast.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
toast.TextColor3 = Color3.fromRGB(235, 235, 245)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.Text = ""
toast.Visible = false
toast.Parent = gui
_G.HeraToast = toast

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 450)
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -225)
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

-- UI helpers
local function makeButton(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 32)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    b.TextColor3 = Color3.fromRGB(235, 235, 245)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    b.Parent = mainFrame
    b.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return b
end

local function makeStepper(labelText, y, getValue, setValue)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 26)
    label.Position = UDim2.new(0, 10, 0, y)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Text = labelText .. ": " .. tostring(getValue())
    label.Parent = mainFrame

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 40, 0, 26)
    minus.Position = UDim2.new(0, 10, 0, y + 28)
    minus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    minus.TextColor3 = Color3.fromRGB(235, 235, 245)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 14
    minus.Text = "-"

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 40, 0, 26)
    plus.Position = UDim2.new(0, 60, 0, y + 28)
    plus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    plus.TextColor3 = Color3.fromRGB(235, 235, 245)
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 14
    plus.Text = "+"

    minus.Parent = mainFrame
    plus.Parent = mainFrame

    local function refresh()
        label.Text = labelText .. ": " .. tostring(getValue())
    end

    minus.MouseButton1Click:Connect(function()
        local v = getValue()
        setValue(math.max(1, v - 1))
        refresh()
    end)
    plus.MouseButton1Click:Connect(function()
        local v = getValue()
        setValue(math.min(10, v + 1))
        refresh()
    end)

    return { label = label, minus = minus, plus = plus, refresh = refresh }
end

-- Feature buttons
makeButton("Toggle Leg Firetouch", 60, function()
    Reach.EnabledLegs = not Reach.EnabledLegs
    toast.Text = "Leg Firetouch: " .. (Reach.EnabledLegs and "ON" or "OFF")
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeButton("Toggle Head Firetouch", 100, function()
    Reach.EnabledHead = not Reach.EnabledHead
    toast.Text = "Head Firetouch: " .. (Reach.EnabledHead and "ON" or "OFF")
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

local legsStepper = makeStepper("Leg reach (studs)", 140,
    function() return Reach.DistLegs end,
    function(v) Reach.DistLegs = v end
)

local headStepper = makeStepper("Head reach (studs)", 200,
    function() return Reach.DistHead end,
    function(v) Reach.DistHead = v end
)

makeButton("Enable Delay Reducer", 250, function()
    Trainer.ReducerEnabled = true
    setTrainerLoop(true)
    toast.Text = "Delay Reducer: ON"
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

makeButton("Disable Delay Reducer", 290, function()
    Trainer.ReducerEnabled = false
    if not Trainer.ReactCueEnabled then
        setTrainerLoop(false)
    end
    toast.Text = "Delay Reducer: OFF"
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

-- Offset stepper (±5ms per click, clamped 0–100ms)
local offsetLabelY = 330
local offsetLabel = Instance.new("TextLabel")
offsetLabel.Size = UDim2.new(1, -20, 0, 26)
offsetLabel.Position = UDim2.new(0, 10, 0, offsetLabelY)
offsetLabel.BackgroundTransparency = 1
offsetLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
offsetLabel.Font = Enum.Font.Gotham
offsetLabel.TextSize = 14
offsetLabel.Text = "Delay reducer offset (ms): " .. tostring(Trainer.OffsetMs)
offsetLabel.Parent = mainFrame

local offsetMinus = Instance.new("TextButton")
offsetMinus.Size = UDim2.new(0, 40, 0, 26)
offsetMinus.Position = UDim2.new(0, 10, 0, offsetLabelY + 28)
offsetMinus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
offsetMinus.TextColor3 = Color3.fromRGB(235, 235, 245)
offsetMinus.Font = Enum.Font.GothamBold
offsetMinus.TextSize = 14
offsetMinus.Text = "-5"
offsetMinus.Parent = mainFrame

local offsetPlus = Instance.new("TextButton")
offsetPlus.Size = UDim2.new(0, 40, 0, 26)
offsetPlus.Position = UDim2.new(0, 60, 0, offsetLabelY + 28)
offsetPlus.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
offsetPlus.TextColor3 = Color3.fromRGB(235, 235, 245)
offsetPlus.Font = Enum.Font.GothamBold
offsetPlus.TextSize = 14
offsetPlus.Text = "+5"
offsetPlus.Parent = mainFrame

local function refreshOffset()
    offsetLabel.Text = "Delay reducer offset (ms): " .. tostring(Trainer.OffsetMs)
end

offsetMinus.MouseButton1Click:Connect(function()
    Trainer.OffsetMs = math.max(0, Trainer.OffsetMs - 5)
    refreshOffset()
end)
offsetPlus.MouseButton1Click:Connect(function()
    Trainer.OffsetMs = math.min(100, Trainer.OffsetMs + 5)
    refreshOffset()
end)

makeButton("Toggle Elemental React trainer", 380, function()
    Trainer.ReactCueEnabled = not Trainer.ReactCueEnabled
    setTrainerLoop(Trainer.ReactCueEnabled or Trainer.ReducerEnabled)
    toast.Text = "React Trainer: " .. (Trainer.ReactCueEnabled and "ON" or "OFF")
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

-- Teleporters
makeButton("Teleport Green Side", 420, tpGreen)
makeButton("Teleport Blue Side", 460, tpBlue) -- extends frame; adjust size if desired

-- Resize frame to fit last button neatly
mainFrame.Size = UDim2.new(0, 360, 0, 500)

-- Startup notice
StarterGui:SetCore("SendNotification", {
    Title = "HeraWare",
    Text = "Loaded. Toggle UI with RightControl.",
    Duration = 3
})
print("HeraWare UI loaded. Toggle with RightControl.")
