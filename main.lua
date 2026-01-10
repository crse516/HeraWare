-- HeraWare Aqua Edition (Custom Sidebar UI, visible in CoreGui)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

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

-- === UI ===
local ScreenGui=Instance.new("ScreenGui",CoreGui)
ScreenGui.Name="HeraWareUI"

local Sidebar=Instance.new("Frame",ScreenGui)
Sidebar.Size=UDim2.new(0,150,1,0)
Sidebar.BackgroundColor3=Color3.fromRGB(30,30,30)

local MainPanel=Instance.new("Frame",ScreenGui)
MainPanel.Position=UDim2.new(0,150,0,0)
MainPanel.Size=UDim2.new(1,-150,1,0)
MainPanel.BackgroundColor3=Color3.fromRGB(45,45,45)

local currentTab
local function showTab(tabFrame)
    if currentTab then currentTab.Visible=false end
    tabFrame.Visible=true; currentTab=tabFrame
end

local function makeTabButton(name,order,tabFrame)
    local btn=Instance.new("TextButton",Sidebar)
    btn.Size=UDim2.new(1,0,0,40)
    btn.Position=UDim2.new(0,0,0,(order-1)*40)
    btn.Text=name; btn.Font=Enum.Font.SourceSansBold; btn.TextSize=18
    btn.BackgroundColor3=Color3.fromRGB(50,50,50); btn.TextColor3=Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function() showTab(tabFrame) end)
end

-- FireTouch Tab
local FireTouchFrame=Instance.new("Frame",MainPanel)
FireTouchFrame.Size=UDim2.new(1,0,1,0); FireTouchFrame.Visible=false
makeTabButton("FireTouch",1,FireTouchFrame)

local legToggle=Instance.new("TextButton",FireTouchFrame)
legToggle.Size=UDim2.new(0,200,0,40); legToggle.Position=UDim2.new(0,20,0,20)
legToggle.Text="Leg Firetouch: OFF"; legToggle.BackgroundColor3=Color3.fromRGB(70,70,70); legToggle.TextColor3=Color3.new(1,1,1)
legToggle.MouseButton1Click:Connect(function() Reach.EnabledLegs=not Reach.EnabledLegs; legToggle.Text="Leg Firetouch: "..(Reach.EnabledLegs and "ON" or "OFF") end)

local headToggle=legToggle:Clone(); headToggle.Parent=FireTouchFrame; headToggle.Position=UDim2.new(0,20,0,70)
headToggle.Text="Head Firetouch: OFF"
headToggle.MouseButton1Click:Connect(function() Reach.EnabledHead=not Reach.EnabledHead; headToggle.Text="Head Firetouch: "..(Reach.EnabledHead and "ON" or "OFF") end)

-- Reacts Tab
local ReactsFrame=Instance.new("Frame",MainPanel)
ReactsFrame.Size=UDim2.new(1,0,1,0); ReactsFrame.Visible=false
makeTabButton("Reacts",2,ReactsFrame)

local elemToggle=Instance.new("TextButton",ReactsFrame)
elemToggle.Size=UDim2.new(0,200,0,40); elemToggle.Position=UDim2.new(0,20,0,20)
elemToggle.Text="Elemental React: OFF"; elemToggle.BackgroundColor3=Color3.fromRGB(70,70,70); elemToggle.TextColor3=Color3.new(1,1,1)
elemToggle.MouseButton1Click:Connect(function() Reacts.Elemental=not Reacts.Elemental; elemToggle.Text="Elemental React: "..(Reacts.Elemental and "ON" or "OFF"); setReactLoop(Reacts.Elemental or Reacts.Hera) end)

local heraToggle=elemToggle:Clone(); heraToggle.Parent=ReactsFrame; heraToggle.Position=UDim2.new(0,20,0,70)
heraToggle.Text="Hera React: OFF"
heraToggle.MouseButton1Click:Connect(function() Reacts.Hera=not Reacts.Hera; heraToggle.Text="Hera React: "..(Reacts.Hera and "ON" or "OFF"); setReactLoop(Reacts.Elemental or Reacts.Hera) end)

-- Resizer Tab
local ResizerFrame=Instance.new("Frame",MainPanel)
ResizerFrame.Size=UDim2.new(1,0,1,0); ResizerFrame.Visible=false
makeTabButton("Resizer",3,ResizerFrame)

local leftBtn=Instance.new("TextButton",ResizerFrame)
leftBtn.Size=UDim2.new(0,200,0,40); leftBtn.Position=UDim2.new(0,20,0,20)
leftBtn.Text="Resize Left Leg"; leftBtn.BackgroundColor3=Color3.fromRGB(70,70,70); left
