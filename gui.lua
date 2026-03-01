var Gui = Instance.new("ScreenGui")
Gui.Parent = Plr.PlayerGui
Gui.IgnoreGuiInset = true
Gui.Name = "Gui"
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame")
Frame.Visible = false
Frame.Parent = Gui
Frame.BackgroundTransparency = 1
Frame.Position = UDim2.fromScale(0.31693515181541443, 0.18193066120147705)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.fromScale(0.34095749258995056, 0.5910717844963074)
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

local LocalScript = Instance.new("LocalScript")
LocalScript.Source = [[local services = {
	Players = game:GetService("Players"),
	uis = game:GetService("UserInputService"),
	ts = game:GetService("TweenService"),
	cs = game:GetService("CollectionService"),
	booleans = {
		isAnimating = false,
		isOpen = false,
		debugmode = false
	},
	localplayer = {
		playerinstance = game.Players.LocalPlayer,
		userid = game.Players.LocalPlayer.UserId,
		name = game.Players.LocalPlayer.Name,
		playerimage = game.Players:GetUserThumbnailAsync(game.Players.LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
	},
	guilocals = {
		frame = script.Parent,
		OPEN_SIZE = script.parent.Size,
		imagelabel = script.Parent.AvatarImage,
		usernametextbox = script.Parent.ignore1,
		cloneables = script.Parent.Parent.Cloneables,
	},
	tables = {
		baseTransparency = {},
		tabLayoutOrder = {},
		tabs = {}
	},
	remotes = {
		kick = game.ReplicatedStorage.Remotes.KickPlayer,
		notify = game.ReplicatedStorage.Remotes.SendNotificationClient
	}
}
local basetransparency = 0.5 
local padding = 10
local currentTab = nil
local hud = require(services.localplayer.playerinstance.PlayerGui.HUD.HudModule)
local layoutorder = 0

services.guilocals.frame.AnchorPoint = Vector2.new(0.5, 0.5)
services.guilocals.frame.Position = UDim2.fromScale(0.5, 0.5)
services.guilocals.usernametextbox.Text = services.localplayer.name
services.guilocals.imagelabel.Image = services.localplayer.playerimage

local function tweenHidden(v)
	if v:IsA("Frame") then
		services.ts:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1
		}):Play()

	elseif v:IsA("TextButton") then
		services.ts:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()

	elseif v:IsA("TextLabel") then
		services.ts:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()

	elseif v:IsA("ImageLabel") then
		services.ts:Create(v, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			ImageTransparency = 1
		}):Play()
	end
end

local function tweenVisible(v)
	local base = services.tables.baseTransparency[v]
	if not base then return end

	if v:IsA("Frame") then
		services.ts:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base
		}):Play()

	elseif v:IsA("TextButton") then
		services.ts:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base.bg,
			TextTransparency = base.text
		}):Play()

	elseif v:IsA("TextLabel") then
		services.ts:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base.bg,
			TextTransparency = base.text
		}):Play()

	elseif v:IsA("ImageLabel") then
		services.ts:Create(v, TweenInfo.new(0.3), {
			BackgroundTransparency = base.bg,
			ImageTransparency = base.image
		}):Play()
	end
end

function tweentransparency(tweento)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
	local tween = services.ts:Create(services.guilocals.frame, tweenInfo, {BackgroundTransparency = tweento})
	tween:Play()
end

function opengui()
	if services.booleans[1] or services.booleans[2] then
		return
	end
	services.booleans[1] = true
	services.booleans[2] = true

	if services.booleans[3] == true then
		hud.notify("GUI Notification", Color3.new(0,0,0), "GUI opened", Color3.new(0,0,0), 5)
	end
	services.guilocals.frame.Visible = true
	tweentransparency(basetransparency)
	services.guilocals.frame.Size = UDim2.new(0, 0, services.guilocals.OPEN_SIZE.Y.Scale, services.guilocals.OPEN_SIZE.Y.Offset)
	local tweenX = services.ts:Create(
		services.guilocals.frame,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(
				services.guilocals.OPEN_SIZE.X.Scale,
				services.guilocals.OPEN_SIZE.X.Offset,
				services.guilocals.OPEN_SIZE.Y.Scale,
				services.guilocals.OPEN_SIZE.Y.Offset
			)
		}
	)
	tweenX:Play()
	tweenX.Completed:Wait()
	services.ts:Create(
		services.guilocals.frame,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = services.guilocals.OPEN_SIZE }
	):Play()

	for _, v in pairs(services.guilocals.frame:GetChildren()) do
		tweenVisible(v)
		if v:IsA("ScrollingFrame") then
			for _, btn in pairs(v:GetChildren()) do
				if btn:IsA("TextButton") then
					tweenVisible(btn)
				end
			end
		end
	end
	services.booleans[1] = false
