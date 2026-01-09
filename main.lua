-- HeraWare: Educational Tester for TPS Ultimate (client-side, non-bypass)
-- UI built with ScreenGui; features: firetouch tests, time-resolution delay reducer,
-- Elemental React preview, local practice ball (client-only), teleporter.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
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

-- Local Practice Ball (client-only, for timing drills; does not affect server ball)
local PracticeBall
local function spawnPracticeBall(position)
    if PracticeBall and PracticeBall.Parent then PracticeBall:Destroy() end
    local ball = Instance.new("Part")
    ball.Name = "HeraPracticeBall"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(2,2,2)
    ball.Material = Enum.Material.Neon
    ball.Color = Color3.fromRGB(0, 170, 255)
    ball.Anchored = false
    ball.CanCollide = false
    ball.Position = position or (HRP.Position + Vector3.new(0, 5, 0))
    ball.Parent = Workspace
    PracticeBall = ball
    return ball
end

local function setPracticeBallVelocity(v3)
    if PracticeBall and PracticeBall:IsA("BasePart") then
        PracticeBall.AssemblyLinearVelocity = v3
    end
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
    local ball = findServerBall() or PracticeBall
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
    local ball = findServerBall() or PracticeBall
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

-- Time-resolution delay reducer: increases client timing resolution and predictive cueing
local TimeRes = {
    Enabled = false,
    RateHz = 144,       -- high-frequency local timing loop
    OffsetMs = 20,      -- tune relative to ping; positive starts earlier
    PredictiveCue = true,
    Connection = nil
}

local function timeResStep(dt)
    if not TimeRes.PredictiveCue then return end
    local ball = findServerBall() or PracticeBall
    if not (HRP and ball and ball:IsA("BasePart")) then return end

    local ping = getPingMs()
    local early = (ping / 2 + TimeRes.OffsetMs) / 1000
    local v = ball.AssemblyLinearVelocity
    local predicted = ball.Position + v * early
    local dist = (predicted - HRP.Position).Magnitude

    -- Soft cue: briefly tint the screen border or flash a small indicator
    if dist <= 4.2 then
        if _G.HeraFlash then
            TweenService:Create(_G.HeraFlash, TweenInfo.new(0.08), { BackgroundTransparency = 0.3 }):Play()
            task.delay(0.08, function()
                if _G.HeraFlash then
                    TweenService:Create(_G.HeraFlash, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
                end
            end)
        end
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
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0, 175, 179) end
end
local function tpBlue()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(0.4269, 175.29, 377.40) end
end

-- Elemental React (preview): client-only cue + optional local practice ball velocity
local Elemental = {
    UsePracticeBall = true,    -- spawn local ball for velocity training
    Speed = 100                -- velocity magnitude for local training
}
local function triggerElementalReact()
    if Elemental.UsePracticeBall then
        local ball = PracticeBall or spawnPracticeBall()
        if ball then
            local cam = Workspace.CurrentCamera
            local dir = cam.CFrame.LookVector
            setPracticeBallVelocity(dir * Elemental.Speed)
        end
    end
    if _G.HeraToast then
        _G.HeraToast.Text = "Elemental React (Preview) triggered"
        _G.HeraToast.Visible = true
        task.delay(1.2, function() if _G.HeraToast then _G.HeraToast.Visible = false end end)
    end
end

-- Minimal UI (ScreenGui)
local gui = Instance.new("ScreenGui")
gui.Name = "HeraWareGUI"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.Parent = LP:WaitForChild("PlayerGui")

local function makeFrame(name, pos, size)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.new(0, size.X, 0, size.Y)
    f.Position = UDim2.new(0, pos.X, 0, pos.Y)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    f.BorderSizePixel = 0
    f.Parent = gui
    return f
end

local function makeText(parent, text, pos, size, bold)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, size.X, 0, size.Y)
    l.Position = UDim2.new(0, pos.X, 0, pos.Y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220, 220, 230)
    l.TextScaled = false
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = 16
    l.Parent = parent
    return l
