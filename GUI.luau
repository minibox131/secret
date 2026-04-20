
local Gui = Instance.new("ScreenGui")
Gui.Name = "Gui"
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = StarterGui

local Frame = Instance.new("Frame")
Frame.Parent = Gui
Frame.BackgroundTransparency = 0.5
Frame.Position = UDim2.fromScale(0.32480403780937195, 0.16805925965309143)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.fromScale(0.3814557194709778, 0.7449179887771606)
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local LocalScript = Instance.new("LocalScript")
LocalScript.Source = [[-- Modular GUI  © 2026 by quackduck1 is licensed under CC BY-SA 4.0. To view a copy of this license, visit https://creativecommons.org/licenses/by-sa/4.0/
local TermsAgree = true
-- Agree to these terms to use this script. If you do not, you may not use this script. If you do use this script, you agree to these terms.
local function consolelog(message, identifier, subid)
	if subid then
		if debug.info(2, "l") ~= nil then print(`[{identifier or "SYSTEM"}], {subid}: {message}, {debug.info(2, "l")}`) else print(`[{identifier or "SYSTEM"}], {subid}: {message}`) end
	else 
		if debug.info(2, "l") ~= nil then print(`[{identifier or "SYSTEM"}]: {message}, {debug.info(2, "l")}`) else print(`[{identifier or "SYSTEM"}]: {message}`) end
	end
end
consolelog(`Running Modular GUI V2! By @quackduck ??`, "INFO")
local Services = {}
local Aliases = {
	ts = "TweenService",
	rs = "RunService",
	ps = "Players",
	uis = "UserInputService",
	cs = "CollectionService",
	cp = "ContentProvider"
}

setmetatable(Services, {
	__index = function(_, key)
		local serviceName = Aliases[key] or key
		local ok, service = pcall(game.GetService, game, serviceName)
		if not ok then
			consolelog(`Invalid service: {tostring(key)} -> {serviceName}`, "META", "Services")
		end
		return service
	end
})

local LocalPlayerProperties = {}
setmetatable(LocalPlayerProperties, {
	__index = function(self, key)
		if Services.Players.LocalPlayer[key] then
			rawset(self, key, Services.Players.LocalPlayer[key])
			return Services.Players.LocalPlayer[key]
		end
		consolelog(`{key} is not a property of {Services.Players.LocalPlayer.Name}`, "META", "Local Player Properties")
	end
})

local ClientChangeableSettings = {
	["KeyToOpen"] = Enum.KeyCode.E,
	["BaseTransparency"] = 0.5,
	["Padding"] = 5,
	["ClonableFolder"] = script.Parent.Parent:WaitForChild("Cloneables"),
	["DropdownFolder"] = script.Parent.Parent:WaitForChild("Dropdowns"),
	["Opensize"] = script.Parent.Size,
	["AvImgLabel"] = script.Parent.AvatarImage,
	["UserTxtBox"] = script.Parent.ignore1,
	["Frame"] = script.Parent,
	["TempFolder"] = script.Parent.Parent.Temporary,
	["IgnoreNextKeyInput"] = false,
	["NotificationSound"] = 17208361335,
	["HoverPart"] = script.Parent.Hover,
	["TabButtonFrame"] = script.Parent.ButtonScrollFrame,
	["EnableBasicAntiCheat"] = true,
	["Loaded"] = false
}
local Internal = table.clone(ClientChangeableSettings)
setmetatable(ClientChangeableSettings, {
	__index = function(_, key)
		local value = Internal[key]
		if value == nil then
			consolelog(`cant read {tostring(key)}, or is not a valid setting`, "META", "Client Changeable Settings")
		end
		return value
	end,
	__newindex = function(_, key, value)
		if Internal[key] == nil then
			consolelog(`cannot write {tostring(key)}, possibly not a valid setting`, "META", "Client Changeable Settings")
			
		end
		local expectedType = typeof(Internal[key])
		if typeof(value) ~= expectedType then
			consolelog(`Wrong Data Type for {key}, expected {expectedType}, got {typeof(value)}`, "META", "Client Changeable Settings")
		end
		Internal[key] = value
	end
})

consolelog('Set up client metatables', "INFO", "SETUP")

ClientChangeableSettings.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
ClientChangeableSettings.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)

local currentTab = nil
local layoutorder = 0
local activeNotifications = {}
local NotificationStack = {}
local isAnimating = false
local isOpen = false
local debugmode = false
local baseTransparency = {}
local tabLayoutOrder = {}
local tabs = {}
local CurrentlyPlayingTabTransition = false
local currentTween = nil
local hoverActive = false

ClientChangeableSettings.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
ClientChangeableSettings.Frame.Position = UDim2.fromScale(0.5, 0.5)
if math.random(1,2) == 1 then ClientChangeableSettings.UserTxtBox.Text = `Welcome, {LocalPlayerProperties.Name}!` else ClientChangeableSettings.UserTxtBox.Text = `Hi, {LocalPlayerProperties.Name}!` end
ClientChangeableSettings.AvImgLabel.Image = `rbxthumb://type=AvatarHeadShot&id={LocalPlayerProperties.UserId}&w=420&h=420`

consolelog('Set up client variables', "INFO", "SETUP")
consolelog("Beginning to set up client functions", "INFO", "SETUP")

local function tweenHidden(v)
	if v:IsA("Frame") then
		Services.TweenService:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1
		}):Play()
	elseif v:IsA("TextLabel") then
		Services.TweenService:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()

	elseif v:IsA("ImageLabel") then
		Services.TweenService:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			ImageTransparency = 1
		}):Play()
	elseif v:IsA("UIStroke") then
		Services.TweenService:Create(v, TweenInfo.new(0.15), {
			Transparency = 1
		}):Play()
	end
end

local function hidetabselector()
	hoverActive = false
	if currentTween then
		currentTween:Pause()
	end
	local tween
	for _, v in pairs(ClientChangeableSettings.TabButtonFrame:GetChildren()) do
		if v:IsA("TextButton") then
			v.Visible = true
			tween = Services.ts:Create(v,TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),{BackgroundTransparency = 1, TextTransparency = 1})
			tween:Play()
		end
	end
	tween.Completed:Connect(function()
		currentTween = Services.ts:Create(ClientChangeableSettings.TabButtonFrame,TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),{BackgroundTransparency = 1,Position = UDim2.new(0, 0, 0, 0)})
		currentTween:Play()
	end)
end

local function opentabselector()
	hoverActive = true
	CurrentlyPlayingTabTransition = true
	if currentTween then
		currentTween:Cancel()
	end
	currentTween = Services.ts:Create(
		ClientChangeableSettings.TabButtonFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = 0.5,
			Position = UDim2.new(0, 0, -0.132, 0)
		}
	)
	currentTween:Play()
	currentTween.Completed:Connect(function()
		if not hoverActive then return end
		for _, v in pairs(ClientChangeableSettings.TabButtonFrame:GetChildren()) do
			if v:IsA("TextButton") then
				v.Visible = true
				local tween = Services.ts:Create(v,TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),{BackgroundTransparency = 0, TextTransparency = 0})
				tween:Play()
			end
		end
	end)
