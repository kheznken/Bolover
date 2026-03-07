-- [[ BOLOVERSAL HUB BY @khezn21 tiktok ]] --
-- [[ ULTRA PRO V16.6 - MOBILE EDITION ]] --

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local roomFolder = nil
local preCloudPos = nil
local autoHideReturnPos = nil
local customSpeed = 16
local customJump = 50
local hitboxSize = 15
local tpTool = nil
local glideTool = nil
local savedLocation = nil
local playerPositions = {}
local xrayParts = {}
local targetPlayerName = ""
local fpsStoredMaterials = {}
local persistentTarget = nil
local targetOrigPos = nil
local spinAngle = 0

local origLight = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient
}

local toggles = {
	speed=false, jumpHigh=false, frozeAll=false, bringAll=false, bringNearby=false,
	hide=false, esp=false, hitbox=false, noclip=false, xray=false, infjump=false,
	autoHide=false, freezeAura=false, antiAfk=false, tptool=false, glidetool=false,
	fullbright=false, spinbot=false, instantInteract=false, bang=false,
	bringTarget=false, freezeTarget=false, antifling=false, antisit=false,
	antistun=false, untouchable=false, fpsBoost=false, spectate=false, instantRespawn=false
}

local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChild("Humanoid") end
local function GetPlayer(s)
	if not s or s=="" then return nil end
	s=s:lower()
	for _,v in pairs(Players:GetPlayers()) do
		if v.Name:lower():sub(1,#s)==s or v.DisplayName:lower():sub(1,#s)==s then return v end
	end
end

local function spawnRoom()
	if roomFolder then return roomFolder:GetAttribute("CenterCF") end
	roomFolder = Instance.new("Folder", workspace); roomFolder.Name = "Boloversal_Room"
	local cf = CFrame.new(math.random(-90000,90000), 40000, math.random(-90000,90000))
	roomFolder:SetAttribute("CenterCF", cf)
	local function qp(sz,pos,col,mat)
		local p=Instance.new("Part",roomFolder); p.Size=sz; p.CFrame=cf*pos
		p.Anchored=true; p.Color=col; p.Material=mat or Enum.Material.Plastic; return p
	end
	qp(Vector3.new(80,1,80),CFrame.new(0,0,0),Color3.fromRGB(255,255,255),Enum.Material.SmoothPlastic)
	qp(Vector3.new(80,25,1),CFrame.new(0,12.5,-40),Color3.fromRGB(240,240,240))
	local g=qp(Vector3.new(0.5,13,40),CFrame.new(40,12.5,0),Color3.fromRGB(180,225,255),Enum.Material.Glass); g.Transparency=0.4
	return cf
end

local function ServerHop(sort)
	local ok,res=pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder="..sort.."&limit=100")) end)
	if not ok then return end
	for _,v in pairs(res.data) do
		if v.playing<v.maxPlayers and v.id~=game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId,v.id); break end
	end
end

local function createGlideTool()
	local tool=Instance.new("Tool"); tool.Name="Glide Tool"; tool.RequiresHandle=true
	local handle=Instance.new("Part",tool); handle.Name="Handle"; handle.Size=Vector3.new(2,2,1); handle.CanCollide=false
	local mesh=Instance.new("SpecialMesh",handle); mesh.MeshId="rbxassetid://68203112"; mesh.TextureId="rbxassetid://68203091"; mesh.Scale=Vector3.new(1.5,1.5,1.5)
	local a0=Instance.new("Attachment",handle); a0.Position=Vector3.new(0,0.5,0)
	local a1=Instance.new("Attachment",handle); a1.Position=Vector3.new(0,-0.5,0)
	local tr=Instance.new("Trail",handle); tr.Attachment0=a0; tr.Attachment1=a1
	tr.Color=ColorSequence.new(Color3.new(0,1,1)); tr.Enabled=false
	local gliding=false
	tool.Activated:Connect(function()
		if gliding then return end
		local hrp=getHRP(player.Character); if not hrp then return end
		gliding=true; tr.Enabled=true
		local target=mouse.Hit.Position
		local nc=RunService.Stepped:Connect(function() if player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end end)
		local bv=Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(1e6,1e6,1e6); bv.Velocity=(target-hrp.Position).Unit*120
		local bg=Instance.new("BodyGyro",hrp); bg.MaxTorque=Vector3.new(1e6,1e6,1e6); bg.CFrame=CFrame.new(hrp.Position,target)
		task.wait((target-hrp.Position).Magnitude/120)
		nc:Disconnect(); bv:Destroy(); bg:Destroy(); tr.Enabled=false; gliding=false
		if player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=true end end end
	end)
	return tool
end

------------------------------------------------
-- UI LIBRARY
------------------------------------------------
local function tw(obj, props, t) TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() end
local function corner(p, r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6); return c end
local function stroke(p, col, th) local s=Instance.new("UIStroke",p); s.Color=col or Color3.fromRGB(60,60,60); s.Thickness=th or 1; return s end

