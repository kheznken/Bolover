-- [[ BOLOVERSAL HUB BY @khezn21 tiktok ]] --
-- [[ ULTRA PRO V16.6 - MOBILE EDITION ]] --

if not game:IsLoaded() then game.Loaded:Wait() end

------------------------------------------------
-- SERVICES & VARIABLES
------------------------------------------------
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
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient
}

local toggles = {
	speed = false, jumpHigh = false, frozeAll = false, bringAll = false, bringNearby = false,
	hide = false, esp = false, hitbox = false, noclip = false,
	xray = false, infjump = false, autoHide = false,
	freezeAura = false, antiAfk = false, tptool = false, glidetool = false,
	fullbright = false, spinbot = false, instantInteract = false,
	bang = false, bringTarget = false, freezeTarget = false,
	antifling = false, antisit = false, antistun = false,
	untouchable = false, fpsBoost = false, spectate = false, instantRespawn = false
}

------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(c) return c and c:FindFirstChild("Humanoid") end

local function GetPlayer(String)
	if not String or String == "" then return nil end
	String = String:lower()
	for _, v in pairs(Players:GetPlayers()) do
		if v.Name:lower():sub(1, #String) == String or v.DisplayName:lower():sub(1, #String) == String then
			return v
		end
	end
	return nil
end

local function spawnRoom()
	if roomFolder then return roomFolder:GetAttribute("CenterCF") end
	roomFolder = Instance.new("Folder", workspace)
	roomFolder.Name = "Boloversal_Room"
	local cf = CFrame.new(math.random(-90000, 90000), 40000, math.random(-90000, 90000))
	roomFolder:SetAttribute("CenterCF", cf)
	local function qp(sz, pos, col, mat)
		local p = Instance.new("Part", roomFolder)
		p.Size = sz; p.CFrame = cf * pos; p.Anchored = true; p.Color = col
		p.Material = mat or Enum.Material.Plastic
		return p
	end
	qp(Vector3.new(80,1,80), CFrame.new(0,0,0), Color3.fromRGB(255,255,255), Enum.Material.SmoothPlastic)
	qp(Vector3.new(80,25,1), CFrame.new(0,12.5,-40), Color3.fromRGB(240,240,240))
	local glass = qp(Vector3.new(0.5,13,40), CFrame.new(40,12.5,0), Color3.fromRGB(180,225,255), Enum.Material.Glass)
	glass.Transparency = 0.4
	return cf
end

local function ServerHop(sort)
	local ok, res = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder="..sort.."&limit=100"))
	end)
	if not ok then return end
	for _, v in pairs(res.data) do
		if v.playing < v.maxPlayers and v.id ~= game.JobId then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
			break
		end
	end
end

local function createGlideTool()
	local tool = Instance.new("Tool")
	tool.Name = "Glide Tool"
	tool.RequiresHandle = true
	local handle = Instance.new("Part", tool)
	handle.Name = "Handle"; handle.Size = Vector3.new(2,2,1); handle.CanCollide = false
	local mesh = Instance.new("SpecialMesh", handle)
	mesh.MeshId = "rbxassetid://68203112"; mesh.TextureId = "rbxassetid://68203091"; mesh.Scale = Vector3.new(1.5,1.5,1.5)
	local a0 = Instance.new("Attachment", handle); a0.Position = Vector3.new(0,0.5,0)
	local a1 = Instance.new("Attachment", handle); a1.Position = Vector3.new(0,-0.5,0)
	local tr = Instance.new("Trail", handle); tr.Attachment0 = a0; tr.Attachment1 = a1
	tr.Color = ColorSequence.new(Color3.new(0,1,1)); tr.Enabled = false
	local gliding = false
	tool.Activated:Connect(function()
		if gliding then return end
		local hrp = getHRP(player.Character)
		if hrp then
			gliding = true; tr.Enabled = true
			local target = mouse.Hit.Position
			local nc = RunService.Stepped:Connect(function()
				if player.Character then for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
			end)
			local bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(1e6,1e6,1e6)
			bv.Velocity = (target - hrp.Position).Unit * 120
			local bg = Instance.new("BodyGyro", hrp); bg.MaxTorque = Vector3.new(1e6,1e6,1e6)
			bg.CFrame = CFrame.new(hrp.Position, target)
			task.wait((target - hrp.Position).Magnitude / 120)
			nc:Disconnect(); bv:Destroy(); bg:Destroy(); tr.Enabled = false; gliding = false
			if player.Character then for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end end
		end
	end)
	return tool
end

------------------------------------------------
-- RAYFIELD-STYLE UI LIBRARY (BUILT-IN, NO HTTP)
------------------------------------------------
local Library = {}
Library.__index = Library

local THEME = {
	Background    = Color3.fromRGB(14, 14, 20),
	TopBar        = Color3.fromRGB(20, 20, 30),
	Accent        = Color3.fromRGB(100, 80, 220),
	AccentHover   = Color3.fromRGB(120, 100, 240),
	TabBG         = Color3.fromRGB(18, 18, 26),
	TabActive     = Color3.fromRGB(28, 28, 40),
	Element       = Color3.fromRGB(22, 22, 32),
	ElementHover  = Color3.fromRGB(30, 30, 44),
	ToggleOn      = Color3.fromRGB(100, 80, 220),
	ToggleOff     = Color3.fromRGB(50, 50, 70),
	Text          = Color3.fromRGB(230, 230, 255),
	SubText       = Color3.fromRGB(140, 140, 180),
	Separator     = Color3.fromRGB(35, 35, 50),
	SliderFill    = Color3.fromRGB(100, 80, 220),
	SliderBG      = Color3.fromRGB(35, 35, 55),
	InputBG       = Color3.fromRGB(18, 18, 28),
	Shadow        = Color3.fromRGB(0, 0, 0),
}

local function tween(obj, props, t, style, dir)
	TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play()
end

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 8)
	return c
end

local function makeStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or Color3.fromRGB(60,60,90)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	return s
end