end

local function playaudio(id, vol)
	if not id then return end
	local a = Instance.new("Sound")
	a.Parent = ClientChangeableSettings.TempFolder
	a.SoundId = "rbxassetid://" .. tostring(id)
	if vol then
		a.Volume = vol
	end
	a:Play()
	a.Ended:Connect(function()
		a:Destroy()
	end)
end

local function tweenVisible(v)
	local base = baseTransparency[v]
	if not base then return end
	if v:IsA("Frame") then
		Services.TweenService:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base
		}):Play()
	elseif v:IsA("TextLabel") then
		Services.TweenService:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base.bg,
			TextTransparency = base.text
		}):Play()

	elseif v:IsA("ImageLabel") then
		Services.TweenService:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base.bg,
			ImageTransparency = base.image
		}):Play()
	elseif v:IsA("UIStroke") then
		Services.TweenService:Create(v, TweenInfo.new(0.3), {
			Transparency = base.bg
		}):Play()
	end
end

function tweentransparency(tweento)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
	local tween = Services.ts:Create(ClientChangeableSettings.Frame, tweenInfo, {BackgroundTransparency = tweento})
	tween:Play()
end

function opengui(load)
	if isAnimating or isOpen then
		return
	end
	isAnimating = true
	isOpen = true
	if load then
		ClientChangeableSettings.Frame.Visible = false
		tweentransparency(ClientChangeableSettings.BaseTransparency)
		ClientChangeableSettings.Frame.Size = UDim2.new(0, 0, ClientChangeableSettings.Opensize.Y.Scale, ClientChangeableSettings.Opensize.Y.Offset)
		ClientChangeableSettings.Frame.Size = UDim2.new(ClientChangeableSettings.Opensize.X.Scale,ClientChangeableSettings.Opensize.X.Offset,ClientChangeableSettings.Opensize.Y.Scale,ClientChangeableSettings.Opensize.Y.Offset)
		ClientChangeableSettings.Frame.Size = ClientChangeableSettings.Opensize 
		for _, v in pairs(ClientChangeableSettings.Frame:GetChildren()) do
			tweenVisible(v)
		end
		ClientChangeableSettings.Frame.ignore.UIStroke.Transparency = 0
		isAnimating = false
	else
		ClientChangeableSettings.Frame.Visible = true
		tweentransparency(ClientChangeableSettings.BaseTransparency)
		ClientChangeableSettings.Frame.Size = UDim2.new(0, 0, ClientChangeableSettings.Opensize.Y.Scale, ClientChangeableSettings.Opensize.Y.Offset)
		local size = ClientChangeableSettings.Opensize
		local tweenX = Services.ts:Create(
			ClientChangeableSettings.Frame,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Size = UDim2.new(size.X.Scale,size.X.Offset,size.Y.Scale,size.Y.Offset)}
		)
		tweenX:Play()
		tweenX.Completed:Connect(function()
			Services.ts:Create(
				ClientChangeableSettings.Frame,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = ClientChangeableSettings.Opensize }
			):Play()
			for _, v in pairs(ClientChangeableSettings.Frame:GetChildren()) do
				tweenVisible(v)
			end
			local twen = Services.ts:Create(ClientChangeableSettings.Frame.ignore.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 0})
			twen:Play()
			twen.Completed:Wait()
			isAnimating = false
		end)
	end
end	

function closegui(load)
	if isAnimating or not isOpen then
		return
	end
	isAnimating = true
	isOpen = false
	if currentTab ~= nil then
		currentTab.Visible = false
		currentTab = nil
	end
	if load then
		ClientChangeableSettings.Frame.ignore.UIStroke.Transparency = 1
		for _, v in pairs(ClientChangeableSettings.Frame:WaitForChild("ButtonScrollFrame"):GetChildren()) do
			if v:IsA("TextButton") then
				v.Transparency = 1
			end
		end
		for _, v in pairs(ClientChangeableSettings.Frame:GetChildren()) do
			tweenHidden(v)
		end
		ClientChangeableSettings.Frame.Size = UDim2.new(ClientChangeableSettings.Opensize.X.Scale,ClientChangeableSettings.Opensize.X.Offset,0, 0)
		ClientChangeableSettings.Frame.Size = UDim2.new(0, 0, 0, 0)
		ClientChangeableSettings.Frame.Visible = false
		isAnimating = false
	else
		for _,v in pairs(ClientChangeableSettings.DropdownFolder:GetChildren()) do
			if v:IsA("Frame") then
				v.Visible = false
			end
		end
		local twen = Services.ts:Create(ClientChangeableSettings.Frame.ignore.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1})
		twen:Play()
		twen:Play()
		twen.Completed:Wait()
		local tweenY = Services.ts:Create(ClientChangeableSettings.Frame,TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),{Size = UDim2.new(ClientChangeableSettings.Opensize.X.Scale,ClientChangeableSettings.Opensize.X.Offset,0, 0)})
	
		tweenY:Play()
		tweenY.Completed:Wait()
		local tweenX = Services.ts:Create(
			ClientChangeableSettings.Frame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 0, 0, 0) }
		)
	
		tweenX:Play()
		tweenX.Completed:Wait()
		ClientChangeableSettings.Frame.Visible = false
		isAnimating = false
	end
end

function addtab(name, transparency, txtcolor, btncolor, menucolor)
	local button = Instance.new("TextButton")
	local uic = Instance.new("UICorner")
	local frame = ClientChangeableSettings.ClonableFolder:WaitForChild("TabTemplate"):Clone()

	-- Configure Frame
	frame.Name = name
	frame.BackgroundColor3 = menucolor or Color3.new(1,1,1)
	frame.BackgroundTransparency = transparency
	frame.Size = UDim2.new(0.94, 0,1, 0)
	frame.Position = UDim2.new(0.03, 0,0, 50)
	frame.ScrollBarImageTransparency = 1
	frame.ScrollBarThickness = 3
	frame.Visible = false


	-- Configure Button
	button.Name = name
	button.Text = name
	button.Size = UDim2.new(0, 54, 0, 54)
	button.BackgroundTransparency = transparency
	button.TextScaled = true
	button.TextColor3 = txtcolor or Color3.new(0,0,0)
	button.BackgroundColor3 = btncolor or Color3.new(1,1,1)
	uic.Parent = button

	-- Logic
	button.Activated:Connect(function()
		if currentTab and currentTab ~= frame then
			currentTab.Visible = false
		end
		if currentTab == frame then
			frame.Visible = false
			currentTab = nil
		else
			frame.Visible = true
			currentTab = frame
		end
	end)

	-- Final Parenting
	frame.Parent = script.Parent:WaitForChild("TabContainer")
	button.Parent = script.Parent:WaitForChild("ButtonScrollFrame")
	table.insert(tabs, frame.Name)
	if ClientChangeableSettings.Loaded == true then
		button.TextTransparency = 1
		button.BackgroundTransparency = 1
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = button.Position + UDim2.new(0, button.Size.X.Offset/2, 0, button.Size.Y.Offset/2)
		button.Size = UDim2.new(0, 0, 0, 0)
		opentabselector()
		playaudio(ClientChangeableSettings.NotificationSound)
		task.wait(0.5)
		local t = Services.ts:Create(button,TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Size = UDim2.new(0, 54, 0, 54),TextTransparency = 0,BackgroundTransparency = transparency})
		t:Play()
		t.Completed:Connect(function()
			hidetabselector()
		end)
	end
	
	return button