local C = {
	BG       = Color3.fromRGB(18, 18, 18),
	Panel    = Color3.fromRGB(24, 24, 24),
	Sidebar  = Color3.fromRGB(20, 20, 20),
	Tab      = Color3.fromRGB(26, 26, 26),
	TabHov   = Color3.fromRGB(32, 32, 32),
	TabSel   = Color3.fromRGB(30, 30, 30),
	Elem     = Color3.fromRGB(28, 28, 28),
	ElemHov  = Color3.fromRGB(34, 34, 34),
	Border   = Color3.fromRGB(45, 45, 45),
	Accent   = Color3.fromRGB(180, 180, 180),
	AccentLo = Color3.fromRGB(110, 110, 110),
	ON       = Color3.fromRGB(200, 200, 200),
	OFF      = Color3.fromRGB(55, 55, 55),
	Text     = Color3.fromRGB(220, 220, 220),
	Sub      = Color3.fromRGB(120, 120, 120),
	TopBar   = Color3.fromRGB(16, 16, 16),
	Knob     = Color3.fromRGB(240, 240, 240),
	SliderBG = Color3.fromRGB(38, 38, 38),
}

local SG = Instance.new("ScreenGui")
SG.Name = "BoloverHub"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true; SG.DisplayOrder = 999
SG.Parent = player.PlayerGui

-- Loading screen
local LF = Instance.new("Frame", SG)
LF.Size = UDim2.new(1,0,1,0); LF.BackgroundColor3 = Color3.fromRGB(10,10,10); LF.BorderSizePixel=0; LF.ZIndex=200

local LInner = Instance.new("Frame", LF)
LInner.Size = UDim2.new(0,300,0,130); LInner.AnchorPoint=Vector2.new(0.5,0.5)
LInner.Position = UDim2.new(0.5,0,0.5,0); LInner.BackgroundColor3=C.Panel; LInner.BorderSizePixel=0; LInner.ZIndex=201
corner(LInner, 10); stroke(LInner, C.Border, 1)

local LTitle = Instance.new("TextLabel", LInner)
LTitle.Size=UDim2.new(1,0,0,36); LTitle.Position=UDim2.new(0,0,0,14)
LTitle.BackgroundTransparency=1; LTitle.Text="ULTRA PRO V16.6"
LTitle.TextColor3=C.Text; LTitle.TextScaled=true; LTitle.Font=Enum.Font.GothamBold; LTitle.ZIndex=202

local LSub = Instance.new("TextLabel", LInner)
LSub.Size=UDim2.new(1,0,0,20); LSub.Position=UDim2.new(0,0,0,48)
LSub.BackgroundTransparency=1; LSub.Text="by khen.khen457"
LSub.TextColor3=C.Sub; LSub.TextScaled=true; LSub.Font=Enum.Font.Gotham; LSub.ZIndex=202

local LBarBG = Instance.new("Frame", LInner)
LBarBG.Size=UDim2.new(0.82,0,0,4); LBarBG.Position=UDim2.new(0.09,0,0,82)
LBarBG.BackgroundColor3=C.SliderBG; LBarBG.BorderSizePixel=0; LBarBG.ZIndex=202; corner(LBarBG,3)

local LBar = Instance.new("Frame", LBarBG)
LBar.Size=UDim2.new(0,0,1,0); LBar.BackgroundColor3=C.Accent; LBar.BorderSizePixel=0; LBar.ZIndex=203; corner(LBar,3)

local LStatus = Instance.new("TextLabel", LInner)
LStatus.Size=UDim2.new(1,0,0,16); LStatus.Position=UDim2.new(0,0,0,96)
LStatus.BackgroundTransparency=1; LStatus.Text="Loading..."
LStatus.TextColor3=C.Sub; LStatus.TextScaled=true; LStatus.Font=Enum.Font.Gotham; LStatus.ZIndex=202