end

function closegui()
	if services.booleans[1] or not services.booleans[2] then
		return
	end
	services.booleans[1] = true
	services.booleans[2] = false
	if currentTab ~= nil then
		currentTab.Visible = false
		currentTab = nil
	end
	if services.booleans[3] == true then
		hud.notify("GUI Notification", Color3.new(0,0,0), "GUI closed", Color3.new(0,0,0), 5)
	end

	for _, v in pairs(services.guilocals.frame:GetChildren()) do
		tweenHidden(v)
		if v:IsA("ScrollingFrame") then
			for _, btn in pairs(v:GetChildren()) do
				if btn:IsA("TextButton") then
					tweenHidden(btn)
				end
			end
		end
	end
	local tweenY = services.ts:Create(
		services.guilocals.frame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.new(
				services.guilocals.OPEN_SIZE.X.Scale,
				services.guilocals.OPEN_SIZE.X.Offset,
				0, 0
			)
		}
	)

	tweenY:Play()
	tweenY.Completed:Wait()
	local tweenX = services.ts:Create(
		services.guilocals.frame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = UDim2.new(0, 0, 0, 0) }
	)

	tweenX:Play()
	tweenX.Completed:Wait()
	services.guilocals.frame.Visible = false
	services.booleans[1] = false
end

function addtab(name, transparency, txtcolor, btncolor, menucolor)
	if services.booleans[3] == true then
		hud.notify("Tab Added", Color3.new(0,0,0), "Name: " .. name .. " | Transparency: " .. transparency .. " | Text Color: " .. tostring(txtcolor) .. " | Button Color: " .. tostring(btncolor) .. " | Menu Color: " .. tostring(menucolor) , Color3.new(0,0,0), 5)
	end
	local button = Instance.new("TextButton")
	local uic = Instance.new("UICorner")
	local frame = Instance.new("ScrollingFrame")
	local uic2 = Instance.new("UICorner")
	local sc = Instance.new("UIAspectRatioConstraint")
	local uip = Instance.new("UIPadding")
	local uilist = Instance.new("UIListLayout")
	
	-- Configure Padding
	uip.PaddingTop = UDim.new(0.01, 0)
	uip.PaddingBottom = UDim.new(0.01, 0)
	uip.PaddingLeft = UDim.new(0.01, 0)
	uip.PaddingRight = UDim.new(0.01, 0)
	
	-- Configure UIListLayout
	uilist.Padding = UDim.new(0.01, 0)
	uilist.SortOrder = Enum.SortOrder.LayoutOrder
	
	-- Configure Sc
	sc.AspectRatio = 0.919
	
	-- Configure Frame
	frame.Name = name
	frame.BackgroundColor3 = menucolor or Color3.new(1,1,1)
	frame.Size = UDim2.new(0, 400, 0, 450)
	frame.Position = UDim2.new(0.142, 0, 0.067, 0)
	frame.BackgroundTransparency = transparency
	frame.ScrollBarImageTransparency = 1
	frame.Visible = false
	uic2.Parent = frame
	uip.Parent = frame
	uilist.Parent = frame


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

		if services.booleans[3] == true then
			hud.notify(
				"Tab Toggled",
				Color3.new(0,0,0),
				"Tab: " .. frame.Name .. " | Visible: " .. tostring(frame.Visible),
				Color3.new(0,0,0),
				5
			)
		end
	end)

	-- Final Parenting
	frame.Parent = script.Parent
	button.Parent = script.Parent:WaitForChild("ScrollingFrame")
	sc.Parent = frame
	table.insert(services.tables.tabs, frame.Name)
	
	return button