end

function addtotab(tab, instanceType, sizeX, sizeY, uic)
	tabLayoutOrder[tab] = tabLayoutOrder[tab] or 1
	local instance = Instance.new(instanceType)
	if uic then
		local corner = Instance.new("UICorner")
		corner.Parent = instance
	end
	instance.Size = UDim2.new(0, sizeX, 0, sizeY)
	instance.LayoutOrder = tabLayoutOrder[tab]
	local tabFrame = script.Parent:WaitForChild("TabContainer"):WaitForChild(tab)
	instance.Parent = tabFrame
	tabLayoutOrder[tab] += 1
	return instance
end

function addstylizedobject(tab, instanceType, style, title, strokecolor)
	tabLayoutOrder[tab] = tabLayoutOrder[tab] or 1
	local tabFrame = script.Parent:WaitForChild("TabContainer"):WaitForChild(tab)
	if not tabFrame then consolelog(`{tab} is not a valid tab`, "FUNCTION", "addstylizedobject") return end
	if style ~= "Default" then consolelog(`{style} is not a valid style`, "FUNCTION", "addstylizedobject") return end
	local templateMap = {
		TextBox = "DefaultStyledTextBox",
		TextButton = "DefaultStyledTextButton",
		ImageLabel = "DefaultStyledImageLabel",
		TextLabel = "DefaultStyledTextLabel",
		Seperator = "DefaultStyledSeperator"
	}
	local templateName = templateMap[instanceType]
	if not templateName then consolelog(`{templateMap} is not a instance type for style '{style}'`, "FUNCTION", "addstylizedobject") return end
	local template = ClientChangeableSettings.ClonableFolder:FindFirstChild(templateName)
	local obj = template:Clone()
	if obj:FindFirstChild("Title") and title then
		obj.Title.Text = title
	end
	if obj:FindFirstChild("UIStroke") then
		obj.UIStroke.Color = strokecolor or Color3.new(0,0,0)
	end
	obj.Visible = true
	obj.LayoutOrder = tabLayoutOrder[tab]
	obj.Parent = tabFrame
	tabLayoutOrder[tab] += 1
	return obj:FindFirstChild(instanceType) or obj
end

function notify(header, headercolor, body, bodycolor, length)
	local notification = ClientChangeableSettings.ClonableFolder:FindFirstChild("Notification"):Clone()
	notification.Parent = ClientChangeableSettings.TempFolder
	notification.Header.Text = header
	notification.Header.TextColor3 = headercolor or Color3.new(0, 0, 0)
	notification.Body.Text = body
	notification.Body.TextColor3 = bodycolor or Color3.new(0, 0, 0)
	notification.ZIndex = 1000
	notification.AnchorPoint = Vector2.new(1, 1)
	notification.Position = UDim2.new(1.5, 0, 1, -20)
	notification.Visible = true
	playaudio(ClientChangeableSettings.NotificationSound)
	table.insert(activeNotifications, 1, notification)
	for i, notif in ipairs(activeNotifications) do
		local offset = (i - 1) * (notif.Size.Y.Offset + ClientChangeableSettings.Padding) + 20
		Services.ts:Create(notif, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 1, -offset)}):Play()
	end
	Services.ts:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, notification.Position.Y.Scale, notification.Position.Y.Offset)}):Play()
	task.delay(length or 3, function()
		local hideTween = Services.ts:Create(notification, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1.5, 0, notification.Position.Y.Scale, notification.Position.Y.Offset)})
		hideTween:Play()
		hideTween.Completed:Wait()
		local index = table.find(activeNotifications, notification)
		if index then
			table.remove(activeNotifications, index)
		end
		for i, notif in ipairs(activeNotifications) do
			local offset = (i - 1) * (notif.Size.Y.Offset + ClientChangeableSettings.Padding) + 20
			Services.ts:Create(notif, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 1, -offset)}):Play()
		end
		notification:Destroy()
	end)
end

local function ReflowStack()
	local yOffset = 0
	for _, notif in ipairs(NotificationStack) do
		if notif and notif.Parent then
			local body = notif.Body
			local height = body.AbsoluteSize.Y
			local targetPos = UDim2.new(0.5,0,0,yOffset)
			Services.ts:Create(notif,TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{ Position = targetPos }):Play()
			yOffset += height + ClientChangeableSettings.Padding
		end
	end
end

function CenterNotify(header, headercolor, body, bodycolor, length)
	local notification = ClientChangeableSettings.ClonableFolder.TopCenterNotfication:Clone()
	playaudio(ClientChangeableSettings.NotificationSound)
	notification.Parent = ClientChangeableSettings.TempFolder
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.Position = UDim2.new(0.5, 0, 0, 0)
	table.insert(NotificationStack, notification)
	notification.Body.Header.Text = header
	notification.Body.Header.TextColor3 = headercolor or Color3.new(0, 0, 0)
	notification.Body.Body.Text = body
	notification.Body.Body.TextColor3 = bodycolor or Color3.new(0, 0, 0)
	notification.ZIndex = 69420
	local dot = notification.Dot
	local bodyFrame = notification.Body
	bodyFrame.Visible = false
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.Body.TextTransparency = 1
	bodyFrame.Header.TextTransparency = 1
	ReflowStack()
	local dotFinalPos = dot.Position
	local dotFinalSize = dot.Size
	local bodyFinalSize = bodyFrame.Size
	dot.AnchorPoint = Vector2.new(0.5, -0.1)
	dot.Position = UDim2.new(0.5, 0, -0.8, 0)
	dot.Visible = true
	bodyFrame.Visible = false
	local tweenIn = Services.ts:Create(dot,TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Position = dotFinalPos})
	tweenIn:Play()
	tweenIn.Completed:Wait()
	bodyFrame.Visible = true
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.Body.TextTransparency = 1
	bodyFrame.Header.TextTransparency = 1
	local expand = Services.ts:Create(dot,TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Size = bodyFinalSize})
	expand:Play()
	expand.Completed:Wait()
	dot.Visible = false
	bodyFrame.BackgroundTransparency = 0.5
	Services.ts:Create(bodyFrame.Body,TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{TextTransparency = 0}):Play()
	Services.ts:Create(bodyFrame.Header,TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{ TextTransparency = 0 }):Play()
	task.wait(length or 3)
	Services.ts:Create(bodyFrame.Body,TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),{ TextTransparency = 1 }):Play()
	local textOut = Services.ts:Create(bodyFrame.Header,TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),{ TextTransparency = 1 })
	textOut:Play()
	textOut.Completed:Wait()
	dot.Visible = true
	bodyFrame.Visible = false
	dot.Size = bodyFinalSize
	local collapse = Services.ts:Create(dot,TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),{ Size = dotFinalSize })
	collapse:Play()
	collapse.Completed:Wait()
	local exitTween = Services.ts:Create(dot,TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),{ Position = UDim2.new(0.5, 0, -0.9, 0) })
	exitTween:Play()
	exitTween.Completed:Wait()
	for i, v in ipairs(NotificationStack) do
		if v == notification then
			table.remove(NotificationStack, i)
			break
		end
	end
	notification:Destroy()
	ReflowStack()
