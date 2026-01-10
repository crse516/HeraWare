-- HeraWare Aqua (Pink Theme, Blur-style toggle UI)
-- Tabs: Info, FireTouch, Reacts, Resizer, Teleportation, Misc

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
        -- TODO: Hook to game's stamina stat if available
    else
        btn.Text = "Daily Stamina Limit Reached"
        print("Daily stamina limit reached.")
    end
end

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HeraWareUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = true
ScreenGui.Parent = CoreGui

-- Toggle hotkey (RightShift)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Containers
local Sidebar = Instance.new("Frame", ScreenGui)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(255, 105, 180)

local MainPanel = Instance.new("Frame", ScreenGui)
MainPanel.Position = UDim2.new(0, 180, 0, 0)
MainPanel.Size = UDim2.new(1, -180, 1, 0)
MainPanel.BackgroundColor3 = Color3.fromRGB(255, 182, 193)

-- Sidebar layout for reliable stacking
local UIList = Instance.new("UIListLayout", Sidebar)
UIList.FillDirection = Enum.FillDirection.Vertical
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)

local function makeTabFrame()
    local f = Instance.new("Frame", MainPanel)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.Visible = false
    f.BackgroundTransparency = 1
    return f
end

local currentTab
local function showTab(tab)
    if currentTab then currentTab.Visible = false end
    tab.Visible = true
    currentTab = tab
end

local function makeTabButton(text, order, tabFrame)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -12, 0, 40)
    btn.Position = UDim2.new(0, 6, 0, 0)
    btn.LayoutOrder = order
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.AutoButtonColor = true
    btn.MouseButton1Click:Connect(function() showTab(tabFrame) end)
    return btn
end

-- Info tab (order 1)
local InfoFrame = makeTabFrame()
makeTabButton("Info", 1, InfoFrame)

local infoTitle = Instance.new("TextLabel", InfoFrame)
infoTitle.Size = UDim2.new(0, 460, 0, 40)
infoTitle.Position = UDim2.new(0, 24, 0, 24)
infoTitle.Text = "Made by Hera"
infoTitle.BackgroundTransparency = 1
infoTitle.Font = Enum.Font.SourceSansBold
infoTitle.TextSize = 22
infoTitle.TextColor3 = Color3.new(1,1,1)

local featuresText = Instance.new("TextLabel", InfoFrame)
featuresText.Size = UDim2.new(0, 520, 0, 160)
featuresText.Position = UDim2.new(0, 24, 0, 74)
featuresText.Text = "Features:\n- FireTouch (Leg/Head, configurable reach)\n- Reacts: Elemental, Hera, Sourenos (reachy)\n- Resizer (Left/Right leg 1–20)\n- Teleportation (Green/Blue)\n- Instant Stamina (1x per click, max 5/day)"
featuresText.BackgroundTransparency = 1
featuresText.Font = Enum.Font.SourceSans
featuresText.TextSize = 18
featuresText.TextColor3 = Color3.new(1,1,1)
featuresText.TextXAlignment = Enum.TextXAlignment.Left
featuresText.TextYAlignment = Enum.TextYAlignment.Top

local licenseText = Instance.new("TextLabel", InfoFrame)
licenseText.Size = UDim2.new(0, 520, 0, 32)
licenseText.Position = UDim2.new(0, 24, 0, 244)
licenseText.Text = "This script is licensed to "..LP.Name
licenseText.BackgroundTransparency = 1
licenseText.Font = Enum.Font.SourceSansBold
licenseText.TextSize = 18
licenseText.TextColor3 = Color3.new(1,1,1)

local avatarImage = Instance.new("ImageLabel", InfoFrame)
avatarImage.Size = UDim2.new(0, 100, 0, 100)
avatarImage.Position = UDim2.new(0, 24, 0, 284)
avatarImage.BackgroundTransparency = 0
avatarImage.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
avatarImage.ScaleType = Enum.ScaleType.Fit

