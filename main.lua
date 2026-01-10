-- HeraWare Aqua Edition (Custom Sidebar UI)
-- Matches the style of blur.xyz TPS Ultimate menu (sidebar + panels)

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
}

local function runLegReach()
    if not Reach.EnabledLegs then return end
    local ball = findServerBall()
    if not ball then return end
    local char = LP.Character
    if not char then return end

    local rl = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg")
    local ll = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftLowerLeg")
    if rl and (ball.Position - rl.Position).Magnitude <= Reach.DistLegs then safeFireTouch(rl, ball) end
    if ll and (ball.Position - ll.Position).Magnitude <= Reach.DistLegs then safeFireTouch(ll, ball) end
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
    Elemental = false, -- "light speed"
    Hera = false,      -- "fast+smooth"
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

    if Reacts.Elemental and dist <= 4.2 then print("Elemental React (light speed)") end
    if Reacts.Hera and dist <= 5.0 then print("Hera React (fast+smooth)") end
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

-- === Custom UI (Sidebar style) ===
local ScreenGui = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
ScreenGui.Name = "HeraWareUI"

local Sidebar = Instance.new("Frame", ScreenGui)
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(30,30,30)

local MainPanel = Instance.new("Frame", ScreenGui)
MainPanel.Position = UDim2.new(0, 150, 0, 0)
MainPanel.Size = UDim2.new(1, -150, 1, 0)
MainPanel.BackgroundColor3 = Color3.fromRGB(45,45,45)

-- Helper to switch tabs
local currentTab
local function showTab(tabFrame)
    if currentTab then currentTab.Visible = false end
    tabFrame.Visible = true
    currentTab = tabFrame
end

-- Create tab button
local function makeTabButton(name, order, tabFrame)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1,0,0,40)
    btn.Position = UDim2.new(0,0,0,(order-1)*40)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function() showTab(tabFrame) end)
end

-- === FireTouch Tab ===
local FireTouchFrame = Instance.new("Frame", MainPanel)
FireTouchFrame.Size = UDim2.new(1,0,1,0)
FireTouchFrame.Visible = false

makeTabButton("FireTouch",1,FireTouchFrame)

-- Example toggle (Leg Firetouch)
local legToggle = Instance.new("TextButton", FireTouchFrame)
legToggle.Size = UDim2.new(0,200,0,40)
legToggle.Position = UDim2.new(0,20,0,20)
legToggle.Text = "Leg Firetouch: OFF"
legToggle.MouseButton1Click:Connect(function()
    Reach.EnabledLegs = not Reach.EnabledLegs
    legToggle.Text = "Leg Firetouch: "..(Reach.EnabledLegs and "ON" or "OFF")
end)

-- Head Firetouch toggle
local headToggle = legToggle:Clone()
headToggle.Parent = FireTouchFrame
headToggle.Position = UDim2.new(0,20,0,70)
headToggle.Text = "Head Firetouch: OFF"
headToggle.MouseButton1Click:Connect(function()
    Reach.EnabledHead = not Reach.EnabledHead
    headToggle.Text = "Head Firetouch: "..(Reach.EnabledHead and "ON" or "OFF")
end)

-- === Reacts Tab ===
local ReactsFrame = Instance.new("Frame", MainPanel)
ReactsFrame.Size = UDim2.new(1,0,1,0)
ReactsFrame.Visible = false
makeTabButton("Reacts",2,ReactsFrame)

local elemToggle = Instance.new("TextButton", ReactsFrame)
elemToggle.Size = UDim2.new(0,200,0,40)
elemToggle.Position = UDim2.new(0,20,0,20)
elemToggle.Text = "Elemental React: OFF"
elemToggle.MouseButton1Click:Connect(function()
    Reacts.Elemental = not Reacts.Elemental
    elemToggle.Text = "Elemental React: "..(Reacts.Elemental and "ON" or "OFF")
    setReactLoop(Reacts.Elemental or Reacts