local function makeShadow(parent)
	local shadow = Instance.new("ImageLabel", parent)
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1, 24, 1, 24)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.new(0,0,0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	return shadow
end

function Library:CreateWindow(config)
	local win = {}
	win.Tabs = {}
	win.ActiveTab = nil
	win.Visible = true
	win.Config = config or {}

	-- ScreenGui
	local SG = Instance.new("ScreenGui")
	SG.Name = "BoloverHub"
	SG.ResetOnSpawn = false
	SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SG.IgnoreGuiInset = true
	SG.DisplayOrder = 999
	SG.Parent = player.PlayerGui

	-- Loading Screen
	local LoadFrame = Instance.new("Frame", SG)
	LoadFrame.Size = UDim2.new(1,0,1,0)
	LoadFrame.BackgroundColor3 = Color3.fromRGB(8,8,12)
	LoadFrame.BorderSizePixel = 0
	LoadFrame.ZIndex = 100

	local LoadInner = Instance.new("Frame", LoadFrame)
	LoadInner.Size = UDim2.new(0, 320, 0, 160)
	LoadInner.AnchorPoint = Vector2.new(0.5,0.5)
	LoadInner.Position = UDim2.new(0.5,0,0.5,0)
	LoadInner.BackgroundColor3 = THEME.TopBar
	LoadInner.BorderSizePixel = 0
	LoadInner.ZIndex = 101
	makeCorner(LoadInner, 14)
	makeStroke(LoadInner, THEME.Accent, 1.5)
	makeShadow(LoadInner)

	local LoadTitle = Instance.new("TextLabel", LoadInner)
	LoadTitle.Size = UDim2.new(1,0,0,50)
	LoadTitle.Position = UDim2.new(0,0,0,18)
	LoadTitle.BackgroundTransparency = 1
	LoadTitle.Text = config.LoadingTitle or "Loading..."
	LoadTitle.TextColor3 = THEME.Text
	LoadTitle.TextScaled = true
	LoadTitle.Font = Enum.Font.GothamBold
	LoadTitle.ZIndex = 102

	local LoadSub = Instance.new("TextLabel", LoadInner)
	LoadSub.Size = UDim2.new(1,0,0,28)
	LoadSub.Position = UDim2.new(0,0,0,64)
	LoadSub.BackgroundTransparency = 1
	LoadSub.Text = config.LoadingSubtitle or ""
	LoadSub.TextColor3 = THEME.SubText
	LoadSub.TextScaled = true
	LoadSub.Font = Enum.Font.Gotham
	LoadSub.ZIndex = 102

	local BarBG = Instance.new("Frame", LoadInner)
	BarBG.Size = UDim2.new(0.8,0,0,6)
	BarBG.Position = UDim2.new(0.1,0,0,108)
	BarBG.BackgroundColor3 = THEME.SliderBG
	BarBG.BorderSizePixel = 0
	BarBG.ZIndex = 102
	makeCorner(BarBG, 4)

	local BarFill = Instance.new("Frame", BarBG)
	BarFill.Size = UDim2.new(0,0,1,0)
	BarFill.BackgroundColor3 = THEME.Accent
	BarFill.BorderSizePixel = 0
	BarFill.ZIndex = 103
	makeCorner(BarFill, 4)

	local LoadDots = Instance.new("TextLabel", LoadInner)
	LoadDots.Size = UDim2.new(1,0,0,24)
	LoadDots.Position = UDim2.new(0,0,0,126)
	LoadDots.BackgroundTransparency = 1
	LoadDots.Text = "Loading assets..."
	LoadDots.TextColor3 = THEME.SubText
	LoadDots.TextScaled = true
	LoadDots.Font = Enum.Font.Gotham
	LoadDots.ZIndex = 102

	-- Animate loading bar
	task.spawn(function()
		local msgs = {"Initializing...","Loading modules...","Setting up UI...","Almost ready...","Done!"}
		for i, msg in ipairs(msgs) do
			LoadDots.Text = msg
			tween(BarFill, {Size = UDim2.new(i / #msgs, 0, 1, 0)}, 0.35)
			task.wait(0.28)
		end
		task.wait(0.2)
		tween(LoadFrame, {BackgroundTransparency = 1}, 0.5)
		tween(LoadInner, {BackgroundTransparency = 1}, 0.5)
		for _, v in ipairs(LoadInner:GetDescendants()) do
			if v:IsA("TextLabel") or v:IsA("Frame") then
				tween(v, {BackgroundTransparency = 1}, 0.5)
				if v:IsA("TextLabel") then tween(v, {TextTransparency = 1}, 0.5) end
			end
		end
		task.wait(0.55)
		LoadFrame:Destroy()
	end)

	-- Main window frame
	local MainFrame = Instance.new("Frame", SG)
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 520, 0, 420)
	MainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
	MainFrame.BackgroundColor3 = THEME.Background
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = false
	makeCorner(MainFrame, 12)
	makeStroke(MainFrame, Color3.fromRGB(50,50,75), 1.2)
	makeShadow(MainFrame)

	-- Top bar
	local TopBar = Instance.new("Frame", MainFrame)
	TopBar.Size = UDim2.new(1,0,0,44)
	TopBar.BackgroundColor3 = THEME.TopBar
	TopBar.BorderSizePixel = 0
	TopBar.ZIndex = 2
	makeCorner(TopBar, 12)

	-- Cover bottom corners of topbar
	local TopBarFix = Instance.new("Frame", TopBar)
	TopBarFix.Size = UDim2.new(1,0,0.5,0)
	TopBarFix.Position = UDim2.new(0,0,0.5,0)
	TopBarFix.BackgroundColor3 = THEME.TopBar
	TopBarFix.BorderSizePixel = 0
	TopBarFix.ZIndex = 2

	-- Accent line under topbar
	local AccentLine = Instance.new("Frame", MainFrame)
	AccentLine.Size = UDim2.new(1,0,0,2)
	AccentLine.Position = UDim2.new(0,0,0,44)
	AccentLine.BackgroundColor3 = THEME.Accent
	AccentLine.BorderSizePixel = 0
	AccentLine.ZIndex = 3

	local TitleLabel = Instance.new("TextLabel", TopBar)
	TitleLabel.Size = UDim2.new(1,-90,1,0)
	TitleLabel.Position = UDim2.new(0,14,0,0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = config.Name or "Hub"
	TitleLabel.TextColor3 = THEME.Text
	TitleLabel.TextScaled = true
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 3

	-- Minimize button
	local MinBtn = Instance.new("TextButton", TopBar)
	MinBtn.Size = UDim2.new(0,30,0,22)
	MinBtn.Position = UDim2.new(1,-72,0.5,-11)
	MinBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
	MinBtn.BorderSizePixel = 0
	MinBtn.Text = "—"
	MinBtn.TextColor3 = THEME.SubText
	MinBtn.TextScaled = true
	MinBtn.Font = Enum.Font.GothamBold
	MinBtn.ZIndex = 4
	makeCorner(MinBtn, 6)

	-- Close button
	local CloseBtn = Instance.new("TextButton", TopBar)
	CloseBtn.Size = UDim2.new(0,30,0,22)
	CloseBtn.Position = UDim2.new(1,-36,0.5,-11)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(180,50,70)
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Text = "✕"
	CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
	CloseBtn.TextScaled = true
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.ZIndex = 4
	makeCorner(CloseBtn, 6)

	-- Sidebar
	local Sidebar = Instance.new("Frame", MainFrame)
	Sidebar.Size = UDim2.new(0,110,1,-46)
	Sidebar.Position = UDim2.new(0,0,0,46)
	Sidebar.BackgroundColor3 = THEME.TabBG
	Sidebar.BorderSizePixel = 0
	Sidebar.ZIndex = 2

	local SidebarFix = Instance.new("Frame", Sidebar)
	SidebarFix.Size = UDim2.new(1,0,1,0)
	SidebarFix.BackgroundColor3 = THEME.TabBG
	SidebarFix.BorderSizePixel = 0
	SidebarFix.ZIndex = 1

	local BottomLeftCorner = Instance.new("Frame", MainFrame)
	BottomLeftCorner.Size = UDim2.new(0,110,0,12)
	BottomLeftCorner.Position = UDim2.new(0,0,1,-12)
	BottomLeftCorner.BackgroundColor3 = THEME.TabBG
	BottomLeftCorner.BorderSizePixel = 0
	BottomLeftCorner.ZIndex = 2

	local SideList = Instance.new("UIListLayout", Sidebar)
	SideList.SortOrder = Enum.SortOrder.LayoutOrder
	SideList.Padding = UDim.new(0,2)

	local SidePad = Instance.new("UIPadding", Sidebar)
	SidePad.PaddingTop = UDim.new(0,8)
	SidePad.PaddingLeft = UDim.new(0,6)
	SidePad.PaddingRight = UDim.new(0,6)

	-- Content area
	local ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(1,-114,1,-50)
	ContentArea.Position = UDim2.new(0,114,0,50)
	ContentArea.BackgroundTransparency = 1
	ContentArea.BorderSizePixel = 0
	ContentArea.ZIndex = 2
	ContentArea.ClipsDescendants = true

	-- Toggle visibility button (floating, for mobile)
	local FloatBtn = Instance.new("TextButton", SG)
	FloatBtn.Size = UDim2.new(0,48,0,48)
	FloatBtn.Position = UDim2.new(0,8,0.45,0)
	FloatBtn.BackgroundColor3 = THEME.Accent
	FloatBtn.BorderSizePixel = 0
	FloatBtn.Text = "☰"
	FloatBtn.TextColor3 = Color3.fromRGB(255,255,255)
	FloatBtn.TextScaled = true
	FloatBtn.Font = Enum.Font.GothamBold
	FloatBtn.ZIndex = 50
	FloatBtn.Visible = false
	makeCorner(FloatBtn, 12)
	makeStroke(FloatBtn, Color3.fromRGB(140,120,255), 1.5)

	-- Dragging
	local dragging, dragStart, startPos = false, nil, nil
	TopBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = inp.Position; startPos = MainFrame.Position
		end
	end)
	TopBar.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
		end
	end)

	local minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			tween(MainFrame, {Size = UDim2.new(0,520,0,44)}, 0.25)
			FloatBtn.Visible = true
		else
			tween(MainFrame, {Size = UDim2.new(0,520,0,420)}, 0.25)
			FloatBtn.Visible = false
		end
	end)
	CloseBtn.MouseButton1Click:Connect(function()
		tween(MainFrame, {Size = UDim2.new(0,520,0,0), BackgroundTransparency = 1}, 0.3)
		task.wait(0.35)
		SG:Destroy()
	end)
	FloatBtn.MouseButton1Click:Connect(function()
		minimized = false
		tween(MainFrame, {Size = UDim2.new(0,520,0,420)}, 0.25)
		FloatBtn.Visible = false
	end)

	-- Mobile drag for FloatBtn
	local fbDragging, fbDragStart, fbStartPos = false, nil, nil
	FloatBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch then
			fbDragging = true; fbDragStart = inp.Position; fbStartPos = FloatBtn.Position
		end
	end)
	FloatBtn.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.Touch then fbDragging = false end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if fbDragging and inp.UserInputType == Enum.UserInputType.Touch then
			local d = inp.Position - fbDragStart
			FloatBtn.Position = UDim2.new(fbStartPos.X.Scale, fbStartPos.X.Offset+d.X, fbStartPos.Y.Scale, fbStartPos.Y.Offset+d.Y)
		end
	end)

	-- Window object methods
	function win:CreateTab(name, icon)
		local tab = {}
		tab.Name = name
		tab.Elements = {}

		-- Tab button
		local TabBtn = Instance.new("TextButton", Sidebar)
		TabBtn.Size = UDim2.new(1,0,0,36)
		TabBtn.BackgroundColor3 = THEME.TabBG
		TabBtn.BorderSizePixel = 0
		TabBtn.Text = ""
		TabBtn.ZIndex = 3
		TabBtn.LayoutOrder = #win.Tabs + 1
		makeCorner(TabBtn, 8)

		local TabLabel = Instance.new("TextLabel", TabBtn)
		TabLabel.Size = UDim2.new(1,-8,1,0)
		TabLabel.Position = UDim2.new(0,8,0,0)
		TabLabel.BackgroundTransparency = 1
		TabLabel.Text = name
		TabLabel.TextColor3 = THEME.SubText
		TabLabel.TextScaled = true
		TabLabel.Font = Enum.Font.Gotham
		TabLabel.TextXAlignment = Enum.TextXAlignment.Left
		TabLabel.ZIndex = 4

		local ActiveBar = Instance.new("Frame", TabBtn)
		ActiveBar.Size = UDim2.new(0,3,0.6,0)
		ActiveBar.Position = UDim2.new(0,-3,0.2,0)
		ActiveBar.BackgroundColor3 = THEME.Accent
		ActiveBar.BorderSizePixel = 0
		ActiveBar.Visible = false
		ActiveBar.ZIndex = 4
		makeCorner(ActiveBar, 2)

		-- Scroll frame for tab content
		local ScrollFrame = Instance.new("ScrollingFrame", ContentArea)
		ScrollFrame.Size = UDim2.new(1,0,1,0)
		ScrollFrame.BackgroundTransparency = 1
		ScrollFrame.BorderSizePixel = 0
		ScrollFrame.ScrollBarThickness = 3
		ScrollFrame.ScrollBarImageColor3 = THEME.Accent
		ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
		ScrollFrame.Visible = false
		ScrollFrame.ZIndex = 3

		local ListLayout = Instance.new("UIListLayout", ScrollFrame)
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0,6)

		local Padding = Instance.new("UIPadding", ScrollFrame)
		Padding.PaddingTop = UDim.new(0,8)
		Padding.PaddingLeft = UDim.new(0,8)
		Padding.PaddingRight = UDim.new(0,8)

		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ScrollFrame.CanvasSize = UDim2.new(0,0,0,ListLayout.AbsoluteContentSize.Y+16)
		end)

		tab.ScrollFrame = ScrollFrame
		tab.ListLayout = ListLayout
		tab.TabBtn = TabBtn
		tab.ActiveBar = ActiveBar
		tab.TabLabel = TabLabel

		TabBtn.MouseButton1Click:Connect(function()
			win:SelectTab(tab)
		end)

		TabBtn.MouseEnter:Connect(function()
			if win.ActiveTab ~= tab then
				tween(TabBtn, {BackgroundColor3 = THEME.TabActive}, 0.15)
				tween(TabLabel, {TextColor3 = THEME.Text}, 0.15)
			end
		end)
		TabBtn.MouseLeave:Connect(function()
			if win.ActiveTab ~= tab then
				tween(TabBtn, {BackgroundColor3 = THEME.TabBG}, 0.15)
				tween(TabLabel, {TextColor3 = THEME.SubText}, 0.15)
			end
		end)

		table.insert(win.Tabs, tab)
		if #win.Tabs == 1 then win:SelectTab(tab) end

		-- Element creator helpers
		local elemOrder = 0
		local function nextOrder() elemOrder = elemOrder + 1 return elemOrder end

		function tab:CreateSection(name)
			local SepFrame = Instance.new("Frame", ScrollFrame)
			SepFrame.Size = UDim2.new(1,0,0,28)
			SepFrame.BackgroundTransparency = 1
			SepFrame.BorderSizePixel = 0
			SepFrame.LayoutOrder = nextOrder()
			SepFrame.ZIndex = 3

			local Line = Instance.new("Frame", SepFrame)
			Line.Size = UDim2.new(1,0,0,1)
			Line.Position = UDim2.new(0,0,0.5,0)
			Line.BackgroundColor3 = THEME.Separator
			Line.BorderSizePixel = 0
			Line.ZIndex = 4

			local SLabel = Instance.new("TextLabel", SepFrame)
			SLabel.Size = UDim2.new(0,0,1,0)
			SLabel.AutomaticSize = Enum.AutomaticSize.X
			SLabel.Position = UDim2.new(0.5,0,0,0)
			SLabel.AnchorPoint = Vector2.new(0.5,0)
			SLabel.BackgroundColor3 = THEME.Background
			SLabel.BorderSizePixel = 0
			SLabel.Text = "  "..name.."  "
			SLabel.TextColor3 = THEME.SubText
			SLabel.TextScaled = true
			SLabel.Font = Enum.Font.GothamBold
			SLabel.ZIndex = 5
		end

		function tab:CreateToggle(config)
			local val = config.CurrentValue or false
			local Frame = Instance.new("Frame", ScrollFrame)
			Frame.Size = UDim2.new(1,0,0,46)
			Frame.BackgroundColor3 = THEME.Element
			Frame.BorderSizePixel = 0
			Frame.LayoutOrder = nextOrder()
			Frame.ZIndex = 3
			makeCorner(Frame, 8)
			makeStroke(Frame, THEME.Separator, 1, 0.5)

			local NameLabel = Instance.new("TextLabel", Frame)
			NameLabel.Size = UDim2.new(1,-70,0.6,0)
			NameLabel.Position = UDim2.new(0,14,0,5)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Text = config.Name or "Toggle"
			NameLabel.TextColor3 = THEME.Text
			NameLabel.TextScaled = true
			NameLabel.Font = Enum.Font.Gotham
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.ZIndex = 4

			local SubLabel = Instance.new("TextLabel", Frame)
			SubLabel.Size = UDim2.new(1,-70,0.35,0)
			SubLabel.Position = UDim2.new(0,14,0.62,0)
			SubLabel.BackgroundTransparency = 1
			SubLabel.Text = val and "Enabled" or "Disabled"
			SubLabel.TextColor3 = val and THEME.Accent or THEME.SubText
			SubLabel.TextScaled = true
			SubLabel.Font = Enum.Font.Gotham
			SubLabel.TextXAlignment = Enum.TextXAlignment.Left
			SubLabel.ZIndex = 4

			-- Toggle pill
			local PillBG = Instance.new("Frame", Frame)
			PillBG.Size = UDim2.new(0,44,0,24)
			PillBG.Position = UDim2.new(1,-56,0.5,-12)
			PillBG.BackgroundColor3 = val and THEME.ToggleOn or THEME.ToggleOff
			PillBG.BorderSizePixel = 0
			PillBG.ZIndex = 4
			makeCorner(PillBG, 12)

			local Circle = Instance.new("Frame", PillBG)
			Circle.Size = UDim2.new(0,18,0,18)
			Circle.Position = val and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
			Circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Circle.BorderSizePixel = 0
			Circle.ZIndex = 5
			makeCorner(Circle, 10)

			local ClickBtn = Instance.new("TextButton", Frame)
			ClickBtn.Size = UDim2.new(1,0,1,0)
			ClickBtn.BackgroundTransparency = 1
			ClickBtn.Text = ""
			ClickBtn.ZIndex = 6

			ClickBtn.MouseButton1Click:Connect(function()
				val = not val
				tween(PillBG, {BackgroundColor3 = val and THEME.ToggleOn or THEME.ToggleOff}, 0.2)
				tween(Circle, {Position = val and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}, 0.2)
				SubLabel.Text = val and "Enabled" or "Disabled"
				tween(SubLabel, {TextColor3 = val and THEME.Accent or THEME.SubText}, 0.15)
				tween(Frame, {BackgroundColor3 = val and Color3.fromRGB(26,24,40) or THEME.Element}, 0.15)
				if config.Callback then config.Callback(val) end
			end)

			ClickBtn.MouseEnter:Connect(function()
				tween(Frame, {BackgroundColor3 = THEME.ElementHover}, 0.15)
			end)
			ClickBtn.MouseLeave:Connect(function()
				tween(Frame, {BackgroundColor3 = val and Color3.fromRGB(26,24,40) or THEME.Element}, 0.15)
			end)
		end

		function tab:CreateButton(config)
			local Frame = Instance.new("Frame", ScrollFrame)
			Frame.Size = UDim2.new(1,0,0,42)
			Frame.BackgroundColor3 = THEME.Element
			Frame.BorderSizePixel = 0
			Frame.LayoutOrder = nextOrder()
			Frame.ZIndex = 3
			makeCorner(Frame, 8)
			makeStroke(Frame, THEME.Separator, 1, 0.5)

			local Btn = Instance.new("TextButton", Frame)
			Btn.Size = UDim2.new(1,-20,0,28)
			Btn.Position = UDim2.new(0,10,0.5,-14)
			Btn.BackgroundColor3 = THEME.Accent
			Btn.BorderSizePixel = 0
			Btn.Text = config.Name or "Button"
			Btn.TextColor3 = Color3.fromRGB(255,255,255)
			Btn.TextScaled = true
			Btn.Font = Enum.Font.GothamBold
			Btn.ZIndex = 4
			makeCorner(Btn, 7)

			Btn.MouseButton1Click:Connect(function()
				tween(Btn, {BackgroundColor3 = THEME.AccentHover}, 0.1)
				task.wait(0.12)
				tween(Btn, {BackgroundColor3 = THEME.Accent}, 0.15)
				if config.Callback then config.Callback() end
			end)
			Btn.MouseEnter:Connect(function() tween(Btn, {BackgroundColor3 = THEME.AccentHover}, 0.15) end)
			Btn.MouseLeave:Connect(function() tween(Btn, {BackgroundColor3 = THEME.Accent}, 0.15) end)
		end

		function tab:CreateSlider(config)
			local minV = config.Range and config.Range[1] or 0
			local maxV = config.Range and config.Range[2] or 100
			local curV = config.CurrentValue or minV
			local inc = config.Increment or 1
			local suffix = config.Suffix or ""

			local Frame = Instance.new("Frame", ScrollFrame)
			Frame.Size = UDim2.new(1,0,0,58)
			Frame.BackgroundColor3 = THEME.Element
			Frame.BorderSizePixel = 0
			Frame.LayoutOrder = nextOrder()
			Frame.ZIndex = 3
			makeCorner(Frame, 8)
			makeStroke(Frame, THEME.Separator, 1, 0.5)

			local NameLabel = Instance.new("TextLabel", Frame)
			NameLabel.Size = UDim2.new(0.6,0,0,22)
			NameLabel.Position = UDim2.new(0,14,0,6)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Text = config.Name or "Slider"
			NameLabel.TextColor3 = THEME.Text
			NameLabel.TextScaled = true
			NameLabel.Font = Enum.Font.Gotham
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.ZIndex = 4

			local ValLabel = Instance.new("TextLabel", Frame)
			ValLabel.Size = UDim2.new(0.35,0,0,22)
			ValLabel.Position = UDim2.new(0.62,0,0,6)
			ValLabel.BackgroundTransparency = 1
			ValLabel.Text = tostring(curV).." "..suffix
			ValLabel.TextColor3 = THEME.Accent
			ValLabel.TextScaled = true
			ValLabel.Font = Enum.Font.GothamBold
			ValLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValLabel.ZIndex = 4

			local TrackBG = Instance.new("Frame", Frame)
			TrackBG.Size = UDim2.new(1,-28,0,6)
			TrackBG.Position = UDim2.new(0,14,0,36)
			TrackBG.BackgroundColor3 = THEME.SliderBG
			TrackBG.BorderSizePixel = 0
			TrackBG.ZIndex = 4
			makeCorner(TrackBG, 4)

			local TrackFill = Instance.new("Frame", TrackBG)
			local fillPct = (curV - minV) / (maxV - minV)
			TrackFill.Size = UDim2.new(fillPct, 0, 1, 0)
			TrackFill.BackgroundColor3 = THEME.SliderFill
			TrackFill.BorderSizePixel = 0
			TrackFill.ZIndex = 5
			makeCorner(TrackFill, 4)

			local Knob = Instance.new("Frame", TrackBG)
			Knob.Size = UDim2.new(0,14,0,14)
			Knob.Position = UDim2.new(fillPct, -7, 0.5, -7)
			Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			Knob.BorderSizePixel = 0
			Knob.ZIndex = 6
			makeCorner(Knob, 8)

			local draggingSlider = false
			local function update(x)
				local rel = math.clamp((x - TrackBG.AbsolutePosition.X) / TrackBG.AbsoluteSize.X, 0, 1)
				local raw = minV + rel * (maxV - minV)
				local snapped = math.round(raw / inc) * inc
				snapped = math.clamp(snapped, minV, maxV)
				curV = snapped
				local pct = (curV - minV) / (maxV - minV)
				TrackFill.Size = UDim2.new(pct, 0, 1, 0)
				Knob.Position = UDim2.new(pct, -7, 0.5, -7)
				ValLabel.Text = tostring(curV).." "..suffix
				if config.Callback then config.Callback(curV) end
			end

			TrackBG.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
					draggingSlider = true; update(inp.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(inp)
				if draggingSlider and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
					update(inp.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
					draggingSlider = false
				end
			end)
		end

		function tab:CreateInput(config)
			local val = ""
			local Frame = Instance.new("Frame", ScrollFrame)
			Frame.Size = UDim2.new(1,0,0,62)
			Frame.BackgroundColor3 = THEME.Element
			Frame.BorderSizePixel = 0
			Frame.LayoutOrder = nextOrder()
			Frame.ZIndex = 3
			makeCorner(Frame, 8)
			makeStroke(Frame, THEME.Separator, 1, 0.5)

			local NameLabel = Instance.new("TextLabel", Frame)
			NameLabel.Size = UDim2.new(1,-14,0,22)
			NameLabel.Position = UDim2.new(0,14,0,6)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Text = config.Name or "Input"
			NameLabel.TextColor3 = THEME.Text
			NameLabel.TextScaled = true
			NameLabel.Font = Enum.Font.Gotham
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.ZIndex = 4

			local InputBG = Instance.new("Frame", Frame)
			InputBG.Size = UDim2.new(1,-28,0,26)
			InputBG.Position = UDim2.new(0,14,0,30)
			InputBG.BackgroundColor3 = THEME.InputBG
			InputBG.BorderSizePixel = 0
			InputBG.ZIndex = 4
			makeCorner(InputBG, 6)
			makeStroke(InputBG, THEME.Accent, 1, 0.7)

			local InputBox = Instance.new("TextBox", InputBG)
			InputBox.Size = UDim2.new(1,-10,1,0)
			InputBox.Position = UDim2.new(0,8,0,0)
			InputBox.BackgroundTransparency = 1
			InputBox.PlaceholderText = config.PlaceholderText or "Type here..."
			InputBox.PlaceholderColor3 = THEME.SubText
			InputBox.Text = ""
			InputBox.TextColor3 = THEME.Text
			InputBox.TextScaled = true
			InputBox.Font = Enum.Font.Gotham
			InputBox.ClearTextOnFocus = false
			InputBox.ZIndex = 5

			InputBox.FocusLost:Connect(function(enter)
				val = InputBox.Text
				if config.Callback then config.Callback(val) end
				tween(InputBG:FindFirstChildWhichIsA("UIStroke") or makeStroke(InputBG, THEME.Accent), {Transparency = 0.7}, 0.15)
			end)
			InputBox.Focused:Connect(function()
				tween(InputBG:FindFirstChildWhichIsA("UIStroke") or makeStroke(InputBG, THEME.Accent), {Transparency = 0}, 0.15)
			end)
		end

		return tab
	end

	function win:SelectTab(tab)
		if win.ActiveTab == tab then return end
		if win.ActiveTab then
			tween(win.ActiveTab.TabBtn, {BackgroundColor3 = THEME.TabBG}, 0.2)
			tween(win.ActiveTab.TabLabel, {TextColor3 = THEME.SubText}, 0.2)
			win.ActiveTab.ActiveBar.Visible = false
			win.ActiveTab.ScrollFrame.Visible = false
		end
		win.ActiveTab = tab
		tween(tab.TabBtn, {BackgroundColor3 = THEME.TabActive}, 0.2)
		tween(tab.TabLabel, {TextColor3 = THEME.Text}, 0.2)
		tab.ActiveBar.Visible = true
		tab.ScrollFrame.Visible = true
		tab.TabLabel.Font = Enum.Font.GothamBold
	end

	win.SG = SG
	return win
end

------------------------------------------------
-- CREATE WINDOW
------------------------------------------------
local Window = Library:CreateWindow({
	Name = "BOLOVERSAL Hub  •  @khezn21",
	LoadingTitle = "ULTRA PRO V16.6",
	LoadingSubtitle = "by khen.khen457",
})

------------------------------------------------
-- TABS
------------------------------------------------
local MainTab     = Window:CreateTab("Main")
local CombatTab   = Window:CreateTab("Combat")
local TargetTab   = Window:CreateTab("Target")
local VisualsTab  = Window:CreateTab("Visuals")
local ItemTab     = Window:CreateTab("Items")
local UtilityTab  = Window:CreateTab("Utility")
local SettingsTab = Window:CreateTab("Settings")

------------------------------------------------
-- MAIN TAB
------------------------------------------------
MainTab:CreateSlider({ Name = "Walkspeed", Range = {16,500}, Increment = 1, Suffix = "WS", CurrentValue = 16, Callback = function(V) customSpeed = V end })
MainTab:CreateToggle({ Name = "Enable Walkspeed", CurrentValue = false, Callback = function(V) toggles.speed = V end })
MainTab:CreateSlider({ Name = "Jump Power", Range = {50,500}, Increment = 1, Suffix = "JP", CurrentValue = 50, Callback = function(V) customJump = V end })
MainTab:CreateToggle({ Name = "Enable Jump Power", CurrentValue = false, Callback = function(V) toggles.jumpHigh = V if not V then local h = getHum(player.Character) if h then h.JumpPower = 50 end end end })
MainTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(V) toggles.infjump = V end })
MainTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(V) toggles.noclip = V if not V and player.Character then for _,v in pairs(player.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end end end })
MainTab:CreateToggle({ Name = "Spinbot", CurrentValue = false, Callback = function(V) toggles.spinbot = V end })
MainTab:CreateToggle({ Name = "God Mode", CurrentValue = false, Callback = function(V) toggles.untouchable = V end })
MainTab:CreateToggle({ Name = "FPS Booster", CurrentValue = false, Callback = function(V)
	toggles.fpsBoost = V
	if V then
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then fpsStoredMaterials[v] = v.Material; v.Material = Enum.Material.SmoothPlastic end
		end
	else
		for part, mat in pairs(fpsStoredMaterials) do if part and part.Parent then part.Material = mat end end
		fpsStoredMaterials = {}
	end
end })
MainTab:CreateToggle({ Name = "Instant Respawn", CurrentValue = false, Callback = function(V) toggles.instantRespawn = V end })