end

function addtotab(tab, instanceType, sizeX, sizeY, uic)
	services.tables.tabLayoutOrder[tab] = services.tables.tabLayoutOrder[tab] or 1
	local instance = Instance.new(instanceType)
	if uic then
		local corner = Instance.new("UICorner")
		corner.Parent = instance
	end
	instance.Size = UDim2.new(0, sizeX, 0, sizeY)
	instance.LayoutOrder = services.tables.tabLayoutOrder[tab]
	local tabFrame = script.Parent:WaitForChild(tab)
	instance.Parent = tabFrame
	services.tables.tabLayoutOrder[tab] += 1
	return instance
end

function addstylizedobject(tab, instanceType, style, title, strokecolor)
	services.tables.tabLayoutOrder[tab] = services.tables.tabLayoutOrder[tab] or 1
	local tabFrame = script.Parent:FindFirstChild(tab)
	if not tabFrame then return end
	if style ~= "Default" then return end
	local templateMap = {
		TextBox = "DefaultStyledTextBox",
		TextButton = "DefaultStyledTextButton",
		ImageLabel = "DefaultStyledImageLabel",
		TextLabel = "DefaultStyledTextLabel",
		Seperator = "DefaultStyledSeperator"
	}
	local templateName = templateMap[instanceType]
	if not templateName then return end
	local template = services.guilocals.cloneables:FindFirstChild(templateName)
	if not template then return end
	local obj = template:Clone()
	if obj:FindFirstChild("Title") and title then
		obj.Title.Text = title
	end
	if obj:FindFirstChild("UIStroke") then
		obj.UIStroke.Color = strokecolor or Color3.new(0,0,0)
	end
	obj.Visible = true
	obj.LayoutOrder = services.tables.tabLayoutOrder[tab]
	obj.Parent = tabFrame
	services.tables.tabLayoutOrder[tab] += 1
	return obj:FindFirstChild(instanceType) or obj
end

---------- Documentation -----------

-- addstylizedobject(tab, instance, style, title, strokecolor)
-- adds a stylized object (instance) to the tab (tab) with the style (style), returns an instance (instance)

-- addobject(tab, instance, sizeX, sizeY, uic)
-- adds an object (instance) to the tab (tab) with the size (sizeX, sizeY), returns an instance (instance)

-- addtab(name, transparency, txtcolor, btncolor, menucolor)
-- adds a tab to the left scrolling frame, does not return anything, transparency gets applied to both the button in the scrolling frame and the tab itself
-- txt and btncolor get applied to the button, and menu color gets applied to the tab

-- notify(header, headercolor, body, bodycolor, length)																															|
-- notifies the player with this gui, does not return anything, length is optional, default is 3, header is the notification header, which can be customized with headercolor	| disabled in this script
-- same thing with body																																							| use hud.notify()

-- note: you are in charge of what your object does, not the ui, you must add an event under the EVENTS section for your object to work

---------- SET UP -----------


---------- EVENTS -----------


services.uis.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		if services.guilocals.frame.Visible == false then
			opengui()
		else
			closegui()
		end
	end
end)


for i, v in pairs(services.guilocals.frame:GetDescendants()) do
	if v:IsA("Frame") then
		services.tables.baseTransparency[v] = v.BackgroundTransparency
	elseif v:IsA("TextButton") then
		services.tables.baseTransparency[v] = {
			bg = v.BackgroundTransparency,
			text = v.TextTransparency
		}
	elseif v:IsA("TextLabel") then
		services.tables.baseTransparency[v] = {
			bg = v.BackgroundTransparency,
			text = v.TextTransparency
		}
	elseif v:IsA("ImageLabel") then
		services.tables.baseTransparency[v] = {
			bg = v.BackgroundTransparency,
			image = v.ImageTransparency
		}
	end
end
hud.notify("Admin", Color3.new(0,0,0), "Admin GUI loaded", Color3.new(0,0,0), 5)]]
LocalScript.Parent = Frame

var UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = Frame

var UICorner = Instance.new("UICorner")
UICorner.Parent = Frame

