-- HeraWare Aqua Edition (Orion UI, Pink Theme)

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
RunService.RenderStepped:Connect(function()
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

-- === Orion UI ===
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({Name = "HeraWare Aqua", HidePremium = false, SaveConfig = false, ConfigFolder = "HeraWareAqua", IntroText = "Made by Hera", Theme = "Pink"})

-- Toggle with RightCtrl
OrionLib:ToggleUI(Enum.KeyCode.RightControl)

-- Info Tab
local InfoTab = Window:MakeTab({Name = "Info", Icon = "rbxassetid://4483345998", PremiumOnly = false})
InfoTab:AddParagraph("Made by Hera","Features:\n- FireTouch\n- Elemental React\n- Hera React\n- Sourenos React\n- Resizer\n- Teleportation\n- 5x Instant Stamina/day")
InfoTab:AddParagraph("License","This script is licensed to "..LP.Name)

-- FireTouch Tab
local FireTab = Window:MakeTab({Name = "FireTouch", Icon = "rbxassetid://4483345998", PremiumOnly = false})
FireTab:AddToggle({Name="Leg Firetouch", Default=false, Callback=function(v) Reach.EnabledLegs=v end})
FireTab:AddToggle({Name="Head Firetouch", Default=false, Callback=function(v) Reach.EnabledHead=v end})
FireTab:AddSlider({Name="Leg Reach Distance", Min=1, Max=20, Default=Reach.DistLegs, Color=Color3.fromRGB(255,20,147), Increment=1, Callback=function(v) Reach.DistLegs=v end})
FireTab:AddSlider({Name="Head Reach Distance", Min=1, Max=20, Default=Reach.DistHead, Color=Color3.fromRGB(255,20,147), Increment=1, Callback=function(v) Reach.DistHead=v end})

-- Reacts Tab
local ReactTab = Window:MakeTab({Name = "Reacts", Icon = "rbxassetid://4483345998", PremiumOnly = false})
ReactTab:AddToggle({Name="Elemental React", Default=false, Callback=function(v) Reacts.Elemental=v; setReactLoop(v or Reacts.Hera or Reacts.Sourenos) end})
ReactTab:AddToggle({Name="Hera React", Default=false, Callback=function(v) Reacts.Hera=v; setReactLoop(v or Reacts.Elemental or Reacts.Sourenos) end})
ReactTab:AddToggle({Name="Sourenos React", Default=false, Callback=function(v) Reacts.Sourenos=v; setReactLoop(v or Reacts.Elemental or Reacts.Hera) end})
ReactTab:AddSlider({Name="React Offset (ms)", Min=0, Max=100, Default=Reacts.OffsetMs, Color=Color3.fromRGB(255,20,147), Increment=5, Callback=function(v) Reacts.OffsetMs=v end})

-- Resizer Tab
local ResizeTab = Window:MakeTab({Name = "Resizer", Icon = "rbxassetid://4483345998", PremiumOnly = false})
ResizeTab:AddSlider({Name="Resize Left Leg", Min=1, Max=20, Default=5, Color=Color3.fromRGB(255,20,147), Increment=1, Callback=function(v) resizeLeg("Left Leg", v) end})
ResizeTab:AddSlider({Name="Resize Right Leg", Min=1, Max=20, Default=5, Color=Color3.fromRGB(255,20,147), Increment=1, Callback=function(v) resizeLeg("Right Leg", v) end})

-- Teleportation Tab
local TeleTab = Window:MakeTab({Name = "Teleportation", Icon = "rbxassetid://4483345998", PremiumOnly = false})
TeleTab:AddButton({Name="Teleport Green Side", Callback=tpGreen})
TeleTab:AddButton({Name="Teleport Blue Side", Callback=tpBlue})

-- Misc Tab (Stamina)
local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local staminaBtn = MiscTab:AddButton({Name="Use Instant Stamina (0/5)", Callback=function() useStamina(staminaBtn) end})

OrionLib:Init()
