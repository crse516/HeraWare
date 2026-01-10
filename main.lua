-- HeraWare Aqua Edition (Orion UI)
-- Features: Leg/Head firetouch (works on match + practice balls), delay reducer predictive cues,
-- Elemental React trainer (visual cue), teleporters, adjustable distances & offset.
-- Placeholders: 5x stamina per day, level spoofing (non-exploit stubs).

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

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

-- Ball finder (match + practice balls)
local function findServerBall()
    local sys = Workspace:FindFirstChild("TPSSystem")
    if sys then
        local tps = sys:FindFirstChild("TPS")
        if tps and tps:IsA("BasePart") then return tps end
    end
    local prac = Workspace:FindFirstChild("Practice")
    if prac then
        for _, c in ipairs(prac:GetDescendants()) do
            if c:IsA("BasePart") and c.Name:lower():find("ball") then
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

-- Reach config
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

-- Delay reducer + React trainer
local Trainer = {
    ReducerEnabled = false,
    ReactCueEnabled = false,
    OffsetMs = 20,
    Connection = nil
}

local function trainerStep()
    local ball = findServerBall()
    if not (HRP and ball and ball:IsA("BasePart")) then return end

    local ping = getPingMs()
    local early = (ping / 2 + Trainer.OffsetMs) / 1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity * early
    local dist = (predicted - HRP.Position).Magnitude

    if Trainer.ReactCueEnabled and dist <= 4.2 then
        print("React cue triggered")
    end
    if Trainer.ReducerEnabled and dist <= 6.0 then
        print("Delay reducer cue triggered")
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

-- Orion UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Window = OrionLib:MakeWindow({Name = "HeraWare Aqua", HidePremium = false, SaveConfig = true, ConfigFolder = "HeraWare"})

-- Tabs
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local SpooferTab = Window:MakeTab({Name = "Level Spoofer", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Main features
MainTab:AddToggle({
    Name = "Leg Firetouch",
    Default = false,
    Callback = function(state)
        Reach.EnabledLegs = state
    end
})

MainTab:AddToggle({
    Name = "Head Firetouch",
    Default = false,
    Callback = function(state)
        Reach.EnabledHead = state
    end
})

MainTab:AddSlider({
    Name = "Leg Reach Distance",
    Min = 1,
    Max = 10,
    Default = Reach.DistLegs,
    Color = Color3.fromRGB(0,180,200),
    Increment = 1,
    ValueName = "studs",
    Callback = function(val)
        Reach.DistLegs = val
    end
})

MainTab:AddSlider({
    Name = "Head Reach Distance",
    Min = 1,
    Max = 10,
    Default = Reach.DistHead,
    Color = Color3.fromRGB(0,180,200),
    Increment = 1,
    ValueName = "studs",
    Callback = function(val)
        Reach.DistHead = val
    end
})

MainTab:AddButton({
    Name = "Enable Delay Reducer",
    Callback = function()
        Trainer.ReducerEnabled = true
        setTrainerLoop(true)
    end
})

MainTab:AddButton({
    Name = "Disable Delay Reducer",
    Callback = function()
        Trainer.ReducerEnabled = false
        setTrainerLoop(Trainer.ReactCueEnabled)
    end
})

MainTab:AddSlider({
    Name = "Delay Offset (ms)",
    Min = 0,
    Max = 100,
    Default = Trainer.OffsetMs,
    Color = Color3.fromRGB(0,180,200),
    Increment = 5,
    ValueName = "ms",
    Callback = function(val)
        Trainer.OffsetMs = val
    end
})

MainTab:AddToggle({
    Name = "Elemental React Trainer",
    Default = false,
    Callback = function(state)
        Trainer.ReactCueEnabled = state
        setTrainerLoop(state or Trainer.ReducerEnabled)
    end
})

MainTab:AddButton({
    Name = "Teleport Green Side",
    Callback = tpGreen
})

MainTab:AddButton({
    Name = "Teleport Blue Side",
    Callback = tpBlue
})

-- Misc tab
MiscTab:AddButton({
    Name = "Get 5x Stamina (placeholder)",
    Callback = function()
        print("Stamina placeholder triggered")
    end
})

-- Spoofer tab
SpooferTab:AddButton({
    Name = "Spoof Level (placeholder)",
    Callback = function()
        print("Level spoof placeholder triggered")
    end
})

OrionLib:Init()