var ignore = Instance.new("TextLabel")
ignore.TextWrapped = true
ignore.Parent = Frame
ignore.TextColor3 = Color3.fromRGB(0, 0, 0)
ignore.BorderColor3 = Color3.fromRGB(0, 0, 0)
ignore.Text = "Test Gui"
ignore.Name = "ignore"
ignore.TextStrokeTransparency = 1.0399999618530273
ignore.Size = UDim2.fromOffset(200, 33)
ignore.Font = Enum.Font.Arial
ignore.BackgroundTransparency = 1
ignore.Position = UDim2.fromScale(0.33134353160858154, 0.009999999776482582)
ignore.BorderSizePixel = 0
ignore.TextSize = 14
ignore.TextScaled = true
ignore.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame.Active = true
ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
ScrollingFrame.Parent = Frame
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.Position = UDim2.fromScale(0.013645224273204803, 0.08976079523563385)
ScrollingFrame.Size = UDim2.fromOffset(66, 488)
ScrollingFrame.ScrollBarImageTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingFrame
UIListLayout.Padding = UDim.new(0.009999999776482582, 0)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

var ignore1 = Instance.new("TextLabel")
ignore1.TextWrapped = true
ignore1.TextColor3 = Color3.fromRGB(0, 0, 0)
ignore1.BorderColor3 = Color3.fromRGB(0, 0, 0)
ignore1.Text = "Username"
ignore1.Parent = Frame
ignore1.Name = "ignore1"
ignore1.Size = UDim2.fromOffset(87, 19)
ignore1.Font = Enum.Font.SourceSans
ignore1.BackgroundTransparency = 1
ignore1.Position = UDim2.fromScale(0.10354986041784286, 0.02453329600393772)
ignore1.BorderSizePixel = 0
ignore1.TextSize = 14
ignore1.TextScaled = true
ignore1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Parent = Frame
AvatarImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
AvatarImage.Name = "AvatarImage"
AvatarImage.Position = UDim2.fromScale(0.019999999552965164, 0.009999999776482582)
AvatarImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
AvatarImage.Size = UDim2.fromOffset(33, 33)
AvatarImage.BorderSizePixel = 0
AvatarImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var UICorner = Instance.new("UICorner")
UICorner.Parent = AvatarImage

var UIScale = Instance.new("UIScale")
UIScale.Parent = Gui

var Cloneables = Instance.new("Folder")
Cloneables.Name = "Cloneables"
Cloneables.Parent = Gui

var Notification = Instance.new("Frame")
Notification.Visible = false
Notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
Notification.Parent = Cloneables
Notification.BackgroundTransparency = 0.5
Notification.Position = UDim2.fromScale(0.5975132584571838, 0.008663366548717022)
Notification.Name = "Notification"
Notification.Size = UDim2.fromOffset(200, 100)
Notification.BorderSizePixel = 0
Notification.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

var UICorner = Instance.new("UICorner")
UICorner.Parent = Notification

var Header = Instance.new("TextLabel")
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

var Body = Instance.new("TextLabel")
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

local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = Notification
UIAspectRatioConstraint.AspectRatio = 2

local DefaultStyledTextBox = Instance.new("Frame")
DefaultStyledTextBox.Visible = false
DefaultStyledTextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledTextBox.Parent = Cloneables
DefaultStyledTextBox.BackgroundTransparency = 0.20000000298023224
DefaultStyledTextBox.Position = UDim2.fromScale(0.7370529770851135, 0.10522230714559555)
DefaultStyledTextBox.Name = "DefaultStyledTextBox"
DefaultStyledTextBox.Size = UDim2.fromOffset(390, 50)
DefaultStyledTextBox.BorderSizePixel = 0
DefaultStyledTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

var Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledTextBox
Title.Name = "Title"
Title.Size = UDim2.fromOffset(291, 14)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.12564103305339813, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var TextBox = Instance.new("TextBox")
TextBox.TextWrapped = true
TextBox.TextColor3 = Color3.fromRGB(184, 184, 184)
TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox.Text = "Textbox"
TextBox.Parent = DefaultStyledTextBox
TextBox.Size = UDim2.fromOffset(355, 36)
TextBox.Font = Enum.Font.SourceSans
TextBox.BackgroundTransparency = 1
TextBox.Position = UDim2.fromScale(0.043589744716882706, 0.2800000011920929)
TextBox.BorderSizePixel = 0
TextBox.TextSize = 14
TextBox.TextScaled = true
TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledTextBox

var UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledTextBox

var DefaultStyledTextButton = Instance.new("Frame")
DefaultStyledTextButton.Visible = false
DefaultStyledTextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledTextButton.Parent = Cloneables
DefaultStyledTextButton.BackgroundTransparency = 0.20000000298023224
DefaultStyledTextButton.Position = UDim2.fromScale(0.7366277575492859, 0.17747411131858826)
DefaultStyledTextButton.Name = "DefaultStyledTextButton"
DefaultStyledTextButton.Size = UDim2.fromOffset(390, 50)
DefaultStyledTextButton.BorderSizePixel = 0
DefaultStyledTextButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

var UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledTextButton

var UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledTextButton

var Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledTextButton
Title.Name = "Title"
Title.Size = UDim2.fromOffset(291, 14)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.12564103305339813, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var TextButton = Instance.new("TextButton")
TextButton.TextWrapped = true
TextButton.TextColor3 = Color3.fromRGB(184, 184, 184)
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.Parent = DefaultStyledTextButton
TextButton.Size = UDim2.fromOffset(381, 36)
TextButton.Font = Enum.Font.SourceSans
TextButton.BackgroundTransparency = 1
TextButton.Position = UDim2.fromScale(0.020512351766228676, 0.2800000011920929)
TextButton.BorderSizePixel = 0
TextButton.TextSize = 14
TextButton.TextScaled = true
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

local DefaultStyledImageLabel = Instance.new("Frame")
DefaultStyledImageLabel.Visible = false
DefaultStyledImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledImageLabel.Parent = Cloneables
DefaultStyledImageLabel.BackgroundTransparency = 0.20000000298023224
DefaultStyledImageLabel.Position = UDim2.fromScale(0.7370008230209351, 0.009221521206200123)
DefaultStyledImageLabel.Name = "DefaultStyledImageLabel"
DefaultStyledImageLabel.Size = UDim2.fromOffset(390, 50)
DefaultStyledImageLabel.BorderSizePixel = 0
DefaultStyledImageLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

var UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledImageLabel

var UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledImageLabel

var Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledImageLabel
Title.Name = "Title"
Title.Size = UDim2.fromOffset(291, 14)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.12564103305339813, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var ImageLabel = Instance.new("ImageLabel")
ImageLabel.Parent = DefaultStyledImageLabel
ImageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
ImageLabel.BackgroundTransparency = 1
ImageLabel.Position = UDim2.fromScale(0.01794871874153614, 0.2800000011920929)
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.Size = UDim2.fromOffset(378, 36)
ImageLabel.BorderSizePixel = 0
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var DefaultStyledTextLabel = Instance.new("Frame")
DefaultStyledTextLabel.Visible = false
DefaultStyledTextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledTextLabel.Parent = Cloneables
DefaultStyledTextLabel.BackgroundTransparency = 0.20000000298023224
DefaultStyledTextLabel.Position = UDim2.fromScale(0.7369632720947266, 0.2545907497406006)
DefaultStyledTextLabel.Name = "DefaultStyledTextLabel"
DefaultStyledTextLabel.Size = UDim2.fromOffset(390, 50)
DefaultStyledTextLabel.BorderSizePixel = 0
DefaultStyledTextLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

var Title = Instance.new("TextLabel")
Title.TextWrapped = true
Title.TextColor3 = Color3.fromRGB(184, 184, 184)
Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
Title.Text = "Title"
Title.Parent = DefaultStyledTextLabel
Title.Name = "Title"
Title.Size = UDim2.fromOffset(374, 50)
Title.Font = Enum.Font.SourceSans
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromScale(0.023076923564076424, 0)
Title.BorderSizePixel = 0
Title.TextSize = 14
Title.TextScaled = true
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledTextLabel

var UIStroke = Instance.new("UIStroke")
UIStroke.Parent = DefaultStyledTextLabel