end

local function makeButton(parent, text, pos, size, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, size.X, 0, size.Y)
    b.Position = UDim2.new(0, pos.X, 0, pos.Y)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(235, 235, 245)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = true
    b.Parent = parent
    b.MouseButton1Click:Connect(function()
        pcall(callback, b)
    end)
    return b
end

local function makeSlider(parent, labelText, pos, width, min, max, default, onChange)
    local label = makeText(parent, labelText .. ": " .. tostring(default), Vector2.new(pos.X, pos.Y), Vector2.new(width, 20), true)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, width, 0, 6)
    bar.Position = UDim2.new(0, pos.X, 0, pos.Y + 24)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    bar.BorderSizePixel = 0
    bar.Parent = parent

    local fill = Instance.new("Frame")
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType.Name == "MouseButton1" then dragging = true end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType.Name == "MouseButton1" then dragging = false end
    end)
    bar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType.Name == "MouseMovement" then
            local x = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
            local newPct = x / bar.AbsoluteSize.X
            fill.Size = UDim2.new(newPct, 0, 1, 0)
            local val = math.floor(min + newPct * (max - min))
            label.Text = labelText .. ": " .. tostring(val)
            pcall(onChange, val)
        end
    end)
end

-- Layout
local main = makeFrame("Main", Vector2.new(20, 20), Vector2.new(320, 440))
makeText(main, "HeraWare — Educational Tester", Vector2.new(12, 10), Vector2.new(296, 24), true)

-- Reach section
makeText(main, "Reach (Firetouch)", Vector2.new(12, 44), Vector2.new(296, 20), true)
makeButton(main, "Enable Leg Firetouch: OFF", Vector2.new(12, 70), Vector2.new(296, 28), function(btn)
    Reach.EnabledLegs = not Reach.EnabledLegs
    btn.Text = "Enable Leg Firetouch: " .. (Reach.EnabledLegs and "ON" or "OFF")
end)
makeButton(main, "Use Right Leg: ON", Vector2.new(12, 104), Vector2.new(144, 28), function(btn)
    Reach.UseRightLeg = not Reach.UseRightLeg
    btn.Text = "Use Right Leg: " .. (Reach.UseRightLeg and "ON" or "OFF")
end)
makeButton(main, "Use Left Leg: ON", Vector2.new(164, 104), Vector2.new(144, 28), function(btn)
    Reach.UseLeftLeg = not Reach.UseLeftLeg
    btn.Text = "Use Left Leg: " .. (Reach.UseLeftLeg and "ON" or "OFF")
end)
makeSlider(main, "Leg Distance (studs)", Vector2.new(12, 140), 296, 1, 10, Reach.DistLegs, function(v)
    Reach.DistLegs = v
end)

makeButton(main, "Enable Head Firetouch: OFF", Vector2.new(12, 176), Vector2.new(296, 28), function(btn)
    Reach.EnabledHead = not Reach.EnabledHead
    btn.Text = "Enable Head Firetouch: " .. (Reach.EnabledHead and "ON" or "OFF")
end)
makeSlider(main, "Head Distance (studs)", Vector2.new(12, 212), 296, 1, 10, Reach.DistHead, function(v)
    Reach.DistHead = v
end)
makeButton(main, "Find Ball", Vector2.new(12, 248), Vector2.new(296, 28), function()
    local b = findServerBall() or PracticeBall
    local msg = b and ("Found: " .. b.Name) or "Ball not found"
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 296, 0, 22)
    toast.Position = UDim2.new(0, 12, 0, 280)
    toast.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    toast.TextColor3 = Color3.fromRGB(235, 235, 245)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 14
    toast.Text = msg
    toast.Parent = main
    task.delay(1.2, function() toast:Destroy() end)
end)