task.spawn(function()
	local steps={"Initializing...","Loading modules...","Building UI...","Done."}
	for i,s in ipairs(steps) do
		LStatus.Text=s; tw(LBar,{Size=UDim2.new(i/#steps,0,1,0)},0.3); task.wait(0.25)
	end
	task.wait(0.15)
	tw(LF,{BackgroundTransparency=1},0.4)
	tw(LInner,{BackgroundTransparency=1},0.4)
	for _,v in ipairs(LInner:GetDescendants()) do
		if v:IsA("TextLabel") then tw(v,{TextTransparency=1},0.3) end
		if v:IsA("Frame") then tw(v,{BackgroundTransparency=1},0.3) end
	end
	task.wait(0.45); LF:Destroy()
end)

-- Main window: 540 wide x 380 tall
local Main = Instance.new("Frame", SG)
Main.Name="MainFrame"
Main.Size=UDim2.new(0,540,0,380)
Main.Position=UDim2.new(0.5,-270,0.5,-190)
Main.BackgroundColor3=C.BG
Main.BorderSizePixel=0
Main.ClipsDescendants=true
corner(Main, 8)
stroke(Main, C.Border, 1)

-- Topbar: full width, 36px tall
local Top = Instance.new("Frame", Main)
Top.Size=UDim2.new(1,0,0,36); Top.Position=UDim2.new(0,0,0,0)
Top.BackgroundColor3=C.TopBar; Top.BorderSizePixel=0; Top.ZIndex=5

-- top bar only rounds top corners
local TopCornerFix = Instance.new("Frame", Top)
TopCornerFix.Size=UDim2.new(1,0,0.5,0); TopCornerFix.Position=UDim2.new(0,0,0.5,0)
TopCornerFix.BackgroundColor3=C.TopBar; TopCornerFix.BorderSizePixel=0; TopCornerFix.ZIndex=4

local TopLine = Instance.new("Frame", Main)
TopLine.Size=UDim2.new(1,0,0,1); TopLine.Position=UDim2.new(0,0,0,36)
TopLine.BackgroundColor3=C.Border; TopLine.BorderSizePixel=0; TopLine.ZIndex=5

local TitleLbl = Instance.new("TextLabel", Top)
TitleLbl.Size=UDim2.new(1,-80,1,0); TitleLbl.Position=UDim2.new(0,12,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="BOLOVERSAL Hub  ·  @khezn21"
TitleLbl.TextColor3=C.Text; TitleLbl.TextSize=13; TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left; TitleLbl.ZIndex=6

local MinBtn = Instance.new("TextButton", Top)
MinBtn.Size=UDim2.new(0,26,0,20); MinBtn.Position=UDim2.new(1,-58,0.5,-10)
MinBtn.BackgroundColor3=C.Tab; MinBtn.BorderSizePixel=0; MinBtn.Text="—"
MinBtn.TextColor3=C.Sub; MinBtn.TextSize=11; MinBtn.Font=Enum.Font.GothamBold; MinBtn.ZIndex=7
corner(MinBtn,4)

local ClsBtn = Instance.new("TextButton", Top)
ClsBtn.Size=UDim2.new(0,26,0,20); ClsBtn.Position=UDim2.new(1,-28,0.5,-10)
ClsBtn.BackgroundColor3=Color3.fromRGB(160,45,45); ClsBtn.BorderSizePixel=0; ClsBtn.Text="✕"
ClsBtn.TextColor3=Color3.fromRGB(255,255,255); ClsBtn.TextSize=11; ClsBtn.Font=Enum.Font.GothamBold; ClsBtn.ZIndex=7
corner(ClsBtn,4)

-- Sidebar: left side, below topbar, 120px wide
local Side = Instance.new("Frame", Main)
Side.Size=UDim2.new(0,120,1,-37); Side.Position=UDim2.new(0,0,0,37)
Side.BackgroundColor3=C.Sidebar; Side.BorderSizePixel=0; Side.ZIndex=4
-- fix right border
local SideRight = Instance.new("Frame", Side)
SideRight.Size=UDim2.new(0,1,1,0); SideRight.Position=UDim2.new(1,-1,0,0)
SideRight.BackgroundColor3=C.Border; SideRight.BorderSizePixel=0; SideRight.ZIndex=5

local SideList = Instance.new("UIListLayout", Side)
SideList.SortOrder=Enum.SortOrder.LayoutOrder; SideList.Padding=UDim.new(0,1)

local SidePad = Instance.new("UIPadding", Side)
SidePad.PaddingTop=UDim.new(0,6); SidePad.PaddingLeft=UDim.new(0,6); SidePad.PaddingRight=UDim.new(0,7)

-- Content: right side, below topbar
local ContentHolder = Instance.new("Frame", Main)
ContentHolder.Size=UDim2.new(1,-121,1,-37); ContentHolder.Position=UDim2.new(0,121,0,37)
ContentHolder.BackgroundColor3=C.BG; ContentHolder.BorderSizePixel=0; ContentHolder.ZIndex=3
ContentHolder.ClipsDescendants=true

-- Floating toggle button for mobile (shows when minimized)
local FloatBtn = Instance.new("TextButton", SG)
FloatBtn.Size=UDim2.new(0,40,0,40); FloatBtn.Position=UDim2.new(0,10,0.5,0)
FloatBtn.BackgroundColor3=C.Panel; FloatBtn.BorderSizePixel=0
FloatBtn.Text="≡"; FloatBtn.TextColor3=C.Text; FloatBtn.TextSize=18
FloatBtn.Font=Enum.Font.GothamBold; FloatBtn.ZIndex=100; FloatBtn.Visible=false
corner(FloatBtn,6); stroke(FloatBtn,C.Border,1)

-- Drag
local dragging,dragStart,startPos=false,nil,nil
Top.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
		dragging=true; dragStart=inp.Position; startPos=Main.Position
	end
end)
Top.InputEnded:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
UserInputService.InputChanged:Connect(function(inp)
	if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
		local d=inp.Position-dragStart
		Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)

local minimized=false
MinBtn.MouseButton1Click:Connect(function()
	minimized=not minimized
	if minimized then tw(Main,{Size=UDim2.new(0,540,0,36)},0.2); FloatBtn.Visible=true
	else tw(Main,{Size=UDim2.new(0,540,0,380)},0.2); FloatBtn.Visible=false end
end)
ClsBtn.MouseButton1Click:Connect(function()
	tw(Main,{Size=UDim2.new(0,540,0,0)},0.25); task.wait(0.3); SG:Destroy()
end)
FloatBtn.MouseButton1Click:Connect(function()
	minimized=false; tw(Main,{Size=UDim2.new(0,540,0,380)},0.2); FloatBtn.Visible=false
end)

-- Tab system
local Tabs={}; local ActiveTab=nil

local function SelectTab(tab)
	if ActiveTab==tab then return end
	if ActiveTab then
		tw(ActiveTab.Btn,{BackgroundColor3=C.Tab},0.15)
		tw(ActiveTab.BtnLabel,{TextColor3=C.Sub},0.15)
		ActiveTab.ActiveIndicator.Visible=false
		ActiveTab.Scroll.Visible=false
	end
	ActiveTab=tab
	tw(tab.Btn,{BackgroundColor3=C.TabSel},0.15)
	tw(tab.BtnLabel,{TextColor3=C.Text},0.15)
	tab.ActiveIndicator.Visible=true
	tab.Scroll.Visible=true
end

local function CreateTab(name)
	local tab={}; local order=#Tabs+1

	local Btn=Instance.new("TextButton", Side)
	Btn.Size=UDim2.new(1,0,0,32); Btn.BackgroundColor3=C.Tab
	Btn.BorderSizePixel=0; Btn.Text=""; Btn.ZIndex=5; Btn.LayoutOrder=order
	corner(Btn,5)

	local BtnLabel=Instance.new("TextLabel", Btn)
	BtnLabel.Size=UDim2.new(1,-14,1,0); BtnLabel.Position=UDim2.new(0,10,0,0)
	BtnLabel.BackgroundTransparency=1; BtnLabel.Text=name
	BtnLabel.TextColor3=C.Sub; BtnLabel.TextSize=12; BtnLabel.Font=Enum.Font.Gotham
	BtnLabel.TextXAlignment=Enum.TextXAlignment.Left; BtnLabel.ZIndex=6

	local ActiveIndicator=Instance.new("Frame", Btn)
	ActiveIndicator.Size=UDim2.new(0,2,0.55,0); ActiveIndicator.Position=UDim2.new(0,-5,0.225,0)
	ActiveIndicator.BackgroundColor3=C.Accent; ActiveIndicator.BorderSizePixel=0
	ActiveIndicator.Visible=false; ActiveIndicator.ZIndex=7; corner(ActiveIndicator,2)

	local Scroll=Instance.new("ScrollingFrame", ContentHolder)
	Scroll.Size=UDim2.new(1,0,1,0); Scroll.BackgroundTransparency=1
	Scroll.BorderSizePixel=0; Scroll.ScrollBarThickness=2
	Scroll.ScrollBarImageColor3=C.AccentLo; Scroll.CanvasSize=UDim2.new(0,0,0,0)
	Scroll.Visible=false; Scroll.ZIndex=4; Scroll.ClipsDescendants=true

	local List=Instance.new("UIListLayout", Scroll)
	List.SortOrder=Enum.SortOrder.LayoutOrder; List.Padding=UDim.new(0,4)
	local Pad=Instance.new("UIPadding", Scroll)
	Pad.PaddingTop=UDim.new(0,8); Pad.PaddingLeft=UDim.new(0,8); Pad.PaddingRight=UDim.new(0,8)

	List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Scroll.CanvasSize=UDim2.new(0,0,0,List.AbsoluteContentSize.Y+16)
	end)

	Btn.MouseButton1Click:Connect(function() SelectTab(tab) end)
	Btn.MouseEnter:Connect(function() if ActiveTab~=tab then tw(Btn,{BackgroundColor3=C.TabHov},0.12) end end)
	Btn.MouseLeave:Connect(function() if ActiveTab~=tab then tw(Btn,{BackgroundColor3=C.Tab},0.12) end end)

	tab.Btn=Btn; tab.BtnLabel=BtnLabel; tab.ActiveIndicator=ActiveIndicator
	tab.Scroll=Scroll; tab.List=List; tab.order=0

	local function nextOrd() tab.order=tab.order+1; return tab.order end

	function tab:CreateSection(name)
		local F=Instance.new("Frame",Scroll)
		F.Size=UDim2.new(1,0,0,24); F.BackgroundTransparency=1; F.BorderSizePixel=0; F.LayoutOrder=nextOrd()
		local Line=Instance.new("Frame",F)
		Line.Size=UDim2.new(1,0,0,1); Line.Position=UDim2.new(0,0,0.5,0)
		Line.BackgroundColor3=C.Border; Line.BorderSizePixel=0; Line.ZIndex=5
		local Lbl=Instance.new("TextLabel",F)
		Lbl.Size=UDim2.new(0,0,1,0); Lbl.AutomaticSize=Enum.AutomaticSize.X
		Lbl.Position=UDim2.new(0,8,0,0); Lbl.BackgroundColor3=C.BG; Lbl.BorderSizePixel=0
		Lbl.Text=" "..name.." "; Lbl.TextColor3=C.Sub; Lbl.TextSize=11
		Lbl.Font=Enum.Font.GothamBold; Lbl.ZIndex=6
	end

	function tab:CreateToggle(cfg)
		local val=cfg.CurrentValue or false
		local F=Instance.new("Frame",Scroll)
		F.Size=UDim2.new(1,0,0,38); F.BackgroundColor3=C.Elem; F.BorderSizePixel=0; F.LayoutOrder=nextOrd(); F.ZIndex=5
		corner(F,6); stroke(F,C.Border,1)

		local NL=Instance.new("TextLabel",F)
		NL.Size=UDim2.new(1,-60,0.55,0); NL.Position=UDim2.new(0,10,0.08,0)
		NL.BackgroundTransparency=1; NL.Text=cfg.Name or "Toggle"
		NL.TextColor3=C.Text; NL.TextSize=12; NL.Font=Enum.Font.Gotham
		NL.TextXAlignment=Enum.TextXAlignment.Left; NL.ZIndex=6

		local SL=Instance.new("TextLabel",F)
		SL.Size=UDim2.new(1,-60,0.38,0); SL.Position=UDim2.new(0,10,0.58,0)
		SL.BackgroundTransparency=1; SL.Text=val and "Enabled" or "Disabled"
		SL.TextColor3=val and C.Accent or C.Sub; SL.TextSize=10; SL.Font=Enum.Font.Gotham
		SL.TextXAlignment=Enum.TextXAlignment.Left; SL.ZIndex=6

		local Pill=Instance.new("Frame",F)
		Pill.Size=UDim2.new(0,36,0,18); Pill.Position=UDim2.new(1,-46,0.5,-9)
		Pill.BackgroundColor3=val and C.ON or C.OFF; Pill.BorderSizePixel=0; Pill.ZIndex=6
		corner(Pill,10)

		local Knob=Instance.new("Frame",Pill)
		Knob.Size=UDim2.new(0,13,0,13); Knob.Position=val and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5)
		Knob.BackgroundColor3=Color3.fromRGB(230,230,230); Knob.BorderSizePixel=0; Knob.ZIndex=7
		corner(Knob,8)

		local Clk=Instance.new("TextButton",F)
		Clk.Size=UDim2.new(1,0,1,0); Clk.BackgroundTransparency=1; Clk.Text=""; Clk.ZIndex=8

		Clk.MouseButton1Click:Connect(function()
			val=not val
			tw(Pill,{BackgroundColor3=val and C.ON or C.OFF},0.15)
			tw(Knob,{Position=val and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5)},0.15)
			SL.Text=val and "Enabled" or "Disabled"
			tw(SL,{TextColor3=val and C.Accent or C.Sub},0.12)
			if cfg.Callback then cfg.Callback(val) end
		end)
		Clk.MouseEnter:Connect(function() tw(F,{BackgroundColor3=C.ElemHov},0.12) end)
		Clk.MouseLeave:Connect(function() tw(F,{BackgroundColor3=C.Elem},0.12) end)
	end

	function tab:CreateButton(cfg)
		local F=Instance.new("Frame",Scroll)
		F.Size=UDim2.new(1,0,0,36); F.BackgroundColor3=C.Elem; F.BorderSizePixel=0; F.LayoutOrder=nextOrd(); F.ZIndex=5
		corner(F,6); stroke(F,C.Border,1)

		local B=Instance.new("TextButton",F)
		B.Size=UDim2.new(1,-16,0,22); B.Position=UDim2.new(0,8,0.5,-11)
		B.BackgroundColor3=C.TabHov; B.BorderSizePixel=0
		B.Text=cfg.Name or "Button"; B.TextColor3=C.Text; B.TextSize=12
		B.Font=Enum.Font.GothamBold; B.ZIndex=6
		corner(B,5); stroke(B,C.Border,1)

		B.MouseButton1Click:Connect(function()
			tw(B,{BackgroundColor3=C.Accent},0.08)
			tw(B,{TextColor3=C.BG},0.08)
			task.wait(0.12)
			tw(B,{BackgroundColor3=C.TabHov},0.15)
			tw(B,{TextColor3=C.Text},0.15)
			if cfg.Callback then cfg.Callback() end
		end)
		B.MouseEnter:Connect(function() tw(B,{BackgroundColor3=Color3.fromRGB(40,40,40)},0.1) end)
		B.MouseLeave:Connect(function() tw(B,{BackgroundColor3=C.TabHov},0.1) end)
	end

	function tab:CreateSlider(cfg)
		local minV=cfg.Range and cfg.Range[1] or 0
		local maxV=cfg.Range and cfg.Range[2] or 100
		local curV=cfg.CurrentValue or minV
		local inc=cfg.Increment or 1
		local suf=cfg.Suffix or ""

		local F=Instance.new("Frame",Scroll)
		F.Size=UDim2.new(1,0,0,52); F.BackgroundColor3=C.Elem; F.BorderSizePixel=0; F.LayoutOrder=nextOrd(); F.ZIndex=5
		corner(F,6); stroke(F,C.Border,1)

		local NL=Instance.new("TextLabel",F)
		NL.Size=UDim2.new(0.6,0,0,18); NL.Position=UDim2.new(0,10,0,7)
		NL.BackgroundTransparency=1; NL.Text=cfg.Name or "Slider"
		NL.TextColor3=C.Text; NL.TextSize=12; NL.Font=Enum.Font.Gotham
		NL.TextXAlignment=Enum.TextXAlignment.Left; NL.ZIndex=6

		local VL=Instance.new("TextLabel",F)
		VL.Size=UDim2.new(0.35,0,0,18); VL.Position=UDim2.new(0.63,0,0,7)
		VL.BackgroundTransparency=1; VL.Text=tostring(curV).." "..suf
		VL.TextColor3=C.Accent; VL.TextSize=12; VL.Font=Enum.Font.GothamBold
		VL.TextXAlignment=Enum.TextXAlignment.Right; VL.ZIndex=6

		local TrackBG=Instance.new("Frame",F)
		TrackBG.Size=UDim2.new(1,-20,0,4); TrackBG.Position=UDim2.new(0,10,0,34)
		TrackBG.BackgroundColor3=C.SliderBG; TrackBG.BorderSizePixel=0; TrackBG.ZIndex=6
		corner(TrackBG,3)

		local Fill=Instance.new("Frame",TrackBG)
		local pct=(curV-minV)/(maxV-minV)
		Fill.Size=UDim2.new(pct,0,1,0); Fill.BackgroundColor3=C.Accent
		Fill.BorderSizePixel=0; Fill.ZIndex=7; corner(Fill,3)

		local Knb=Instance.new("Frame",TrackBG)
		Knb.Size=UDim2.new(0,12,0,12); Knb.Position=UDim2.new(pct,-6,0.5,-6)
		Knb.BackgroundColor3=C.Knob; Knb.BorderSizePixel=0; Knb.ZIndex=8; corner(Knb,8)

		local ds=false
		local function upd(x)
			local rel=math.clamp((x-TrackBG.AbsolutePosition.X)/TrackBG.AbsoluteSize.X,0,1)
			local raw=minV+rel*(maxV-minV)
			local snp=math.clamp(math.round(raw/inc)*inc,minV,maxV)
			curV=snp; local p=(curV-minV)/(maxV-minV)
			Fill.Size=UDim2.new(p,0,1,0); Knb.Position=UDim2.new(p,-6,0.5,-6)
			VL.Text=tostring(curV).." "..suf
			if cfg.Callback then cfg.Callback(curV) end
		end
		TrackBG.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then ds=true; upd(inp.Position.X) end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if ds and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then upd(inp.Position.X) end
		end)
		UserInputService.InputEnded:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then ds=false end
		end)
	end

	function tab:CreateInput(cfg)
		local F=Instance.new("Frame",Scroll)
		F.Size=UDim2.new(1,0,0,56); F.BackgroundColor3=C.Elem; F.BorderSizePixel=0; F.LayoutOrder=nextOrd(); F.ZIndex=5
		corner(F,6); stroke(F,C.Border,1)

		local NL=Instance.new("TextLabel",F)
		NL.Size=UDim2.new(1,-14,0,18); NL.Position=UDim2.new(0,10,0,7)
		NL.BackgroundTransparency=1; NL.Text=cfg.Name or "Input"
		NL.TextColor3=C.Text; NL.TextSize=12; NL.Font=Enum.Font.Gotham
		NL.TextXAlignment=Enum.TextXAlignment.Left; NL.ZIndex=6

		local IBG=Instance.new("Frame",F)
		IBG.Size=UDim2.new(1,-20,0,22); IBG.Position=UDim2.new(0,10,0,28)
		IBG.BackgroundColor3=C.SliderBG; IBG.BorderSizePixel=0; IBG.ZIndex=6
		corner(IBG,5); stroke(IBG,C.Border,1)

		local IBox=Instance.new("TextBox",IBG)
		IBox.Size=UDim2.new(1,-12,1,0); IBox.Position=UDim2.new(0,8,0,0)
		IBox.BackgroundTransparency=1; IBox.PlaceholderText=cfg.PlaceholderText or "Type here..."
		IBox.PlaceholderColor3=C.Sub; IBox.Text=""; IBox.TextColor3=C.Text
		IBox.TextSize=11; IBox.Font=Enum.Font.Gotham; IBox.ClearTextOnFocus=false; IBox.ZIndex=7

		IBox.FocusLost:Connect(function() if cfg.Callback then cfg.Callback(IBox.Text) end end)
	end

	table.insert(Tabs, tab)
	if #Tabs==1 then SelectTab(tab) end
	return tab