------------------------------------------------
-- COMBAT TAB
------------------------------------------------
CombatTab:CreateToggle({ Name = "Hitbox Expander", CurrentValue = false, Callback = function(V) toggles.hitbox = V end })
CombatTab:CreateSlider({ Name = "Hitbox Size", Range = {2,100}, Increment = 1, CurrentValue = 15, Callback = function(V) hitboxSize = V end })
CombatTab:CreateToggle({ Name = "Freeze All", CurrentValue = false, Callback = function(V) toggles.frozeAll = V end })
CombatTab:CreateToggle({ Name = "Freeze Aura (35 stud)", CurrentValue = false, Callback = function(V) toggles.freezeAura = V end })
CombatTab:CreateToggle({ Name = "Bring All", CurrentValue = false, Callback = function(V) toggles.bringAll = V end })
CombatTab:CreateToggle({ Name = "Bring Nearby (70 stud)", CurrentValue = false, Callback = function(V) toggles.bringNearby = V end })

------------------------------------------------
-- TARGET TAB
------------------------------------------------
TargetTab:CreateInput({ Name = "Target Player", PlaceholderText = "Enter username...", Callback = function(T) targetPlayerName = T end })
TargetTab:CreateToggle({ Name = "Spectate Target", CurrentValue = false, Callback = function(V)
	toggles.spectate = V
	if V then
		task.spawn(function()
			while toggles.spectate do
				local t = GetPlayer(targetPlayerName)
				if t and t.Character and getHum(t.Character) then
					workspace.CurrentCamera.CameraSubject = t.Character.Humanoid
				else
					if player.Character then workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid") end
				end
				task.wait(0.1)
			end
		end)
	else
		if player.Character then workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid") end
	end
end })
TargetTab:CreateToggle({ Name = "Bring Target", CurrentValue = false, Callback = function(V)
	toggles.bringTarget = V
	if V then
		local t = GetPlayer(targetPlayerName)
		if t and t.Character and getHRP(t.Character) then
			persistentTarget = t
			targetOrigPos = getHRP(t.Character).CFrame
		end
	else
		if persistentTarget and persistentTarget.Character and getHRP(persistentTarget.Character) and targetOrigPos then
			getHRP(persistentTarget.Character).CFrame = targetOrigPos
		end
		persistentTarget = nil; targetOrigPos = nil
	end
end })
TargetTab:CreateToggle({ Name = "Freeze Target", CurrentValue = false, Callback = function(V)
	toggles.freezeTarget = V
	local t = GetPlayer(targetPlayerName)
	if t and t.Character and getHRP(t.Character) then getHRP(t.Character).Anchored = V end
end })