end

function preload()
	for _, v in pairs(ClientChangeableSettings.Frame:GetDescendants()) do
		if v:IsA("Frame") then
			baseTransparency[v] = v.BackgroundTransparency
		elseif v:IsA("TextLabel") then
			baseTransparency[v] = {
				bg = v.BackgroundTransparency,
				text = v.TextTransparency
			}
		elseif v:IsA("ImageLabel") then
			baseTransparency[v] = {
				bg = v.BackgroundTransparency,
				image = v.ImageTransparency
			}
		elseif v:IsA("UIStroke") then
			baseTransparency[v] = {
				bg = v.Transparency
			}
		end
	end
	
	for _, v in pairs(ClientChangeableSettings.TabButtonFrame:GetChildren()) do
		if v:IsA("TextButton") then
			v.BackgroundTransparency = 1
			v.TextTransparency = 1
			v.Visible = false
		end
	end
	opengui(true)
	closegui(true)
	consolelog("Client setup complete!", "INFO", "SETUP")
	CenterNotify("GUI", Color3.new(0,0,0), "GUI setup complete!", Color3.new(0,0,0), 3)
	ClientChangeableSettings.Loaded = true
end

function adddropdown(parent, name, title, style, tbl, preset)
	if style ~= "Default" then return end
	if parent:IsA("TextButton") then
		local instance = ClientChangeableSettings.ClonableFolder:WaitForChild("DefaultStyledDropDown"):Clone()
		instance.Name = name
		instance.Parent = ClientChangeableSettings.DropdownFolder
		instance.ZIndex = 4000
		instance.Visible = false
		instance.Title.Text = title
		for _, entry in pairs(tbl) do
			if not entry.Type then
				consolelog("Missing Type in dropdown entry", "ERROR", "AddDropDown")
				break
			end
			local template = instance.DropdownInstances:FindFirstChild(entry.Type)
			if not template then
				consolelog(entry.Type .. " is not supported", "WARN", "AddDropDown")
				break
			end
			local d = template:Clone()
			d.Parent = instance.ScrollingFrame
			d.Visible = true
			if entry.Properties then
				for prop, val in pairs(entry.Properties) do
					local ok, no = pcall(function()
						d[prop] = val
					end)
					if no then
						consolelog(prop .. " invalid for " .. d.Name, "ERROR", "AddDropDown")
					end
				end
			end
		end
		if preset == 1 then
			for _, v in pairs(Services.ps:GetChildren()) do
				local clone = instance.DropdownInstances.Textbutton:Clone()
				clone.Text = v.Name
				clone.Visible = true
				clone.Parent = instance.ScrollingFrame
				clone.Activated:Connect(function()
					ClientChangeableSettings.DropdownFolder.DropDownButtonFired:Fire(instance, name, v.Name)
				end)
			end
		end
		parent.Activated:Connect(function()
			local mousePos = Services.uis:GetMouseLocation()
			local inset = Services.GuiService:GetGuiInset()
			local x = mousePos.X - inset.X
			local y = mousePos.Y - inset.Y
			instance.Position = UDim2.fromOffset(x, y)
			instance.Visible = not instance.Visible
		end)
	end
end

task.spawn(function()
	while ClientChangeableSettings.EnableBasicAntiCheat do
		pcall(function()
			if typeof(identifyexecutor) == "function" then
				local name, version = identifyexecutor()
				if name ~= nil then
					consolelog(`{LocalPlayerProperties.Name} is using {name}, {version}`, "ANTICHEAT", "UNC DETECTOR")
					Services.ps.LocalPlayer:Kick("Exploiting")
				end
			end
		end)
		task.wait(10)
	end
end)
if ClientChangeableSettings.EnableBasicAntiCheat then local t = Instance.new("RemoteEvent") t.Name = "GiveAdmin" t.Parent = Services.rs t.OnClientEvent:Connect(function() Services.ps.LocalPlayer:Kick("nice try bud") end) end

consolelog("Set up all client functions!", "INFO", "SETUP")
consolelog("Adding System Events", "INFO", "SETUP")

Services.rs.RenderStepped:Connect(function()
	local t = tick() * 0.05
	local h1 = (t % 1)
	local h2 = ((t + 0.33) % 1)
	local h3 = ((t + 0.66) % 1)

	script.Parent.ignore.UIStroke.UIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(h2, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(h3, 1, 1)),
	})
end)

Services.uis.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if ClientChangeableSettings.IgnoreNextKeyInput then return end
	if input.KeyCode == ClientChangeableSettings.KeyToOpen then
		if ClientChangeableSettings.Frame.Visible == false then
			opengui()
		else
			closegui()
		end
	end
end)
ClientChangeableSettings.HoverPart.MouseEnter:Connect(function() opentabselector() end)


ClientChangeableSettings.HoverPart.MouseLeave:Connect(function() hidetabselector() end)
---------- Documentation -----------

-- // Functions // --
-- opengui(load?) -- Opens the GUI, if you provide true for load, it'll silently open the gui immeditely and with the central frame visibility set to false
-- closegui(load?) -- Closes the GUI, if you provide true for load, it'll close the gui immeditely
-- preload() -- Preloads the GUI aswell as transitions, isnt required but recommended as it'll load stuff in
-- addtab(name, transparency, txtcolor, btncolor, menucolor) -- creates a tab with the parameters specified, as of now returns the tab's button
-- addtotab(tab, instanceType, sizeX, sizeY, uic) -- adds a generic instance to the tab specified and returns it, uic is a bool for a UICorner
-- addstylizedobject(tab, instanceType, style, title, strokecolor) --  adds a stylized object to the tab specified, returns the instance specified
-- notify(header, headercolor, body, bodycolor, length) -- a regular notification that pops up in the bottom right of the screen
-- CenterNotify(header, headercolor, body, bodycolor, length) -- a notification that pops up in the top center of the screen
-- consolelog(message, identifier, subid?) -- provides a clean way to log things to the console (ex: '[identifier] subid: oh no my table broke')
-- adddropdown() - wip
-- Any other functions are internal functions and are not meant to be used!