end

------------------------------------------------
-- CREATE TABS
------------------------------------------------
local MainTab     = CreateTab("Main")
local CombatTab   = CreateTab("Combat")
local TargetTab   = CreateTab("Target")
local VisualsTab  = CreateTab("Visuals")
local ItemTab     = CreateTab("Items")
local UtilityTab  = CreateTab("Utility")
local SettingsTab = CreateTab("Settings")

------------------------------------------------
-- MAIN
------------------------------------------------
MainTab:CreateSlider({Name="Walkspeed",Range={16,500},Increment=1,Suffix="WS",CurrentValue=16,Callback=function(V) customSpeed=V end})
MainTab:CreateToggle({Name="Enable Walkspeed",CurrentValue=false,Callback=function(V) toggles.speed=V end})
MainTab:CreateSlider({Name="Jump Power",Range={50,500},Increment=1,Suffix="JP",CurrentValue=50,Callback=function(V) customJump=V end})
MainTab:CreateToggle({Name="Enable Jump Power",CurrentValue=false,Callback=function(V) toggles.jumpHigh=V if not V then local h=getHum(player.Character) if h then h.JumpPower=50 end end end})
MainTab:CreateToggle({Name="Infinite Jump",CurrentValue=false,Callback=function(V) toggles.infjump=V end})
MainTab:CreateToggle({Name="Noclip",CurrentValue=false,Callback=function(V) toggles.noclip=V if not V and player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=true end end end end})
MainTab:CreateToggle({Name="Spinbot",CurrentValue=false,Callback=function(V) toggles.spinbot=V end})
MainTab:CreateToggle({Name="God Mode",CurrentValue=false,Callback=function(V) toggles.untouchable=V end})
MainTab:CreateToggle({Name="FPS Booster",CurrentValue=false,Callback=function(V)
	toggles.fpsBoost=V
	if V then
		for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then fpsStoredMaterials[v]=v.Material; v.Material=Enum.Material.SmoothPlastic end end
	else
		for p,m in pairs(fpsStoredMaterials) do if p and p.Parent then p.Material=m end end; fpsStoredMaterials={}
	end
end})
MainTab:CreateToggle({Name="Instant Respawn",CurrentValue=false,Callback=function(V) toggles.instantRespawn=V end})