------------------------------------------------
-- VISUALS TAB
------------------------------------------------
VisualsTab:CreateToggle({ Name = "ESP Highlights", CurrentValue = false, Callback = function(V) toggles.esp = V end })
VisualsTab:CreateToggle({ Name = "Xray Vision", CurrentValue = false, Callback = function(V)
	toggles.xray = V
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
			if V then
				if not xrayParts[v] then xrayParts[v] = v.Transparency end
				v.Transparency = 0.6
			else
				if xrayParts[v] ~= nil then v.Transparency = xrayParts[v]; xrayParts[v] = nil end
			end
		end
	end
end })
VisualsTab:CreateToggle({ Name = "Fullbright", CurrentValue = false, Callback = function(V)
	if V then
		Lighting.Brightness = 2; Lighting.ClockTime = 12
		Lighting.GlobalShadows = false; Lighting.Ambient = Color3.new(1,1,1)
	else
		Lighting.Brightness = origLight.Brightness; Lighting.ClockTime = origLight.ClockTime
		Lighting.GlobalShadows = origLight.GlobalShadows; Lighting.Ambient = origLight.Ambient
	end
end })

------------------------------------------------
-- ITEMS TAB
------------------------------------------------
ItemTab:CreateToggle({ Name = "TP Tool", CurrentValue = false, Callback = function(V)
	toggles.tptool = V
	if V then
		tpTool = Instance.new("Tool"); tpTool.Name = "Click TP"; tpTool.RequiresHandle = false
		tpTool.Parent = player.Backpack
		tpTool.Activated:Connect(function()
			local hrp = getHRP(player.Character)
			if hrp then hrp.CFrame = mouse.Hit * CFrame.new(0,3,0) end
		end)
	else
		if tpTool then tpTool:Destroy(); tpTool = nil end
	end
end })
ItemTab:CreateToggle({ Name = "Glide Tool", CurrentValue = false, Callback = function(V)
	toggles.glidetool = V
	if V then
		glideTool = createGlideTool(); glideTool.Parent = player.Backpack
	else
		if glideTool then glideTool:Destroy(); glideTool = nil end
	end
end })