-- // Variables // --
-- Services: a metatable for services
-- ClientChangeableSettings: a metatable for client changeable settings
-- LocalPlayerProperties: a metatable for local player properties
-- any random tables and bools are things remaining from v1 that i refuse to redo and will be redone for v3

-- // ClientChangeableSettings // --
-- KeyToOpen: Enum.KeyCode (Keybind to open the GUI)
-- Frame: Central frame which most of the GUI is contained in
-- IgnoreNextKeyInput: Bool (If the key input should be ignored)
-- NotificationSound: Sound ID (Sound to play for notifications)
-- padding: the padding amount used by notifications
-- Rest are used for setting up/other stuff, but they are still changeable
-- note: you can NOT add indexes to this when running, they can only be set in during scripting!

-- // Services // --
-- its a simple service handler, examples below
-- Services.CollectionService
-- Services.cs (only if you register a valid alias in the alias table)

-- // LocalPlayerProperties // --
-- simple local player property handler, index it with any local player property and it shall return

-- // Examples // --
-- adddropdown() table
-- 	{
--		Type = "TextBox",
--		Properties = {
--			Text = "Hello",
--			PlaceholderText = "Type here..."
--		}
--	},
--	{
--		Type = "TextLabel",
--		Properties = {
--			Text = "Label"
--		}
--	}
--}

---------- SET UP -----------

consolelog("Setting up client parameters and customized UI", "INFO", "SETUP")
local testval = "regular"
addtab("Settings", 0.5, Color3.new(0, 0, 0), Color3.new(0.356863, 0.356863, 0.356863), Color3.new(0.356863, 0.356863, 0.356863))
local Keybind = addstylizedobject("Settings", "TextButton", "Default", "GUI Keybind", Color3.new(0,0,0))
Keybind.Text = `Press me to change, Current Keybind: {string.sub(tostring(ClientChangeableSettings.KeyToOpen),14)}`
local SoundID = addstylizedobject("Settings", "TextBox", "Default", "Notification Sound ID", Color3.new(0,0,0))
SoundID.PlaceholderText = `Current Sound ID: {ClientChangeableSettings.NotificationSound}`
local Noti = addstylizedobject("Settings", "TextButton", "Default", "Notify Test", Color3.new(0,0,0))
Noti.Text = `Current Mode: {testval}`
local dpt = addstylizedobject("Settings", "TextButton", "Default", "Drop Down Test", Color3.new(0,0,0))
dpt.Text = "Selected User: "
local servertest = addstylizedobject("Settings", "TextLabel", "Default", "Server Test", Color3.new(0,0,0))
local r = addstylizedobject("Settings", "TextButton", "Default", "Server Test", Color3.new(0,0,0))
r.Text = `click`
--------- EVENTS -----------

consolelog("Setting up client events", "INFO", "SETUP")

Keybind.Activated:Connect(function()
	Keybind.Text = "Setting keybind, press any key..."
	local conn
	conn = Services.uis.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		ClientChangeableSettings.IgnoreNextKeyInput = true
		if input.UserInputType == Enum.UserInputType.Keyboard then
			ClientChangeableSettings.KeyToOpen = input.KeyCode
			Keybind.Text = `Press me to change, Current Keybind: {string.sub(tostring(ClientChangeableSettings.KeyToOpen),14)}`
			conn:Disconnect()
			CenterNotify("Settings", Color3.new(0,0,0), `Keybind to open GUI has been changed! New keybind is '{string.sub(tostring(ClientChangeableSettings.KeyToOpen),14)}'`, Color3.new(0,0,0), 3)
			ClientChangeableSettings.IgnoreNextKeyInput = false
		end
	end)
end)

SoundID.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	local id = tonumber(SoundID.Text)
	if not id then SoundID.Text = `Not a valid ID!` return end
	local sucess = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = id
		Services.cp:PreloadAsync({sound})
	end)
	if sucess then
		ClientChangeableSettings.NotificationSound = id
		SoundID.PlaceholderText = `Current Sound ID: {ClientChangeableSettings.NotificationSound}`
		CenterNotify("Settings", Color3.new(0,0,0), `Notification sound has been changed, it is now '{id}'`, Color3.new(0,0,0), 3)
	else
		SoundID.Text = `Failed to load sound!`
	end
end)

Noti.Activated:Connect(function()
	if testval == "regular" then
		testval = "center"
		notify("abc", Color3.new(0,0,0), "abc", Color3.new(0,0,0), 3)
		Noti.Text = `Current Mode: {testval}`
	else
		testval = "regular"
		CenterNotify("abc", Color3.new(0,0,0), "abc", Color3.new(0,0,0), 3)
		Noti.Text = `Current Mode: {testval}`
	end
end)

dpt.Activated:Connect(function()
	addtab("NIGGET", 0.5, Color3.new(0, 0, 0), Color3.new(0.356863, 0.356863, 0.356863), Color3.new(0.356863, 0.356863, 0.356863))
end)

r.Activated:Connect(function()
	servertest.Title.Text = Services.ReplicatedStorage:WaitForChild("GetData"):InvokeServer("test")
end)

if not TermsAgree then consolelog("You must agree to the terms to use this", "COPYRIGHT", "CC-BY-SA 4.0") script.Parent.Parent:Destroy() else preload() end]]
LocalScript.Parent = Frame

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = Frame

local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame
UICorner.CornerRadius = UDim.new(0, 3)

local ignore = Instance.new("TextLabel")
ignore.TextWrapped = true
ignore.Parent = Frame
ignore.TextStrokeTransparency = 1.0399999618530273
ignore.ZIndex = 16
ignore.TextSize = 49
ignore.Size = UDim2.fromScale(0.4519908130168915, 0.0575568825006485)
ignore.RichText = true
ignore.TextColor3 = Color3.fromRGB(0, 0, 0)
ignore.BorderColor3 = Color3.fromRGB(0, 0, 0)
ignore.Text = "Modular Gui V2"
ignore.Font = Enum.Font.FredokaOne
ignore.BackgroundTransparency = 1
ignore.Position = UDim2.fromScale(0.4235084354877472, 0.01487597357481718)
ignore.Name = "ignore"
ignore.BorderSizePixel = 0
ignore.TextScaled = true
ignore.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.600000023841858
UIStroke.Transparency = 1
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Parent = ignore
UIStroke.LineJoinMode = Enum.LineJoinMode.Miter

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = 0 1 1 1 0 1 1 0.431373 0.8 0 
UIGradient.Parent = UIStroke

local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
UITextSizeConstraint.MaxTextSize = 34
UITextSizeConstraint.Parent = ignore

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = ignore
UIAspectRatioConstraint.AspectRatio = 7.852941036224365