------------------------------------------------
-- COMBAT
------------------------------------------------
CombatTab:CreateToggle({Name="Hitbox Expander",CurrentValue=false,Callback=function(V) toggles.hitbox=V end})
CombatTab:CreateSlider({Name="Hitbox Size",Range={2,100},Increment=1,CurrentValue=15,Callback=function(V) hitboxSize=V end})
CombatTab:CreateToggle({Name="Freeze All",CurrentValue=false,Callback=function(V) toggles.frozeAll=V end})
CombatTab:CreateToggle({Name="Freeze Aura (35 studs)",CurrentValue=false,Callback=function(V) toggles.freezeAura=V end})
CombatTab:CreateToggle({Name="Bring All",CurrentValue=false,Callback=function(V) toggles.bringAll=V end})
CombatTab:CreateToggle({Name="Bring Nearby (70 studs)",CurrentValue=false,Callback=function(V) toggles.bringNearby=V end})

------------------------------------------------
-- TARGET
------------------------------------------------
TargetTab:CreateInput({Name="Target Player",PlaceholderText="Enter username...",Callback=function(T) targetPlayerName=T end})
TargetTab:CreateToggle({Name="Spectate Target",CurrentValue=false,Callback=function(V)
	toggles.spectate=V
	if V then task.spawn(function()
		while toggles.spectate do
			local t=GetPlayer(targetPlayerName)
			if t and t.Character and getHum(t.Character) then workspace.CurrentCamera.CameraSubject=t.Character.Humanoid
			elseif player.Character then workspace.CurrentCamera.CameraSubject=player.Character:FindFirstChild("Humanoid") end
			task.wait(0.1)
		end
	end)
	elseif player.Character then workspace.CurrentCamera.CameraSubject=player.Character:FindFirstChild("Humanoid") end
end})
TargetTab:CreateToggle({Name="Bring Target",CurrentValue=false,Callback=function(V)
	toggles.bringTarget=V
	if V then local t=GetPlayer(targetPlayerName) if t and t.Character and getHRP(t.Character) then persistentTarget=t; targetOrigPos=getHRP(t.Character).CFrame end
	else
		if persistentTarget and persistentTarget.Character and getHRP(persistentTarget.Character) and targetOrigPos then getHRP(persistentTarget.Character).CFrame=targetOrigPos end
		persistentTarget=nil; targetOrigPos=nil
	end
end})
TargetTab:CreateToggle({Name="Freeze Target",CurrentValue=false,Callback=function(V)
	toggles.freezeTarget=V; local t=GetPlayer(targetPlayerName)
	if t and t.Character and getHRP(t.Character) then getHRP(t.Character).Anchored=V end
end})