local TEST_TAB = Instance.new("ScrollingFrame")
TEST_TAB.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
TEST_TAB.Active = true
TEST_TAB.BorderColor3 = Color3.fromRGB(0, 0, 0)
TEST_TAB.Parent = Cloneables
TEST_TAB.Visible = false
TEST_TAB.Name = "TEST_TAB"
TEST_TAB.Position = UDim2.fromScale(0.47396090626716614, 0.14629210531711578)
TEST_TAB.Size = UDim2.fromScale(0.2730870842933655, 0.5178777575492859)
TEST_TAB.ScrollBarImageTransparency = 1
TEST_TAB.BorderSizePixel = 0
TEST_TAB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

var UICorner = Instance.new("UICorner")
UICorner.Parent = TEST_TAB

var UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0.009999999776482582, 0)
UIPadding.PaddingBottom = UDim.new(0.009999999776482582, 0)
UIPadding.Parent = TEST_TAB
UIPadding.PaddingRight = UDim.new(0.009999999776482582, 0)
UIPadding.PaddingLeft = UDim.new(0.009999999776482582, 0)

var UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = TEST_TAB
UIListLayout.Padding = UDim.new(0.009999999776482582, 0)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

var UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
UIAspectRatioConstraint.Parent = TEST_TAB
UIAspectRatioConstraint.AspectRatio = 0.9220489859580994

var DefaultStyledSeperator = Instance.new("Frame")
DefaultStyledSeperator.Visible = false
DefaultStyledSeperator.BorderColor3 = Color3.fromRGB(0, 0, 0)
DefaultStyledSeperator.Parent = Cloneables
DefaultStyledSeperator.BackgroundTransparency = 1
DefaultStyledSeperator.Position = UDim2.fromScale(0.594818115234375, 0.5410215258598328)
DefaultStyledSeperator.Name = "DefaultStyledSeperator"
DefaultStyledSeperator.Size = UDim2.fromOffset(291, 10)
DefaultStyledSeperator.BorderSizePixel = 0
DefaultStyledSeperator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

var UICorner = Instance.new("UICorner")
UICorner.Parent = DefaultStyledSeperator

var Frame = Instance.new("Frame")
Frame.Parent = DefaultStyledSeperator
Frame.BackgroundTransparency = 0.20000000298023224
Frame.Position = UDim2.fromScale(0.8013203144073486, -37.150001525878906)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.fromOffset(355, 10)
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

var UICorner = Instance.new("UICorner")
UICorner.Parent = Frame

var TopCenterNotfication = Instance.new("Frame")
TopCenterNotfication.BorderColor3 = Color3.fromRGB(0, 0, 0)
TopCenterNotfication.AnchorPoint = Vector2.new(0.5, 0)
TopCenterNotfication.Parent = Cloneables
TopCenterNotfication.BackgroundTransparency = 1
TopCenterNotfication.Position = UDim2.fromScale(0.49966996908187866, 0)
TopCenterNotfication.Name = "TopCenterNotfication"
TopCenterNotfication.Size = UDim2.fromScale(0.0330033004283905, 0.06188118830323219)
TopCenterNotfication.BorderSizePixel = 0
TopCenterNotfication.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

var UICorner = Instance.new("UICorner")
UICorner.Parent = TopCenterNotfication
UICorner.CornerRadius = UDim.new(0, 70)

var Dot = Instance.new("Frame")
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

var UICorner = Instance.new("UICorner")
UICorner.Parent = Dot
UICorner.CornerRadius = UDim.new(0, 70)

var Body = Instance.new("Frame")
Body.Visible = false
Body.BorderColor3 = Color3.fromRGB(0, 0, 0)
Body.Parent = TopCenterNotfication
Body.BackgroundTransparency = 0.699999988079071
Body.Position = UDim2.fromScale(-2.498112678527832, 0.8469361662864685)
Body.Name = "Body"
Body.Size = UDim2.fromOffset(300, 94)
Body.BorderSizePixel = 0
Body.BackgroundColor3 = Color3.fromRGB(34, 34, 34)

var UICorner = Instance.new("UICorner")
UICorner.Parent = Body
UICorner.CornerRadius = UDim.new(0, 70)

var Header = Instance.new("TextLabel")
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

var Body = Instance.new("TextLabel")
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