-- Delay resolution section
makeText(main, "Delay Reducer (Time Resolution)", Vector2.new(12, 310), Vector2.new(296, 20), true)
makeButton(main, "Enable Reducer: OFF", Vector2.new(12, 336), Vector2.new(296, 28), function(btn)
    TimeRes.Enabled = not TimeRes.Enabled
    btn.Text = "Enable Reducer: " .. (TimeRes.Enabled and "ON" or "OFF")
    setTimeRes(TimeRes.Enabled)
end)
makeSlider(main, "Update Rate (Hz)", Vector2.new(12, 372), 296, 60, 240, TimeRes.RateHz, function(v)
    TimeRes.RateHz = v -- keep one heartbeat connection; Hz guides internal logic
end)
makeSlider(main, "Timing Offset (ms)", Vector2.new(12, 408), 296, -60, 60, TimeRes.OffsetMs, function(v)
    TimeRes.OffsetMs = v
end)

-- Flash overlay used by reducer cues
local flash = Instance.new("Frame")
flash.Size = UDim2.new(1, 0, 0, 3)
flash.Position = UDim2.new(0, 0, 0, 0)
flash.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui
_G.HeraFlash = flash

-- Secondary panel for React & Teleport & Practice Ball
local side = makeFrame("Side", Vector2.new(360, 20), Vector2.new(320, 440))
makeText(side, "Tools", Vector2.new(12, 10), Vector2.new(296, 24), true)

-- Elemental React (preview) + Practice Ball controls
makeText(side, "Elemental React (Preview)", Vector2.new(12, 44), Vector2.new(296, 20), true)
makeButton(side, "Trigger Elemental React", Vector2.new(12, 70), Vector2.new(296, 28), triggerElementalReact)
local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0, 296, 0, 22)
toast.Position = UDim2.new(0, 12, 0, 104)
toast.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
toast.TextColor3 = Color3.fromRGB(235, 235, 245)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 14
toast.Text = ""
toast.Visible = false
toast.Parent = side
_G.HeraToast = toast

makeText(side, "Practice Ball (local-only)", Vector2.new(12, 136), Vector2.new(296, 20), true)
makeButton(side, "Spawn Practice Ball", Vector2.new(12, 162), Vector2.new(296, 28), function()
    local b = spawnPracticeBall()
    if b then
        toast.Text = "Practice ball spawned"
        toast.Visible = true
        task.delay(1.2, function() toast.Visible = false end)
    end
end)
makeSlider(side, "Practice Speed", Vector2.new(12, 198), 296, 10, 200, Elemental.Speed, function(v)
    Elemental.Speed = v
end)
makeButton(side, "Clear Practice Ball", Vector2.new(12, 234), Vector2.new(296, 28), function()
    if PracticeBall and PracticeBall.Parent then PracticeBall:Destroy() end
    toast.Text = "Practice ball cleared"
    toast.Visible = true
    task.delay(1.0, function() toast.Visible = false end)
end)

-- Teleporter
makeText(side, "Teleporter", Vector2.new(12, 276), Vector2.new(296, 20), true)
makeButton(side, "Green Side", Vector2.new(12, 302), Vector2.new(144, 28), tpGreen)
makeButton(side, "Blue Side", Vector2.new(164, 302), Vector2.new(144, 28), tpBlue)

-- Ping display
makeText(side, "Network", Vector2.new(12, 340), Vector2.new(296, 20), true)
makeButton(side, "Show Ping", Vector2.new(12, 366), Vector2.new(296, 28), function()
    local p = math.floor(getPingMs())
    toast.Text = "Ping: " .. tostring(p) .. " ms"
    toast.Visible = true
    task.delay(1.2, function() toast.Visible = false end)
end)

-- Title bar
StarterGui:SetCore("SendNotification", {
    Title = "HeraWare",
    Text = "Loaded: Educational Tester",
    Duration = 3
})
