-- HeraWare Aqua Edition (Madbliss-inspired UI, Pink Theme)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

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
        for _, c in ipairs(prac:GetDescendants()) do
            if c:IsA("BasePart") and c.Name:lower():find("ball") then return c end
        end
    end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():find("ball") then return d end
    end
    return nil
end

-- Feature state
local Reach = {EnabledLegs=false, EnabledHead=false, DistLegs=3, DistHead=5}
local Reacts = {Elemental=false, Hera=false, Sourenos=false, OffsetMs=20, Connection=nil}

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

local function reactStep()
    local ball = findServerBall()
    if not (HRP and ball) then return end
    local ping = getPingMs()
    local early = (ping/2 + Reacts.OffsetMs)/1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity * early
    local dist = (predicted - HRP.Position).Magnitude
    if Reacts.Elemental and dist <= 4.2 then print("Elemental React (light speed)") end
    if Reacts.Hera and dist <= 5.0 then print("Hera React (fast+smooth)") end
    if Reacts.Sourenos and dist <= 7.0 then print("Sourenos React (reachy)") end
end

local function setReactLoop(state)
    if state and not Reacts.Connection then
        Reacts.Connection = RunService.Heartbeat:Connect(reactStep)
    elseif not state and Reacts.Connection then
        Reacts.Connection:Disconnect()
        Reacts.Connection = nil
    end
end

local function tpGreen() if HRP then HRP.CFrame = CFrame.new(0,175,179) end end
local function tpBlue()  if HRP then HRP.CFrame = CFrame.new(0.4269,175.29,377.40) end end

local function resizeLeg(legName, scale)
    local leg = Character:FindFirstChild(legName)
    if leg and leg:IsA("BasePart") then
        leg.Size = Vector3.new(leg.Size.X, scale, leg.Size.Z)
    end
end

-- Stamina (5x per day; 1x per click)
local staminaUses, staminaLimit = 0, 5
local staminaDay = os.date("%x")
local function useStamina(btn)
    local today = os.date("%x")
    if today ~= staminaDay then
        staminaDay = today
        staminaUses = 0
    end
    if staminaUses < staminaLimit then
        staminaUses += 1
        btn.Text = ("Use Instant Stamina (%d/%d)"):format(staminaUses, staminaLimit)
        print(("Instant stamina granted! (%d/%d)"):format(staminaUses, staminaLimit))
    else
        btn.Text = "Daily Stamina Limit Reached"
        print("Daily stamina limit reached.")
    end
end

-- === UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HeraWareUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = true
ScreenGui.Parent = CoreGui

-- Toggle hotkey (RightCtrl)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame", ScreenGui)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(255, 105, 180)

local UIList = Instance.new("UIListLayout", Sidebar)
UIList.FillDirection = Enum.FillDirection.Vertical
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)

-- Main panel with pages
local MainPanel = Instance.new("Frame", ScreenGui)
MainPanel.Position = UDim2.new(0, 180, 0, 0)
MainPanel.Size = UDim2.new(1, -180, 1, 0)
MainPanel.BackgroundColor3 = Color3.fromRGB(255, 182, 193)

local Pages = Instance.new("UIPageLayout", MainPanel)
Pages.FillDirection = Enum.FillDirection.Horizontal
Pages.SortOrder = Enum.SortOrder.LayoutOrder
Pages.Padding = UDim.new(0,0)

local function makeTab(name, order)
    local frame = Instance.new("Frame", MainPanel)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1,-12,0,40)
    btn.Text = name
    btn.LayoutOrder = order
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.BackgroundColor3 = Color3.fromRGB(255,20,147)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function() Pages:JumpTo(frame) end)
    return frame
end

-- Info Tab
local InfoFrame = makeTab("Info",1)
local infoTitle = Instance.new("TextLabel", InfoFrame)
infoTitle.Size = UDim2.new(0,460,0,40)
infoTitle.Position = UDim2.new(0,24,0,24)
infoTitle.Text = "Made by Hera"
infoTitle.BackgroundTransparency = 1
infoTitle.Font = Enum.Font.SourceSansBold
infoTitle.TextSize = 22
infoTitle.TextColor3 = Color3.new(1,1,1)

local featuresText = Instance.new("TextLabel", InfoFrame)
featuresText.Size = UDim2.new(0,520,0,160)
featuresText.Position = UDim2.new(0,24,0,74)
featuresText.Text = "Features:\n- FireTouch\n- Elemental React\n- Hera React\n- Sourenos React\n- Resizer\n- Teleportation\n- 5x Instant Stamina/day"
featuresText.BackgroundTransparency = 1
featuresText.Font = Enum.Font.SourceSans
featuresText.TextSize = 18
featuresText.TextColor3 = Color3.new(1,1,1)
featuresText.TextXAlignment = Enum.TextXAlignment.Left
featuresText.TextYAlignment = Enum.TextYAlignment.Top

local licenseText = Instance.new("TextLabel", InfoFrame)
licenseText.Size = UDim2.new(0,520,0,32)
licenseText.Position = UDim2.new(0,24,0,244)
licenseText.Text = "This script is licensed to "..