local Frame = Instance.new("Frame")
Frame.Parent = Frame
Frame.Size = UDim2.fromScale(0.3519183099269867, 0.07480388879776001)
Frame.BackgroundTransparency = 0.699999988079071
Frame.Position = UDim2.fromScale(0.018744276836514473, 0.006785012315958738)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.ZIndex = 16
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Color3.fromRGB(156, 156, 156)

local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = Frame
UIAspectRatioConstraint.AspectRatio = 4.704545497894287

local TabContainer = Instance.new("Folder")
TabContainer.Name = "TabContainer"
TabContainer.Parent = Frame

local ButtonScrollFrame = Instance.new("ScrollingFrame")
ButtonScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
ButtonScrollFrame.Active = true
ButtonScrollFrame.ScrollBarImageTransparency = 1
ButtonScrollFrame.ScrollBarThickness = 7
ButtonScrollFrame.Parent = Frame
ButtonScrollFrame.Name = "ButtonScrollFrame"
ButtonScrollFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ButtonScrollFrame.Size = UDim2.fromScale(1, 0.11849946528673172)
ButtonScrollFrame.BackgroundTransparency = 1
ButtonScrollFrame.ScrollingDirection = Enum.ScrollingDirection.X
ButtonScrollFrame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
ButtonScrollFrame.ZIndex = 5
ButtonScrollFrame.BorderSizePixel = 0
ButtonScrollFrame.CanvasSize = UDim2.fromScale(2, 2)

local UICorner = Instance.new("UICorner")
UICorner.Parent = ButtonScrollFrame
UICorner.CornerRadius = UDim.new(0, 3)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ButtonScrollFrame
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.FillDirection = Enum.FillDirection.Horizontal

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 5)
UIPadding.PaddingBottom = UDim.new(0, 5)
UIPadding.Parent = ButtonScrollFrame
UIPadding.PaddingRight = UDim.new(0, 5)
UIPadding.PaddingLeft = UDim.new(0, 5)

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = ButtonScrollFrame
UIAspectRatioConstraint.AspectRatio = 8.438857078552246

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
AvatarImage.Parent = Frame
AvatarImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
AvatarImage.Name = "AvatarImage"
AvatarImage.Position = UDim2.fromScale(0.03748844936490059, 0.006298376712948084)
AvatarImage.Size = UDim2.fromScale(0.07448537647724152, 0.07448537647724152)
AvatarImage.ZIndex = 16
AvatarImage.BorderSizePixel = 0
AvatarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UICorner = Instance.new("UICorner")
UICorner.Parent = AvatarImage

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = AvatarImage

local ignore1 = Instance.new("TextLabel")
ignore1.Parent = Frame
ignore1.TextWrapped = true
ignore1.Name = "ignore1"
ignore1.TextColor3 = Color3.fromRGB(0, 0, 0)
ignore1.BorderColor3 = Color3.fromRGB(0, 0, 0)
ignore1.Text = "Username"
ignore1.TextSize = 14
ignore1.TextStrokeTransparency = 1.0399999618530273
ignore1.Size = UDim2.fromScale(0.22853468358516693, 0.06432828307151794)
ignore1.Font = Enum.Font.SourceSans
ignore1.BackgroundTransparency = 1
ignore1.Position = UDim2.fromScale(0.12542219460010529, 0.010903296060860157)
ignore1.BorderSizePixel = 0
ignore1.ZIndex = 16
ignore1.TextScaled = true
ignore1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
UITextSizeConstraint.MaxTextSize = 38
UITextSizeConstraint.Parent = ignore1

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = ignore1
UIAspectRatioConstraint.AspectRatio = 3.5526316165924072

local Hover = Instance.new("Frame")
Hover.Parent = Frame
Hover.Name = "Hover"
Hover.BackgroundTransparency = 1
Hover.Position = UDim2.fromScale(-0.0016935652820393443, -0.17435887455940247)
Hover.BorderColor3 = Color3.fromRGB(0, 0, 0)
Hover.Size = UDim2.fromScale(1.0025514364242554, 0.28800147771835327)
Hover.BorderSizePixel = 0
Hover.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = Hover
UIAspectRatioConstraint.AspectRatio = 3.4810633659362793

local Temporary = Instance.new("Folder")
Temporary.Name = "Temporary"
Temporary.Parent = Gui

local Sound = Instance.new("Sound")
Sound.SoundId = "rbxassetid://17208361335"
Sound.Parent = Temporary
Sound.RollOffMode = Enum.RollOffMode.InverseTapered

local Dropdowns = Instance.new("Folder")
Dropdowns.Name = "Dropdowns"
Dropdowns.Parent = Gui

local DropDownButtonFired = Instance.new("BindableEvent")
DropDownButtonFired.Name = "DropDownButtonFired"
DropDownButtonFired.Parent = Dropdowns

local Cloneables = Instance.new("Folder")
Cloneables.Name = "Cloneables"
Cloneables.Parent = Gui

local Notification = Instance.new("Frame")
Notification.Visible = false
Notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
Notification.Parent = Cloneables
Notification.Name = "Notification"
Notification.BackgroundTransparency = 0.5
Notification.Position = UDim2.fromScale(0.8683329820632935, 0.8737327456474304)
Notification.Size = UDim2.fromOffset(200, 100)
Notification.ZIndex = 67676767
Notification.BorderSizePixel = 0
Notification.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local UICorner = Instance.new("UICorner")
UICorner.Parent = Notification

local Header = Instance.new("TextLabel")
Header.TextWrapped = true
Header.TextColor3 = Color3.fromRGB(0, 0, 0)
Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
Header.Text = "Header"
Header.Parent = Notification
Header.Name = "Header"
Header.Size = UDim2.fromOffset(171, 15)
Header.Font = Enum.Font.SourceSans
Header.BackgroundTransparency = 1
Header.Position = UDim2.fromScale(0.07000000029802322, 0)
Header.BorderSizePixel = 0
Header.TextSize = 14
Header.TextScaled = true
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = Notification
UIAspectRatioConstraint.AspectRatio = 2

