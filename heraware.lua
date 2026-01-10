-- HeraWare Aqua Edition (Rayfield UI, Pink Theme)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Ball finder
local function findServerBall()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and d.Name:lower():find("ball") then return d end
    end
    return nil
end

-- Reach
local Reach = {EnabledLegs=false, EnabledHead=false, DistLegs=3, DistHead=5}
local reachConn
local function startReach()
    if reachConn then reachConn:Disconnect() end
    reachConn = RunService.RenderStepped:Connect(function()
        local ball = findServerBall()
        if not ball then return end
        if Reach.EnabledLegs then
            local rl = Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightLowerLeg")
            local ll = Character:FindFirstChild("Left Leg") or Character:FindFirstChild("LeftLowerLeg")
            if rl and (ball.Position-rl.Position).Magnitude <= Reach.DistLegs then firetouchinterest(rl,ball,0) firetouchinterest(rl,ball,1) end
            if ll and (ball.Position-ll.Position).Magnitude <= Reach.DistLegs then firetouchinterest(ll,ball,0) firetouchinterest(ll,ball,1) end
        end
        if Reach.EnabledHead then
            local head = Character:FindFirstChild("Head")
            if head and (ball.Position-head.Position).Magnitude <= Reach.DistHead then firetouchinterest(head,ball,0) firetouchinterest(head,ball,1) end
        end
    end)
end

-- Reacts
local Reacts = {Elemental=false,Hera=false,Sourenos=false,OffsetMs=20,Connection=nil}
local function reactStep()
    local ball = findServerBall()
    if not (HRP and ball) then return end
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local early = (ping/2+Reacts.OffsetMs)/1000
    local predicted = ball.Position + ball.AssemblyLinearVelocity*early
    local dist = (predicted-HRP.Position).Magnitude
    if Reacts.Elemental and dist<=4.2 then print("Elemental React") end
    if Reacts.Hera and dist<=5.0 then print("Hera React") end
    if Reacts.Sourenos and dist<=7.0 then print("Sourenos React") end
end
local function setReactLoop(state)
    if state and not Reacts.Connection then
        Reacts.Connection = RunService.Heartbeat:Connect(reactStep)
    elseif not state and Reacts.Connection then
        Reacts.Connection:Disconnect(); Reacts.Connection=nil
    end
end

-- Teleports
local function tpGreen() HRP.CFrame=CFrame.new(0,175,179) end
local function tpBlue() HRP.CFrame=CFrame.new(0.4269,175.29,377.40) end

-- Resizer
local function resizeLeg(legName,scale)
    local leg=Character:FindFirstChild(legName)
    if leg and leg:IsA("BasePart") then leg.Size=Vector3.new(leg.Size.X,scale,leg.Size.Z) end
end

-- Stamina
local staminaUses, staminaLimit = 0, 5
local staminaDay = os.date("%x")
local function useStamina(btn)
    local today = os.date("%x")
    if today ~= staminaDay then staminaDay=today; staminaUses=0 end
    if staminaUses < staminaLimit then
        staminaUses+=1
        btn:Set("Name","Use Instant Stamina ("..staminaUses.."/"..staminaLimit..")")
        print("Instant stamina granted! ("..staminaUses.."/"..staminaLimit..")")
    else
        btn:Set("Name","Daily Stamina Limit Reached")
    end
end

-- === Rayfield UI ===
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

local Window = Rayfield:CreateWindow({
   Name = "HeraWare Aqua",
   LoadingTitle = "Made by Hera",
   LoadingSubtitle = "Licensed to "..LP.Name,
   Theme = "Pink",
   KeySystem = false
})

-- Toggle with RightCtrl
Rayfield:ToggleUI(Enum.KeyCode.RightControl)

-- Info Tab
local InfoTab = Window:CreateTab("Info", 4483345998)
InfoTab:CreateSection("Made by Hera")
InfoTab:CreateParagraph({Title="Features", Content="- FireTouch\n- Elemental React\n- Hera React\n- Sourenos React\n- Resizer\n- Teleportation\n- 5x Instant Stamina/day"})
InfoTab:CreateParagraph({Title="License", Content="This script is licensed to "..LP.Name})
InfoTab:CreateParagraph({Title="Hint", Content="Press RightCtrl to toggle UI"})

-- FireTouch Tab
local FireTab = Window:CreateTab("FireTouch", 4483345998)
FireTab:CreateToggle({Name="Leg Firetouch", CurrentValue=false, Callback=function(v) Reach.EnabledLegs=v; startReach() end})
FireTab:CreateToggle({Name="Head Firetouch", CurrentValue=false, Callback=function(v) Reach.EnabledHead=v; startReach() end})
FireTab:CreateSlider({Name="Leg Reach Distance", Range={1,20}, Increment=1, CurrentValue=Reach.DistLegs, Callback=function(v) Reach.DistLegs=v end})
FireTab:CreateSlider({Name="Head Reach Distance", Range={1,20}, Increment=1, CurrentValue=Reach.DistHead, Callback=function(v) Reach.DistHead=v end})

-- Reacts Tab
local ReactTab = Window:CreateTab("Reacts", 4483345998)
ReactTab:CreateToggle({Name="Elemental React", CurrentValue=false, Callback=function(v) Reacts.Elemental=v; setReactLoop(v or Reacts.Hera or Reacts.Sourenos) end})
ReactTab:CreateToggle({Name="Hera React", CurrentValue=false, Callback=function(v) Reacts.Hera=v; setReactLoop(v or Reacts.Elemental or Reacts.Sourenos) end})
ReactTab:CreateToggle({Name="Sourenos React", CurrentValue=false, Callback=function(v) Reacts.Sourenos=v; setReactLoop(v or Reacts.Elemental or Reacts.Hera) end})
ReactTab:CreateSlider({Name="React Offset (ms)", Range={0,100}, Increment=5, CurrentValue=Reacts.OffsetMs, Callback=function(v) Reacts.OffsetMs=v end})

-- Resizer Tab
local ResizeTab = Window:CreateTab("Resizer", 4483345998)
ResizeTab:CreateSlider({Name="Resize Left Leg", Range={1,20}, Increment=1, CurrentValue=5, Callback=function(v) resizeLeg("Left Leg", v) end})
ResizeTab:CreateSlider({Name="Resize Right Leg", Range={1,20}, Increment=1, CurrentValue=5, Callback=function(v) resizeLeg("Right Leg", v) end})

-- Teleportation Tab
local TeleTab = Window:CreateTab("Teleportation", 4483345998)
TeleTab:CreateButton({Name="Teleport Green Side", Callback=tpGreen})
TeleTab:CreateButton({Name="Teleport Blue Side", Callback=tpBlue})

-- Misc Tab (Stamina)
local MiscTab = Window:CreateTab("Misc", 4483345998)
local staminaBtn = MiscTab:CreateButton({Name="Use Instant Stamina (0/5)", Callback=function() useStamina(staminaBtn) end})

Rayfield:Init()
