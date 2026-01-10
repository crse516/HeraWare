-- HeraWare Aqua Edition (Custom UI)
-- Features: FireTouch reach (match + practice balls), Elemental React ("light speed"), Hera React ("fast+smooth"),
-- Teleporters, Leg Resizer, Stamina placeholder, Level Spoofer placeholder.

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

-- Reacts
local Reacts = {
    Elemental = false, -- "light speed" react
    Hera = false,      -- "fast+smooth" react
    OffsetMs = 20,
    Connection = nil
}

local function reactStep()
    local ball = findServerBall()
    if not (HRP and ball and ball:IsA("BasePart")) then return end

    local ping = getPingMs()
    local early = (ping / 2 + Reacts.OffsetMs) / 1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity * early
    local dist = (predicted - HRP.Position).Magnitude

    if Reacts.Elemental and dist <= 4.2 then
        print("Elemental React (light speed) triggered")
    end
    if Reacts.Hera and dist <= 5.0 then
        print("Hera React (fast+smooth) triggered")
    end
end

local function setReactLoop(state)
    if state and not Reacts.Connection then
        Reacts.Connection = RunService.Heartbeat:Connect(reactStep)
    elseif not state and Reacts.Connection then
        Reacts.Connection:Disconnect()
        Reacts.Connection = nil
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

-- Leg Resizer
local function resizeLeg(legName, scale)
    local char = LP.Character
    if not char then return end
    local leg = char:FindFirstChild(legName)
    if leg and leg:IsA("BasePart") then
        leg.Size = Vector3.new(leg.Size.X, scale, leg.Size.Z)
    end
end

-- Custom UI Framework (simple sidebar style)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
local Window = OrionLib:MakeWindow({Name = "HeraWare Aqua", HidePremium = false, SaveConfig = true, ConfigFolder = "HeraWare"})

-- Tabs
local FireTouchTab = Window:MakeTab({Name = "FireTouch", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local ReactsTab = Window:MakeTab({Name = "Reacts", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local ResizerTab = Window:MakeTab({Name = "Resizer", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TeleportTab = Window:MakeTab({Name = "Teleportation", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local SpooferTab = Window:MakeTab({Name = "Level Spoofer", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- FireTouch options
FireTouchTab:AddToggle({Name = "Leg Firetouch", Default = false, Callback = function(state) Reach.EnabledLegs = state end})
FireTouchTab:AddToggle({Name = "Head Firetouch", Default = false, Callback = function(state) Reach.EnabledHead = state end})
FireTouchTab:AddSlider({Name = "Leg Reach Distance", Min = 1, Max = 20, Default = Reach.DistLegs, Increment = 1, ValueName = "studs", Callback = function(val) Reach.DistLegs = val end})
FireTouchTab:AddSlider({Name = "Head Reach Distance", Min = 1, Max = 20, Default = Reach.DistHead, Increment = 1, ValueName = "studs", Callback = function(val) Reach.DistHead = val end})

-- Reacts options
ReactsTab:AddToggle({Name = "Elemental React (light speed)", Default = false, Callback = function(state) Reacts.Elemental = state; setReactLoop(state or Reacts.Hera) end})
ReactsTab:AddToggle({Name = "Hera React (fast+smooth)", Default = false, Callback = function(state) Reacts.Hera = state; setReactLoop(state or Reacts.Elemental) end})
ReactsTab:AddSlider({Name = "React Offset (ms)", Min = 0, Max = 100, Default = Reacts.OffsetMs, Increment = 5, ValueName = "ms", Callback = function(val) Reacts.OffsetMs = val end})

-- Resizer options
ResizerTab:AddSlider({Name = "Resize Left Leg", Min = 1, Max = 20, Default = 5, Increment = 1, ValueName = "scale", Callback = function(val) resizeLeg("Left Leg", val) end})
ResizerTab:AddSlider({Name = "Resize Right