------------------------------------------------
-- UTILITY TAB
------------------------------------------------
UtilityTab:CreateToggle({ Name = "Hide Room", CurrentValue = false, Callback = function(V)
	toggles.hide = V
	local hrp = getHRP(player.Character)
	if not hrp then return end
	if V then
		preCloudPos = hrp.CFrame
		hrp.CFrame = spawnRoom() * CFrame.new(0,5,0)
	else
		if roomFolder then roomFolder:Destroy(); roomFolder = nil end
		if preCloudPos then hrp.CFrame = preCloudPos end
	end
end })
UtilityTab:CreateToggle({ Name = "Auto Hide (< 30% HP)", CurrentValue = false, Callback = function(V) toggles.autoHide = V end })
UtilityTab:CreateToggle({ Name = "Instant Interact", CurrentValue = false, Callback = function(V) toggles.instantInteract = V end })
UtilityTab:CreateButton({ Name = "Save Position", Callback = function()
	local hrp = getHRP(player.Character)
	if hrp then savedLocation = hrp.CFrame end
end })
UtilityTab:CreateButton({ Name = "Teleport to Saved", Callback = function()
	if savedLocation then
		local hrp = getHRP(player.Character)
		if hrp then hrp.CFrame = savedLocation end
	end
end })

------------------------------------------------
-- SETTINGS TAB
------------------------------------------------
SettingsTab:CreateToggle({ Name = "Anti AFK", CurrentValue = false, Callback = function(V) toggles.antiAfk = V end })
SettingsTab:CreateToggle({ Name = "Anti Fling", CurrentValue = false, Callback = function(V) toggles.antifling = V end })
SettingsTab:CreateToggle({ Name = "Anti Sit", CurrentValue = false, Callback = function(V) toggles.antisit = V end })
SettingsTab:CreateToggle({ Name = "Anti Stun / Ragdoll", CurrentValue = false, Callback = function(V) toggles.antistun = V end })
SettingsTab:CreateSection("Server")
SettingsTab:CreateButton({ Name = "Smallest Server", Callback = function() ServerHop("Asc") end })
SettingsTab:CreateButton({ Name = "Biggest Server", Callback = function() ServerHop("Desc") end })
SettingsTab:CreateButton({ Name = "Rejoin", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end })