------------------------------------------------
-- VISUALS
------------------------------------------------
VisualsTab:CreateToggle({Name="ESP Highlights",CurrentValue=false,Callback=function(V) toggles.esp=V end})
VisualsTab:CreateToggle({Name="Xray Vision",CurrentValue=false,Callback=function(V)
	toggles.xray=V
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
			if V then if not xrayParts[v] then xrayParts[v]=v.Transparency end; v.Transparency=0.6
			else if xrayParts[v]~=nil then v.Transparency=xrayParts[v]; xrayParts[v]=nil end end
		end
	end
end})
VisualsTab:CreateToggle({Name="Fullbright",CurrentValue=false,Callback=function(V)
	if V then Lighting.Brightness=2; Lighting.ClockTime=12; Lighting.GlobalShadows=false; Lighting.Ambient=Color3.new(1,1,1)
	else Lighting.Brightness=origLight.Brightness; Lighting.ClockTime=origLight.ClockTime; Lighting.GlobalShadows=origLight.GlobalShadows; Lighting.Ambient=origLight.Ambient end
end})

------------------------------------------------
-- ITEMS
------------------------------------------------
ItemTab:CreateToggle({Name="TP Tool",CurrentValue=false,Callback=function(V)
	toggles.tptool=V
	if V then tpTool=Instance.new("Tool"); tpTool.Name="Click TP"; tpTool.RequiresHandle=false; tpTool.Parent=player.Backpack
		tpTool.Activated:Connect(function() local hrp=getHRP(player.Character) if hrp then hrp.CFrame=mouse.Hit*CFrame.new(0,3,0) end end)
	else if tpTool then tpTool:Destroy(); tpTool=nil end end
end})
ItemTab:CreateToggle({Name="Glide Tool",CurrentValue=false,Callback=function(V)
	toggles.glidetool=V
	if V then glideTool=createGlideTool(); glideTool.Parent=player.Backpack
	else if glideTool then glideTool:Destroy(); glideTool=nil end end
end})