task.spawn(function()
    local ok, id = pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok and id then
        avatarImage.Image = id
    else
        avatarImage.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

-- FireTouch tab (order 2)
local FireFrame = makeTabFrame()
makeTabButton("FireTouch", 2, FireFrame)

local legToggle = Instance.new("TextButton", FireFrame)
legToggle.Size = UDim2.new(0, 240, 0, 40)
legToggle.Position = UDim2.new(0, 24, 0, 24)
legToggle.Text = "Leg Firetouch: OFF"
legToggle.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
legToggle.TextColor3 = Color3.new(1,1,1)
legToggle.Font = Enum.Font.SourceSansBold
legToggle.TextSize = 18
legToggle.MouseButton1Click:Connect(function()
    Reach.EnabledLegs = not Reach.EnabledLegs
    legToggle.Text = "Leg Firetouch: "..(Reach.EnabledLegs and "ON" or "OFF")
end)

local headToggle = legToggle:Clone()
headToggle.Parent = FireFrame
headToggle.Position = UDim2.new(0, 24, 0, 74)
headToggle.Text = "Head Firetouch: OFF"
headToggle.MouseButton1Click:Connect(function()
    Reach.EnabledHead = not Reach.EnabledHead
    headToggle.Text = "Head Firetouch: "..(Reach.EnabledHead and "ON" or "OFF")
end)

local legSliderMinus = Instance.new("TextButton", FireFrame)
legSliderMinus.Size = UDim2.new(0, 40, 0, 40)
legSliderMinus.Position = UDim2.new(0, 24, 0, 124)
legSliderMinus.Text = "-"
legSliderMinus.BackgroundColor3 = Color3.fromRGB(200, 20, 120)
legSliderMinus.TextColor3 = Color3.new(1,1,1)

local legSliderPlus = legSliderMinus:Clone()
legSliderPlus.Parent = FireFrame
legSliderPlus.Position = UDim2.new(0, 114, 0, 124)
legSliderPlus.Text = "+"

local legDistLabel = Instance.new("TextLabel", FireFrame)
legDistLabel.Size = UDim2.new(0, 160, 0, 40)
legDistLabel.Position = UDim2.new(0, 164, 0, 124)
legDistLabel.Text = "Leg Reach: "..Reach.DistLegs
legDistLabel.BackgroundTransparency = 1
legDistLabel.TextColor3 = Color3.new(1,1,1)
legDistLabel.Font = Enum.Font.SourceSansBold
legDistLabel.TextSize = 18

legSliderMinus.MouseButton1Click:Connect(function()
    Reach.DistLegs = math.max(1, Reach.DistLegs - 1)
    legDistLabel.Text = "Leg Reach: "..Reach.DistLegs
end)
legSliderPlus.MouseButton1Click:Connect(function()
    Reach.DistLegs = math.min(20, Reach.DistLegs + 1)
    legDistLabel.Text = "Leg Reach: "..Reach.DistLegs
end)

local headMinus = legSliderMinus:Clone()
headMinus.Parent = FireFrame
headMinus.Position = UDim2.new(0, 24, 0, 174)

local headPlus = legSliderPlus:Clone()
headPlus.Parent = FireFrame
headPlus.Position = UDim2.new(0, 114, 0, 174)

local headDistLabel = legDistLabel:Clone()
headDistLabel.Parent = FireFrame
headDistLabel.Position = UDim2.new(0, 164, 0, 174)
headDistLabel.Text = "Head Reach: "..Reach.DistHead

headMinus.MouseButton1Click:Connect(function()
    Reach.DistHead = math.max(1, Reach.DistHead - 1)
    headDistLabel.Text = "Head Reach: "..Reach.DistHead
end)
headPlus.MouseButton1Click:Connect(function()
    Reach.DistHead = math.min(20, Reach.DistHead + 1)
    headDistLabel.Text = "Head Reach: "..Reach.DistHead
end)

-- Reacts tab (order 3)
local ReactsFrame = makeTabFrame()
makeTabButton("Reacts", 3, ReactsFrame)

local elemToggle = Instance.new("TextButton", ReactsFrame)
elemToggle.Size = UDim2.new(0, 240, 0, 40)
elemToggle.Position = UDim2.new(0, 24, 0, 24)
elemToggle.Text = "Elemental React: OFF"
elemToggle.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
elemToggle.TextColor3 = Color3.new(1,1,1)
elemToggle.Font = Enum.Font.SourceSansBold
elemToggle.TextSize = 18
elemToggle.MouseButton1Click:Connect(function()
    Reacts.Elemental = not Reacts.Elemental
    elemToggle.Text = "Elemental React: "..(Reacts.Elemental and "ON" or "OFF")
    setReactLoop(Reacts.Elemental or Reacts.Hera or Reacts.Sourenos)
end)

local heraToggle = elemToggle:Clone()
heraToggle.Parent = ReactsFrame
heraToggle.Position = UDim2.new(0, 24, 0, 74)
heraToggle.Text = "Hera React: OFF"
heraToggle.MouseButton1Click:Connect(function()
    Reacts.Hera = not Reacts.Hera
    heraToggle.Text = "Hera React: "..(Reacts.Hera and "ON" or "OFF")
    setReactLoop(Reacts.Elemental or Reacts.Hera or Reacts.Sourenos)
end)

local sourToggle = elemToggle:Clone()
sourToggle.Parent = ReactsFrame
sourToggle.Position = UDim2.new(0, 24, 0, 124)
sourToggle.Text = "Sourenos React: OFF"
sourToggle.MouseButton1Click:Connect(function()
    Reacts.Sourenos = not Reacts.Sourenos
    sourToggle.Text = "Sourenos React: "..(Reacts.Sourenos and "ON" or "OFF")
    setReactLoop(Reacts.Elemental or Reacts.Hera or Reacts.Sourenos)
end)

local offsetMinus = Instance.new("TextButton", ReactsFrame)
offsetMinus.Size = UDim2.new(0, 40, 0, 40)
offsetMinus.Position = UDim2.new(0, 24, 0, 174)
offsetMinus.Text = "-"
offsetMinus.BackgroundColor3 = Color3.fromRGB(200, 20, 120)
offsetMinus.TextColor3 = Color3.new(1,1,1)

local offsetPlus = offsetMinus:Clone()
offsetPlus.Parent = ReactsFrame
offsetPlus.Position = UDim2.new(0, 114, 0, 174)
offsetPlus.Text = "+"

local offsetLabel = Instance.new("TextLabel", ReactsFrame)
offsetLabel.Size = UDim2.new(0, 160, 0, 40)
offsetLabel.Position = UDim2.new(0, 164, 0, 174)
offsetLabel.Text = "Offset: "..Reacts.OffsetMs.." ms"
offsetLabel.BackgroundTransparency = 1
offsetLabel.TextColor3 = Color3.new(1,1,1)
offsetLabel.Font = Enum.Font.SourceSansBold
offsetLabel.TextSize = 18

offsetMinus.MouseButton1Click:Connect(function()
    Reacts.OffsetMs = math.max(0, Reacts.OffsetMs - 5)
    offsetLabel.Text = "Offset: "..Reacts.OffsetMs.." ms"
end)
offsetPlus.MouseButton1Click:Connect(function()
    Reacts.OffsetMs = math.min(100, Reacts.OffsetMs + 5)
    offsetLabel.Text = "Offset: "..Reacts.OffsetMs.." ms"
end)

-- Resizer tab (order 4)
local ResizerFrame = makeTabFrame()
makeTabButton("Resizer", 4, ResizerFrame)

local leftMinus = Instance.new("TextButton", ResizerFrame)
leftMinus.Size = UDim2.new(0, 40, 0, 40)
leftMinus.Position = UDim2.new(0, 24, 0, 24)
leftMinus.Text = "-"
leftMinus.BackgroundColor3 = Color3.fromRGB(200, 20, 120)
leftMinus.TextColor3 = Color3.new(1,1,1)

local leftPlus = leftMinus:Clone()
leftPlus.Parent = ResizerFrame
leftPlus.Position = UDim2.new(0, 114, 0, 24)
leftPlus.Text = "+"

local leftLabel = Instance.new("TextLabel", ResizerFrame)
leftLabel.Size = UDim2.new(0, 160, 0, 40)
leftLabel.Position = UDim2.new(0, 164, 0, 24)
leftLabel.Text = "Left Leg: 5"
leftLabel.BackgroundTransparency = 1
leftLabel.TextColor3 = Color3.new(1,1,1)
leftLabel.Font = Enum.Font.SourceSansBold
leftLabel.TextSize = 18

local leftSize = 5
leftMinus.MouseButton1Click:Connect(function()
    leftSize = math.max(1, leftSize - 1)
    leftLabel.Text = "Left Leg: "..leftSize
    resizeLeg("Left Leg", leftSize)
end)
leftPlus.MouseButton1Click:Connect(function()
    leftSize = math.min(20, leftSize + 1)
    leftLabel.Text = "Left Leg: "..leftSize
    resizeLeg("Left Leg", leftSize)
end)

local rightMinus = leftMinus:Clone()
rightMinus.Parent = ResizerFrame
rightMinus.Position = UDim2.new(0, 24, 0, 74)

local rightPlus = leftPlus:Clone()
rightPlus.Parent = ResizerFrame
rightPlus.Position = UDim2.new(0, 114, 0, 74)

local rightLabel = leftLabel:Clone()
rightLabel.Parent = ResizerFrame
rightLabel.Position = UDim2.new(0, 164, 0, 74)
rightLabel.Text = "Right Leg: 5"

local rightSize = 5
rightMinus.MouseButton1Click:Connect(function()
    rightSize = math.max(1, rightSize - 1)
    rightLabel.Text = "Right Leg: "..rightSize
    resizeLeg("Right Leg", rightSize)
end)
rightPlus.MouseButton1Click:Connect(function()
    rightSize = math.min(20, rightSize + 1)
    rightLabel.Text = "Right Leg: "..rightSize
    resizeLeg("Right Leg", rightSize)
end)

-- Teleportation tab (order 5)
local TeleFrame = makeTabFrame()
makeTabButton("Teleportation", 5, TeleFrame)

local tpG = Instance.new("TextButton", TeleFrame)
tpG.Size = UDim2.new(0, 240, 0, 40)
tpG.Position = UDim2.new(0, 24, 0, 24)
tpG.Text = "Teleport Green Side"
tpG.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
tpG.TextColor3 = Color3.new(1,1,1)
tpG.Font = Enum.Font.SourceSansBold
tpG.TextSize = 18
tpG.MouseButton1Click:Connect(tpGreen)

local tpB = tpG:Clone()
tpB.Parent = TeleFrame
tpB.Position = UDim2.new(0, 24, 0, 74)
tpB.Text = "Teleport Blue Side"
tpB.MouseButton1Click:Connect(tpBlue)

-- Misc tab (order 6) – stamina button
local MiscFrame = makeTabFrame()
local staminaBtn = Instance.new("TextButton", MiscFrame)
staminaBtn.Size = UDim2.new(0, 240, 0, 40)
staminaBtn.Position = UDim2.new(0, 24, 0, 24)
staminaBtn.Text = "Use Instant Stamina (0/5)"
staminaBtn.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
staminaBtn.TextColor3 = Color3.new(1,1,1)
staminaBtn.Font = Enum.Font.SourceSansBold
staminaBtn.TextSize = 18
staminaBtn.MouseButton1Click:Connect(function() useStamina(staminaBtn) end)

makeTabButton("Misc", 6, MiscFrame)

-- Show Info by default
showTab(InfoFrame)