------------------------------------------------
-- CORE LOOP
------------------------------------------------
local instantRespawnConn = nil

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local hrp, hum = getHRP(char), getHum(char)
	if not hrp or not hum then return end

	if toggles.speed and hum.MoveDirection.Magnitude > 0 then
		hrp.Velocity = Vector3.new(hum.MoveDirection.X * customSpeed, hrp.Velocity.Y, hum.MoveDirection.Z * customSpeed)
	end
	if toggles.jumpHigh then hum.JumpPower = customJump end

	if toggles.spinbot then
		spinAngle = (spinAngle + 4) % 360
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
	end

	if toggles.antisit then hum.Sit = false end
	if toggles.antistun then hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end
	if toggles.antifling then hrp.RotVelocity = Vector3.new(0,0,0) end

	if toggles.untouchable then
		for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch = false end end
	else
		for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch = true end end
	end

	if toggles.bringTarget and persistentTarget and persistentTarget.Character then
		local t_hrp = getHRP(persistentTarget.Character)
		if t_hrp then t_hrp.CFrame = hrp.CFrame * CFrame.new(0,0,-3) end
	end

	if toggles.autoHide then
		local hp = (hum.Health / math.max(hum.MaxHealth,1)) * 100
		if hp < 30 and not toggles.hide then
			autoHideReturnPos = hrp.CFrame
			hrp.CFrame = spawnRoom() * CFrame.new(0,5,0)
			toggles.hide = true
		elseif hp >= 50 and toggles.hide and autoHideReturnPos then
			hrp.CFrame = autoHideReturnPos
			autoHideReturnPos = nil
			toggles.hide = false
			if roomFolder then roomFolder:Destroy(); roomFolder = nil end
		end
	end

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local ph = getHRP(p.Character)
			if ph then
				local dist = (ph.Position - hrp.Position).Magnitude
				local bring = toggles.bringAll or (toggles.bringNearby and dist < 70)
				local freeze = toggles.frozeAll or (toggles.freezeAura and dist < 35)
				if bring or freeze then
					if not playerPositions[p.UserId] then playerPositions[p.UserId] = ph.CFrame end
					ph.Anchored = true
					if bring then ph.CFrame = hrp.CFrame * CFrame.new(0,0,-5) end
				else
					if playerPositions[p.UserId] then
						ph.Anchored = false
						ph.CFrame = playerPositions[p.UserId]
						playerPositions[p.UserId] = nil
					end
				end
				if toggles.hitbox then
					ph.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
					ph.Transparency = 0.6
				else
					ph.Size = Vector3.new(2,2,1)
					ph.Transparency = 0
				end
				if toggles.esp then
					local h = p.Character:FindFirstChild("T_ESP")
					if not h then h = Instance.new("Highlight", p.Character); h.Name = "T_ESP" end
					h.Enabled = true
				elseif p.Character:FindFirstChild("T_ESP") then
					p.Character.T_ESP.Enabled = false
				end
			end
		end
	end
end)

-- Instant respawn (safe, not in Heartbeat)
player.CharacterAdded:Connect(function(char)
	if toggles.instantRespawn then
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				task.wait(0.05)
				player:LoadCharacter()
			end)
		end
	end
end)

RunService.Stepped:Connect(function()
	if toggles.noclip and player.Character then
		for _, v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end
end)

player.Idled:Connect(function()
	if toggles.antiAfk then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

UserInputService.JumpRequest:Connect(function()
	if toggles.infjump then
		local hum = getHum(player.Character)
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if toggles.instantInteract then
		pcall(function() fireproximityprompt(prompt) end)
	end
end)