------------------------------------------------
-- UTILITY
------------------------------------------------
UtilityTab:CreateToggle({Name="Hide Room",CurrentValue=false,Callback=function(V)
	toggles.hide=V; local hrp=getHRP(player.Character); if not hrp then return end
	if V then preCloudPos=hrp.CFrame; hrp.CFrame=spawnRoom()*CFrame.new(0,5,0)
	else if roomFolder then roomFolder:Destroy(); roomFolder=nil end; if preCloudPos then hrp.CFrame=preCloudPos end end
end})
UtilityTab:CreateToggle({Name="Auto Hide (< 30% HP)",CurrentValue=false,Callback=function(V) toggles.autoHide=V end})
UtilityTab:CreateToggle({Name="Instant Interact",CurrentValue=false,Callback=function(V) toggles.instantInteract=V end})
UtilityTab:CreateButton({Name="Save Position",Callback=function() local hrp=getHRP(player.Character) if hrp then savedLocation=hrp.CFrame end end})
UtilityTab:CreateButton({Name="Teleport to Saved",Callback=function() if savedLocation then local hrp=getHRP(player.Character) if hrp then hrp.CFrame=savedLocation end end end})

------------------------------------------------
-- SETTINGS
------------------------------------------------
SettingsTab:CreateToggle({Name="Anti AFK",CurrentValue=false,Callback=function(V) toggles.antiAfk=V end})
SettingsTab:CreateToggle({Name="Anti Fling",CurrentValue=false,Callback=function(V) toggles.antifling=V end})
SettingsTab:CreateToggle({Name="Anti Sit",CurrentValue=false,Callback=function(V) toggles.antisit=V end})
SettingsTab:CreateToggle({Name="Anti Stun / Ragdoll",CurrentValue=false,Callback=function(V) toggles.antistun=V end})
SettingsTab:CreateSection("Servers")
SettingsTab:CreateButton({Name="Smallest Server",Callback=function() ServerHop("Asc") end})
SettingsTab:CreateButton({Name="Biggest Server",Callback=function() ServerHop("Desc") end})
SettingsTab:CreateButton({Name="Rejoin",Callback=function() TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId) end})