local Body = Instance.new("TextLabel")
Body.TextWrapped = true
Body.TextColor3 = Color3.fromRGB(0, 0, 0)
Body.BorderColor3 = Color3.fromRGB(0, 0, 0)
Body.Text = "Body"
Body.Parent = Notification
Body.Name = "Body"
Body.Size = UDim2.fromOffset(200, 63)
Body.Font = Enum.Font.SourceSans
Body.BackgroundTransparency = 1
Body.Position = UDim2.fromScale(0, 0.25)
Body.BorderSizePixel = 0
Body.TextSize = 14
Body.TextScaled = true
Body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local TEST_TAB = Instance.new("ScrollingFrame")
TEST_TAB.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
TEST_TAB.Active = true
TEST_TAB.BorderColor3 = Color3.fromRGB(0, 0, 0)
TEST_TAB.Parent = Cloneables
TEST_TAB.Visible = false
TEST_TAB.Name = "TEST_TAB"
TEST_TAB.Position = UDim2.fromScale(0.3323215842247009, 0.23960863053798676)
TEST_TAB.Size = UDim2.fromScale(0.3683841824531555, 0.651547372341156)
TEST_TAB.ScrollBarImageTransparency = 1
TEST_TAB.BorderSizePixel = 0
TEST_TAB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UICorner = Instance.new("UICorner")
UICorner.Parent = TEST_TAB

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0.009999999776482582, 0)
UIPadding.PaddingBottom = UDim.new(0.009999999776482582, 0)
UIPadding.Parent = TEST_TAB
UIPadding.PaddingRight = UDim.new(0.009999999776482582, 0)
UIPadding.PaddingLeft = UDim.new(0.009999999776482582, 0)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = TEST_TAB
UIListLayout.Padding = UDim.new(0.009999999776482582, 0)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = TEST_TAB
UIAspectRatioConstraint.AspectRatio = 1.0873056650161743

local TopCenterNotfication = Instance.new("Frame")
TopCenterNotfication.BorderColor3 = Color3.fromRGB(0, 0, 0)
TopCenterNotfication.Parent = Cloneables
TopCenterNotfication.AnchorPoint = Vector2.new(0.5, 0)
TopCenterNotfication.Name = "TopCenterNotfication"
TopCenterNotfication.BackgroundTransparency = 1
TopCenterNotfication.Position = UDim2.fromScale(0.49966996908187866, 0)
TopCenterNotfication.Size = UDim2.fromScale(0.0330033004283905, 0.06188118830323219)
TopCenterNotfication.ZIndex = 69420
TopCenterNotfication.BorderSizePixel = 0
TopCenterNotfication.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local UICorner = Instance.new("UICorner")
UICorner.Parent = TopCenterNotfication
UICorner.CornerRadius = UDim.new(0, 70)

local Dot = Instance.new("Frame")
Dot.Visible = false
Dot.BorderColor3 = Color3.fromRGB(0, 0, 0)
Dot.AnchorPoint = Vector2.new(0.5, 0)
Dot.Parent = TopCenterNotfication
Dot.BackgroundTransparency = 0.5
Dot.Position = UDim2.fromScale(0.5096704363822937, 0.8799999952316284)
Dot.Name = "Dot"
Dot.Size = UDim2.fromScale(1.0130200386047363, 1.0018811225891113)
Dot.BorderSizePixel = 0
Dot.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local UICorner = Instance.new("UICorner")
UICorner.Parent = Dot
UICorner.CornerRadius = UDim.new(0, 4)

local Body = Instance.new("Frame")
Body.Visible = false
Body.BorderColor3 = Color3.fromRGB(0, 0, 0)
Body.Parent = TopCenterNotfication
Body.BackgroundTransparency = 0.699999988079071
Body.Position = UDim2.fromScale(-2.498112678527832, 0.8469361662864685)
Body.Name = "Body"
Body.Size = UDim2.fromOffset(300, 94)
Body.BorderSizePixel = 0
Body.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local UICorner = Instance.new("UICorner")
UICorner.Parent = Body
UICorner.CornerRadius = UDim.new(0, 4)

local Header = Instance.new("TextLabel")
Header.TextWrapped = true
Header.TextColor3 = Color3.fromRGB(0, 0, 0)
Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
Header.Text = "Title"
Header.Parent = Body
Header.Name = "Header"
Header.Size = UDim2.fromOffset(200, 14)
Header.Font = Enum.Font.SourceSans
Header.BackgroundTransparency = 1
Header.Position = UDim2.fromScale(0.1666666716337204, 0)
Header.BorderSizePixel = 0
Header.TextSize = 14
Header.TextScaled = true
Header.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local Body = Instance.new("TextLabel")
Body.TextWrapped = true
Body.TextColor3 = Color3.fromRGB(0, 0, 0)
Body.BorderColor3 = Color3.fromRGB(0, 0, 0)
Body.Parent = Body
Body.Name = "Body"
Body.Size = UDim2.fromOffset(279, 72)
Body.Font = Enum.Font.SourceSans
Body.BackgroundTransparency = 1
Body.Position = UDim2.fromScale(0.036666665226221085, 0.1489361673593521)
Body.BorderSizePixel = 0
Body.TextSize = 14
Body.TextScaled = true
Body.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local TabTemplate = Instance.new("ScrollingFrame")
TabTemplate.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
TabTemplate.Active = true
TabTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
TabTemplate.Parent = Cloneables
TabTemplate.Visible = false
TabTemplate.Name = "TabTemplate"
TabTemplate.Position = UDim2.fromScale(0.6449397802352905, 0.2648293375968933)
TabTemplate.Size = UDim2.fromScale(0.3683841824531555, 0.651547372341156)
TabTemplate.ScrollBarImageTransparency = 1
TabTemplate.BorderSizePixel = 0
TabTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UICorner = Instance.new("UICorner")
UICorner.Parent = TabTemplate

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0.009999999776482582, 0)
UIPadding.PaddingBottom = UDim.new(0.009999999776482582, 0)
UIPadding.Parent = TabTemplate
UIPadding.PaddingRight = UDim.new(0.009999999776482582, 0)
UIPadding.PaddingLeft = UDim.new(0.009999999776482582, 0)

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = TabTemplate
UIAspectRatioConstraint.AspectRatio = 1.0873056650161743

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = TabTemplate
UIListLayout.Padding = UDim.new(0.009999999776482582, 0)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local DefaultStyledTextLabel = Instance.new("Frame")
DefaultStyledTextLabel.Visible = false
DefaultStyledTextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledTextLabel.Parent = Cloneables
DefaultStyledTextLabel.BackgroundTransparency = 0.20000000298023224
DefaultStyledTextLabel.Position = UDim2.fromScale(0.0257759727537632, 0.9052843451499939)
DefaultStyledTextLabel.Name = "DefaultStyledTextLabel"
DefaultStyledTextLabel.Size = UDim2.fromOffset(526, 50)
DefaultStyledTextLabel.BorderSizePixel = 0
DefaultStyledTextLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledTextLabel
Title.Name = "Title"
Title.Size = UDim2.fromOffset(512, 50)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.01206778734922409, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledTextLabel

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledTextLabel

local DefaultStyledTextButton = Instance.new("Frame")
DefaultStyledTextButton.Visible = false
DefaultStyledTextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledTextButton.Parent = Cloneables
DefaultStyledTextButton.BackgroundTransparency = 0.20000000298023224
DefaultStyledTextButton.Position = UDim2.fromScale(0.020841946825385094, 0.403199166059494)
DefaultStyledTextButton.Name = "DefaultStyledTextButton"
DefaultStyledTextButton.Size = UDim2.fromOffset(526, 50)
DefaultStyledTextButton.BorderSizePixel = 0
DefaultStyledTextButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledTextButton

local UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledTextButton

local Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledTextButton
Title.Name = "Title"
Title.Size = UDim2.fromOffset(511, 14)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.012353933416306973, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local TextButton = Instance.new("TextButton")
TextButton.TextWrapped = true
TextButton.TextColor3 = Color3.fromRGB(184, 184, 184)
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.Parent = DefaultStyledTextButton
TextButton.Size = UDim2.fromOffset(519, 36)
TextButton.Font = Enum.Font.SourceSans
TextButton.BackgroundTransparency = 1
TextButton.Position = UDim2.fromScale(0.012353933416306973, 0.2800000011920929)
TextButton.BorderSizePixel = 0
TextButton.TextSize = 14
TextButton.TextScaled = true
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local DefaultStyledTextBox = Instance.new("Frame")
DefaultStyledTextBox.Visible = false
DefaultStyledTextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledTextBox.Parent = Cloneables
DefaultStyledTextBox.BackgroundTransparency = 0.20000000298023224
DefaultStyledTextBox.Position = UDim2.fromScale(0.025526538491249084, 0.7546548247337341)
DefaultStyledTextBox.Name = "DefaultStyledTextBox"
DefaultStyledTextBox.Size = UDim2.fromOffset(525, 50)
DefaultStyledTextBox.BorderSizePixel = 0
DefaultStyledTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledTextBox
Title.Name = "Title"
Title.Size = UDim2.fromOffset(511, 14)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.012852114625275135, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local TextBox = Instance.new("TextBox")
TextBox.TextWrapped = true
TextBox.TextColor3 = Color3.fromRGB(184, 184, 184)
TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox.Text = ""
TextBox.Parent = DefaultStyledTextBox
TextBox.Size = UDim2.fromOffset(511, 36)
TextBox.Position = UDim2.fromScale(0.012852143496274948, 0.2800000011920929)
TextBox.Font = Enum.Font.SourceSans
TextBox.BackgroundTransparency = 1
TextBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
TextBox.BorderSizePixel = 0
TextBox.TextSize = 14
TextBox.TextScaled = true
TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledTextBox

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledTextBox

local DefaultStyledImageLabel = Instance.new("Frame")
DefaultStyledImageLabel.Visible = false
DefaultStyledImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledImageLabel.Parent = Cloneables
DefaultStyledImageLabel.BackgroundTransparency = 0.20000000298023224
DefaultStyledImageLabel.Position = UDim2.fromScale(0.025526538491249084, 0.6498268246650696)
DefaultStyledImageLabel.Name = "DefaultStyledImageLabel"
DefaultStyledImageLabel.Size = UDim2.fromOffset(526, 50)
DefaultStyledImageLabel.BorderSizePixel = 0
DefaultStyledImageLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledImageLabel

local UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledImageLabel

local Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledImageLabel
Title.Name = "Title"
Title.Size = UDim2.fromOffset(528, 14)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.017949488013982773, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local ImageLabel = Instance.new("ImageLabel")
ImageLabel.Parent = DefaultStyledImageLabel
ImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
ImageLabel.BackgroundTransparency = 1
ImageLabel.Position = UDim2.fromScale(0.017949488013982773, 0.2800000011920929)
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.Size = UDim2.fromOffset(508, 36)
ImageLabel.BorderSizePixel = 0
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local DefaultStyledDropDown = Instance.new("Frame")
DefaultStyledDropDown.Visible = false
DefaultStyledDropDown.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledDropDown.Parent = Cloneables
DefaultStyledDropDown.BackgroundTransparency = 0.20000000298023224
DefaultStyledDropDown.Position = UDim2.fromScale(0.4607645869255066, 0.42370742559432983)
DefaultStyledDropDown.Name = "DefaultStyledDropDown"
DefaultStyledDropDown.Size = UDim2.fromOffset(190, 193)
DefaultStyledDropDown.BorderSizePixel = 0
DefaultStyledDropDown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledDropDown

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledDropDown

local Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledDropDown
Title.Name = "Title"
Title.Size = UDim2.fromOffset(187, 18)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.012068256735801697, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame.Active = true
ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.Position = UDim2.fromScale(0, 0.09326425194740295)
ScrollingFrame.Parent = DefaultStyledDropDown
ScrollingFrame.Size = UDim2.fromOffset(189, 165)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingFrame
UIListLayout.Padding = UDim.new(0.009999999776482582, 0)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0.004999999888241291, 0)
UIPadding.PaddingBottom = UDim.new(0.004999999888241291, 0)
UIPadding.Parent = ScrollingFrame
UIPadding.PaddingRight = UDim.new(0.004999999888241291, 0)
UIPadding.PaddingLeft = UDim.new(0.004999999888241291, 0)

local DropdownInstances = Instance.new("Folder")
DropdownInstances.Name = "DropdownInstances"
DropdownInstances.Parent = DefaultStyledDropDown

local TextBox = Instance.new("TextBox")
TextBox.Visible = false
TextBox.TextColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox.Text = ""
TextBox.Parent = DropdownInstances
TextBox.Font = Enum.Font.SourceSans
TextBox.BackgroundTransparency = 0.20000000298023224
TextBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
TextBox.Size = UDim2.fromOffset(181, 35)
TextBox.BorderSizePixel = 0
TextBox.TextSize = 14
TextBox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = TextBox

local UICorner = Instance.new("UICorner")
UICorner.Parent = TextBox

local Textbutton = Instance.new("TextButton")
Textbutton.Visible = false
Textbutton.TextColor3 = Color3.fromRGB(0, 0, 0)
Textbutton.BorderColor3 = Color3.fromRGB(0, 0, 0)
Textbutton.Parent = DropdownInstances
Textbutton.Font = Enum.Font.SourceSans
Textbutton.BackgroundTransparency = 0.20000000298023224
Textbutton.Name = "Textbutton"
Textbutton.Size = UDim2.fromOffset(181, 35)
Textbutton.BorderSizePixel = 0
Textbutton.TextSize = 14
Textbutton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

local UICorner = Instance.new("UICorner")
UICorner.Parent = Textbutton

local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = Textbutton

local DefaultStyledSeperator = Instance.new("Frame")
DefaultStyledSeperator.Visible = false
DefaultStyledSeperator.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledSeperator.Parent = Cloneables
DefaultStyledSeperator.BackgroundTransparency = 0.20000000298023224
DefaultStyledSeperator.Position = UDim2.fromScale(0.023153847083449364, 0.6155738234519958)
DefaultStyledSeperator.Name = "DefaultStyledSeperator"
DefaultStyledSeperator.Size = UDim2.fromOffset(512, 10)
DefaultStyledSeperator.BorderSizePixel = 0
DefaultStyledSeperator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledSeperator
