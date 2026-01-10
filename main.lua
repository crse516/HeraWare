-- HeraWare Aqua Edition (Kavo UI)
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

-- Ball finder
local function findServerBall()
    local sys = Workspace:FindFirstChild("TPSSystem")
    if sys then
        local tps = sys:FindFirstChild("TPS")
        if tps and tps:IsA("BasePart") then return tps end
    end
    local prac = Workspace:FindFirstChild("Practice")
    if prac then
        for _, c in ipairs(prac:GetDescendants()) do
            if c:IsA("BasePart") and c.Name:lower():find("ball") then return c end
        end
    end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():find("ball") then return d end
    end
    return nil
end

-- Reach
local Reach = {EnabledLegs=false, EnabledHead=false, DistLegs=3, DistHead=5}
RunService.RenderStepped:Connect(function()
    if Reach.EnabledLegs then
        local ball = findServerBall()
        if ball then
            local rl = Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightLowerLeg")
            local ll = Character:FindFirstChild("Left Leg") or Character:FindFirstChild("LeftLowerLeg")
            if rl and (ball.Position-rl.Position).Magnitude <= Reach.DistLegs then safeFireTouch(rl,ball) end
            if ll and (ball.Position-ll.Position).Magnitude <= Reach.DistLegs then safeFireTouch(ll,ball) end
        end
    end
    if Reach.EnabledHead then
        local ball = findServerBall()
        if ball then
            local head = Character:FindFirstChild("Head")
            if head and (ball.Position-head.Position).Magnitude <= Reach.DistHead then safeFireTouch(head,ball) end
        end
    end
end)

-- Reacts
local Reacts = {Elemental=false,Hera=false,OffsetMs=20,Connection=nil}
local function reactStep()
    local ball = findServerBall()
    if not (HRP and ball) then return end
    local ping = getPingMs()
    local early = (ping/2+Reacts.OffsetMs)/1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity*early
    local dist = (predicted-HRP.Position).Magnitude
    if Reacts.Elemental and dist<=4.2 then print("Elemental React (light speed)") end
    if Reacts.Hera and dist<=5.0 then print("Hera React (fast+smooth)") end
end
local function setReactLoop(state)
    if state and not Reacts.Connection then
        Reacts.Connection = RunService.Heartbeat:Connect(reactStep)
    elseif not state and Reacts.Connection then
        Reacts.Connection:Disconnect(); Reacts.Connection=nil
    end
end

-- Teleporters
local function tpGreen() if HRP then HRP.CFrame=CFrame.new(0,175,179) end end
local function tpBlue() if HRP then HRP.CFrame=CFrame.new(0.4269,175.29,377.40) end end

-- Resizer
local function resizeLeg(legName,scale)
    local leg=Character:FindFirstChild(legName)
    if leg and leg:IsA("BasePart") then leg.Size=Vector3.new(leg.Size.X,scale,leg.Size.Z) end
end

-- === Kavo UI ===
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("HeraWare Aqua", "DarkTheme")

-- Tabs
local FireTouchTab = Window:NewTab("FireTouch")
local ReactsTab = Window:NewTab("Reacts")
local ResizerTab = Window:NewTab("Resizer")
local TeleportTab = Window:NewTab("Teleportation")
local MiscTab = Window:NewTab("Misc")
local SpooferTab = Window:NewTab("Level Spoofer")

-- FireTouch
local FireSection = FireTouchTab:NewSection("FireTouch Settings")
FireSection:NewToggle("Leg Firetouch", "Toggle leg reach", function(v) Reach.EnabledLegs=v end)
FireSection:NewToggle("Head Firetouch", "Toggle head reach", function(v) Reach.EnabledHead=v end)
FireSection:NewSlider("Leg Reach Distance", "Adjust leg reach", 20, 1, function(v) Reach.DistLegs=v end)
FireSection:NewSlider("Head Reach Distance", "Adjust head reach", 20, 1, function(v) Reach.DistHead=v end)

-- Reacts
local ReactSection = ReactsTab:NewSection("React Modes")
ReactSection:NewToggle("Elemental React (light speed)", "Fast react mode", function(v) Reacts.Elemental=v; setReactLoop(v or Reacts.Hera) end)
ReactSection:NewToggle("Hera React (fast+smooth)", "Smooth react mode", function(v) Reacts.Hera=v; setReactLoop(v or Reacts.Elemental) end)
ReactSection:NewSlider("React Offset (ms)", "Adjust offset", 100, 0, function(v) Reacts.OffsetMs=v end)

-- Resizer
local ResizeSection = ResizerTab:NewSection("Leg Resizer")
ResizeSection:NewSlider("Resize Left Leg", "Scale left leg", 20, 1, function(v) resizeLeg("Left Leg", v) end)
ResizeSection:NewSlider("Resize Right Leg", "Scale right leg", 20, 1, function(v) resizeLeg("Right Leg", v) end)

-- Teleportation
local TeleSection = TeleportTab:NewSection("Teleport Options")
TeleSection:NewButton("Teleport Green Side", "Move to green side", tpGreen)
TeleSection:NewButton("Teleport Blue Side", "Move to blue side", tpBlue)

-- Misc
local MiscSection = MiscTab:NewSection("Miscellaneous")
MiscSection:NewButton("Get 5x Stamina (placeholder)", "Placeholder stamina boost", function() print("Stamina placeholder") end)

-- Spoofer
local SpoofSection = SpooferTab:NewSection("Level Spoofer")
SpoofSection:NewButton("Spoof Level (placeholder)", "Placeholder spoof", function() print("Spoof placeholder") end)