------------------------------------------------
-- CORE LOOP
------------------------------------------------
RunService.Heartbeat:Connect(function()
	local char=player.Character; if not char then return end
	local hrp,hum=getHRP(char),getHum(char); if not hrp or not hum then return end

	if toggles.speed and hum.MoveDirection.Magnitude>0 then
		hrp.Velocity=Vector3.new(hum.MoveDirection.X*customSpeed,hrp.Velocity.Y,hum.MoveDirection.Z*customSpeed)
	end
	if toggles.jumpHigh then hum.JumpPower=customJump end
	if toggles.spinbot then spinAngle=(spinAngle+4)%360; hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(spinAngle),0) end
	if toggles.antisit then hum.Sit=false end
	if toggles.antistun then hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end
	if toggles.antifling then hrp.RotVelocity=Vector3.new(0,0,0) end
	if toggles.untouchable then for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=false end end
	else for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=true end end end
	if toggles.bringTarget and persistentTarget and persistentTarget.Character then
		local th=getHRP(persistentTarget.Character); if th then th.CFrame=hrp.CFrame*CFrame.new(0,0,-3) end
	end
	if toggles.autoHide then
		local hp=(hum.Health/math.max(hum.MaxHealth,1))*100
		if hp<30 and not toggles.hide then autoHideReturnPos=hrp.CFrame; hrp.CFrame=spawnRoom()*CFrame.new(0,5,0); toggles.hide=true
		elseif hp>=50 and toggles.hide and autoHideReturnPos then hrp.CFrame=autoHideReturnPos; autoHideReturnPos=nil; toggles.hide=false; if roomFolder then roomFolder:Destroy(); roomFolder=nil end end
	end
	for _,p in pairs(Players:GetPlayers()) do
		if p~=player and p.Character then
			local ph=getHRP(p.Character)
			if ph then
				local dist=(ph.Position-hrp.Position).Magnitude
				local bring=toggles.bringAll or (toggles.bringNearby and dist<70)
				local freeze=toggles.frozeAll or (toggles.freezeAura and dist<35)
				if bring or freeze then
					if not playerPositions[p.UserId] then playerPositions[p.UserId]=ph.CFrame end
					ph.Anchored=true; if bring then ph.CFrame=hrp.CFrame*CFrame.new(0,0,-5) end
				else
					if playerPositions[p.UserId] then ph.Anchored=false; ph.CFrame=playerPositions[p.UserId]; playerPositions[p.UserId]=nil end
				end
				if toggles.hitbox then ph.Size=Vector3.new(hitboxSize,hitboxSize,hitboxSize); ph.Transparency=0.6
				else ph.Size=Vector3.new(2,2,1); ph.Transparency=0 end
				if toggles.esp then
					local h=p.Character:FindFirstChild("T_ESP")
					if not h then h=Instance.new("Highlight",p.Character); h.Name="T_ESP" end; h.Enabled=true
				elseif p.Character:FindFirstChild("T_ESP") then p.Character.T_ESP.Enabled=false end
			end
		end
	end
end)

player.CharacterAdded:Connect(function(char)
	if toggles.instantRespawn then
		local hum=char:WaitForChild("Humanoid",5)
		if hum then hum.Died:Connect(function() task.wait(0.05); player:LoadCharacter() end) end
	end
end)

RunService.Stepped:Connect(function()
	if toggles.noclip and player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
	end
end)

player.Idled:Connect(function()
	if toggles.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

UserInputService.JumpRequest:Connect(function()
	if toggles.infjump then local h=getHum(player.Character) if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if toggles.instantInteract then pcall(function() fireproximityprompt(prompt) end) end
end)
