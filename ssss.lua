-- Services
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local HttpService  = game:GetService("HttpService")
local LocalPlayer  = Players.LocalPlayer

-- Setup
local CONFIG_FILE = "config.pscp"
local config

local prev = CoreGui:FindFirstChild("PSCP_GUI")
if prev then prev:Destroy() end

-- Default config, if ran for the first time
local DefaultConfig = {
    ExecutionCount = 1,

    Settings = {
        ESP = false,
        Chams = false,
        ModWatch = false,
        AllyMode = false
    },
	NotifSoundId = "1008383810",
    PrevUser = LocalPlayer.Name,
	FooterText = "Development"
}

-- Config Checker / handler
if isfile(CONFIG_FILE) then
    config = HttpService:JSONDecode(readfile(CONFIG_FILE))
else
    config = DefaultConfig
    writefile(CONFIG_FILE, HttpService:JSONEncode(config))
end

-- Config helpers
local function SaveConfig()
    writefile(CONFIG_FILE, HttpService:JSONEncode(config))
end

-- ── Utility ─────────────────────────────────────────────────

local function round(n, places)
	local f = 10 ^ (places or 0)
	return math.floor(n * f + 0.5) / f
end

local function notify(title, text, time) -- Now tapped into the games internal notification service
	game:GetService("ReplicatedStorage").NotifGui:Fire(title, text, time or 3)

	local aud = Instance.new("Sound")
	aud.Parent = CoreGui
	aud.SoundId = "rbxassetid://" .. config.NotifSoundId or "rbxassetid://9120386436"
	aud.Volume = 2
	aud:Play()

end

-- ── Color / faction data ─────────────────────────────────────

local colort = {
	["Foundation"] = {
		["Janitor"]         = Color3.fromRGB(191, 191, 191),
		["Head Researcher"] = Color3.fromRGB(255, 226, 119),
		["Researcher"]      = Color3.fromRGB(255, 206,  77),
		["MTF Cadet"]       = Color3.fromRGB(  0, 174, 255),
		["MTF Commander"]   = Color3.fromRGB(  0, 140, 255),
		["MTF Lieutenant"]  = Color3.fromRGB(  0, 160, 255),
		["MTF Medic"]       = Color3.fromRGB(135, 190, 255),
		["MTF Sniper"]      = Color3.fromRGB(115, 180, 255),
		["MTF Specialist"]  = Color3.fromRGB( 95, 160, 255),
		["Facility Guard"]  = Color3.fromRGB(150, 150, 150),
		["Security Chief"]  = Color3.fromRGB(200, 200, 200),
	},
	["GOC"] = {
		["GOC Private"]  = Color3.fromRGB(140, 200, 200),
		["GOC Sapper"]   = Color3.fromRGB(150, 200, 200),
		["GOC Corporal"] = Color3.fromRGB(160, 200, 200),
		["GOC Captain"]  = Color3.fromRGB(180, 200, 200),
	},
	["Chaos"] = {
		["Class-D"]  = Color3.fromRGB(255, 170,  80),
		["CI Delta"] = Color3.fromRGB(  0,  60,  10),
		["CI Beta"]  = Color3.fromRGB(  0, 100,   0),
		["CI Alpha"] = Color3.fromRGB(  0, 120,   0),
		["CI Gamma"] = Color3.fromRGB(  0,  80,   0),
	},
	["SCP"] = {
		["SCP-049"]       = Color3.fromRGB(255,  38,  38),
		["SCP-049-2"]     = Color3.fromRGB(255,  64,  64),
		["SCP-096"]       = Color3.fromRGB(255,  92,  92),
		["SCP-106"]       = Color3.fromRGB(180,  70,  70),
		["SCP-173"]       = Color3.fromRGB(255,  51,  51),
		["SCP-1507"]      = Color3.fromRGB(255, 130, 210),
		["SCP-1770"]      = Color3.fromRGB(255, 210, 190),
		["SCP-1770-1"]    = Color3.fromRGB(255, 210, 190),
		["SCP-247-J"]     = Color3.fromRGB(255, 245, 200),
		["SCP-457"]       = Color3.fromRGB(255, 140, 120),
		["SCP-610"]       = Color3.fromRGB(255,   0,   0),
		["SCP-939"]       = Color3.fromRGB(255, 120, 120),
		["Serpents Hand"] = Color3.fromRGB(170, 220, 190),
	},
	["Neutral"] = {
		["Skeleton"]  = Color3.fromRGB(255, 210, 120),
		["Spirit"]    = Color3.fromRGB(220, 220, 220),
		["TEAM [1]"]  = Color3.fromRGB(170, 210, 255),
		["TEAM [2]"]  = Color3.fromRGB(255, 170,  80),
		["TEAM [3]"]  = Color3.fromRGB( 80, 255,  80),
		["TEAM [4]"]  = Color3.fromRGB(255, 130, 130),
		["Tutorial"]  = Color3.fromRGB(220, 220, 220),
		["Zombie"]    = Color3.fromRGB( 80, 255,  80),
		["LOBBY"]     = Color3.fromRGB(255, 255, 255),
	},
}

local relations = {
	["Foundation"] = { Foundation="ally",    GOC="neutral", Chaos="hostile", SCP="hostile", Neutral="neutral" },
	["Chaos"]      = { Foundation="hostile", GOC="hostile", Chaos="ally",    SCP="hostile", Neutral="neutral" },
	["SCP"]        = { Foundation="hostile", GOC="hostile", Chaos="hostile", SCP="ally",    Neutral="hostile" },
	["GOC"]        = { Foundation="neutral", GOC="ally",    Chaos="hostile", SCP="hostile", Neutral="neutral" },
	["Neutral"]    = { Foundation="neutral", GOC="neutral", Chaos="neutral", SCP="hostile", Neutral="ally"    },
}

local classColorCache   = {} :: {[string]: Color3}
local classFactionCache = {} :: {[string]: string}

for faction, teams in pairs(colort) do
	for className, color in pairs(teams) do
		classColorCache[className]   = color
		classFactionCache[className] = faction
	end
end

local WHITE  = Color3.fromRGB(255, 255, 255)
local GREEN  = Color3.fromRGB( 80, 255,  80)
local RED    = Color3.fromRGB(255,  80,  80)
local YELLOW = Color3.fromRGB(255, 255,   0)

local function findclass(class: string): Color3
	if not class then return WHITE end
	class = class:match("^%s*(.-)%s*$")
	return classColorCache[class] or WHITE
end

local function getFaction(teamName: string): string?
	return classFactionCache[teamName]
end

local function getRelationColor(p1: Player, p2: Player): Color3?
	local t1 = p1:GetAttribute("teamname")
	local t2 = p2:GetAttribute("teamname")
	if not t1 or not t2 then return nil end
	if t1 == t2 then return GREEN end
	local f1, f2 = getFaction(t1), getFaction(t2)
	if not f1 or not f2 then return nil end
	local rel = relations[f1] and relations[f1][f2]
	if rel == "ally"    then return GREEN
	elseif rel == "hostile" then return RED
	elseif rel == "neutral" then return WHITE
	end
	return YELLOW
end

local function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	end
	return nil
end

local function waitForCharacter(plr: Player)
	while true do
		local char = plr.Character
		if char then
			local root = getRoot(char)
			local hum  = char:FindFirstChildOfClass("Humanoid")
			if root and hum then return char, root, hum end
		end
		task.wait()
	end
end

-- ── State ────────────────────────────────────────────────────

local ESPEnabled      = false
local ChamsEnabled    = false
local ModWatchEnabled = false
local AllyMode        = false   -- shared toggle for both ESP and Chams

local ESPConnections   = {} :: {RBXScriptConnection}
local ChamsConnections = {} :: {RBXScriptConnection}
local ActiveChams      = {} :: {[Player]: Folder}
local ActiveESP        = {} :: {[Player]: {conn: RBXScriptConnection, holder: Folder}}
local ModWatchConnection: RBXScriptConnection? = nil
local RoomData         = {}
local ESP_TICK_RATE    = 0.05  -- 20Hz is plenty; was 0.1 but per-player loops were the real cost

local ModList = {
	1554909143, 641572667,  167512137,  722546560,  2298074664,
	155505545,  1319248072, 1922519282, 929711710,  1541173134,
	1048583001, 326524503,  1398622850, 496918818,  13784931,
	47528047,   250145302,  1129296527, 2667345614, 309109143,
	56158504,   2021558848, 148893499,  122121163,  129033998,
}

-- ── Chams ────────────────────────────────────────────────────

local function chams(plr: Player, useRelation: boolean)
	task.spawn(function()
		if not plr or plr == LocalPlayer then return end

		local old = ActiveChams[plr]
		if old then
			if old.Parent then old:Destroy() end
			ActiveChams[plr] = nil
		end
		local existingFolder = CoreGui:FindFirstChild(plr.Name .. "_CHAM")
		if existingFolder then existingFolder:Destroy() end

		waitForCharacter(plr)

		local holder = Instance.new("Folder")
		holder.Name   = plr.Name .. "_CHAM"
		holder.Parent = CoreGui
		ActiveChams[plr] = holder

		local highlight = Instance.new("Highlight")
		highlight.Name    = plr.Name
		highlight.Adornee = plr.Character
		highlight.Parent  = holder

		local team  = plr:GetAttribute("teamname")
		local color = classColorCache[team] or WHITE
		if useRelation then
			color = getRelationColor(plr, LocalPlayer) or color
		end
		highlight.FillColor = color

		local charConn, teamConn
		charConn = plr.CharacterAdded:Connect(function()
			if ChamsEnabled then chams(plr, useRelation) end
			charConn:Disconnect()
		end)
		teamConn = plr:GetAttributeChangedSignal("teamname"):Connect(function()
			if ChamsEnabled then chams(plr, useRelation) end
			teamConn:Disconnect()
		end)
	end)
end

-- ── ESP ──────────────────────────────────────────────────────

local function cleanupESP(plr: Player)
	local entry = ActiveESP[plr]
	if entry then
		if entry.conn then entry.conn:Disconnect() end
		if entry.holder and entry.holder.Parent then entry.holder:Destroy() end
		ActiveESP[plr] = nil
	end
	-- Belt-and-suspenders: destroy any orphaned folder too
	local orphan = CoreGui:FindFirstChild(plr.Name .. "_ESP")
	if orphan then orphan:Destroy() end
end

local function ESP(plr: Player, ally: boolean)
	task.spawn(function()
		if plr == LocalPlayer then return end

		-- Prevent double-spawn: cancel any existing ESP for this player first
		cleanupESP(plr)

		if not plr.Character then return end

		local holder = Instance.new("Folder")
		holder.Name   = plr.Name .. "_ESP"
		holder.Parent = CoreGui

		-- Register immediately so PlayerRemoving can find it
		ActiveESP[plr] = { conn = nil, holder = holder }

		waitForCharacter(plr)

		-- Player may have left during waitForCharacter
		if not plr.Parent then
			holder:Destroy()
			ActiveESP[plr] = nil
			return
		end

		local highlight = Instance.new("Highlight")
		highlight.Name    = plr.Name
		highlight.Adornee = plr.Character
		highlight.Parent  = holder

		local team  = plr:GetAttribute("teamname")
		local color = classColorCache[team] or WHITE
		if ally then
			color = getRelationColor(plr, LocalPlayer) or color
		end
		highlight.FillColor = color

		local head = plr.Character and plr.Character:FindFirstChild("Head")
		if not head then
			cleanupESP(plr)
			return
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Adornee     = head
		billboard.Name        = plr.Name
		billboard.Parent      = holder
		billboard.Size        = UDim2.new(0, 100, 0, 150)
		billboard.StudsOffset = Vector3.new(0, 1, 0)
		billboard.AlwaysOnTop = true

		local label = Instance.new("TextLabel")
		label.Parent                 = billboard
		label.BackgroundTransparency = 1
		label.Position               = UDim2.new(0, 0, 0, -50)
		label.Size                   = UDim2.new(0, 100, 0, 100)
		label.Font                   = Enum.Font.SourceSansSemibold
		label.TextSize               = 20
		label.TextColor3             = color
		label.TextStrokeTransparency = 0
		label.TextYAlignment         = Enum.TextYAlignment.Bottom
		label.ZIndex                 = 10

		local plrName = plr.Name
		local charConn: RBXScriptConnection
		local teamConn: RBXScriptConnection
		local alive = true  -- set false to stop the task.wait loop

		local function cleanup()
			alive = false
			if charConn then charConn:Disconnect() end
			if teamConn then teamConn:Disconnect() end
		end

		-- task.wait loop replaces per-player Heartbeat connection entirely
		local loopTask = task.spawn(function()
			while alive and holder.Parent do
				local char    = plr.Character
				local locChar = LocalPlayer.Character
				if char and locChar then
					local root    = getRoot(char)
					local locRoot = getRoot(locChar)
					local hum     = char:FindFirstChildOfClass("Humanoid")
					if root and locRoot and hum then
						local currentTeam = plr:GetAttribute("teamname") or "?"
						local fillColor   = findclass(currentTeam)
						highlight.FillColor = fillColor
						label.TextColor3    = fillColor
						label.Text = "Name: " .. plrName
							.. " | HP: "    .. round(hum.Health, 1)
							.. " | Class: " .. currentTeam
					end
				end
				task.wait(ESP_TICK_RATE)
			end
			-- Loop exited naturally (holder destroyed) — ensure cleanup
			cleanup()
		end)

		-- Store the task cancel handle in ActiveESP so PlayerRemoving can kill it
		ActiveESP[plr] = {
			conn   = nil,   -- no Heartbeat conn anymore
			holder = holder,
			loop   = loopTask,
			kill   = function()
				alive = false
				task.cancel(loopTask)
				cleanup()
			end,
		}

		charConn = plr.CharacterAdded:Connect(function()
			cleanup()
			if ESPEnabled then
				task.wait()
				holder:Destroy()
				ActiveESP[plr] = nil
				ESP(plr, ally)
			end
		end)

		teamConn = plr:GetAttributeChangedSignal("teamname"):Connect(function()
			cleanup()
			if ESPEnabled then
				holder:Destroy()
				ActiveESP[plr] = nil
				ESP(plr, ally)
			end
		end)
	end)
end

-- ── ModWatch ─────────────────────────────────────────────────

local function MonitorJoins(): RBXScriptConnection
	for _, player in ipairs(Players:GetPlayers()) do
		if table.find(ModList, player.UserId) then
			notify("Player Detected", player.Name .. " is already in-game")
		end
	end
	return Players.PlayerAdded:Connect(function(player)
		if table.find(ModList, player.UserId) then
			notify("Player Joined", player.Name .. " (" .. player.UserId .. ") joined")
		end
	end)
end

-- ── Player cleanup on leave ───────────────────────────────────

Players.PlayerRemoving:Connect(function(plr)
	-- Kill ESP loop and destroy holder
	local espEntry = ActiveESP[plr]
	if espEntry then
		if espEntry.kill then espEntry.kill() end
		if espEntry.holder and espEntry.holder.Parent then
			espEntry.holder:Destroy()
		end
		ActiveESP[plr] = nil
	end
	-- Belt-and-suspenders for any orphaned folders
	local espFolder = CoreGui:FindFirstChild(plr.Name .. "_ESP")
	if espFolder then espFolder:Destroy() end

	-- Kill Chams holder
	local chamFolder = ActiveChams[plr]
	if chamFolder and chamFolder.Parent then chamFolder:Destroy() end
	ActiveChams[plr] = nil
	local chamOrphan = CoreGui:FindFirstChild(plr.Name .. "_CHAM")
	if chamOrphan then chamOrphan:Destroy() end
end)

-- ── RoomESP ──────────────────────────────────────────────────

local function RoomESP(roomName: string)
	local roundFolder = workspace:FindFirstChild("Round")
	if not roundFolder then notify("RoomESP", "workspace.Round not found") return end
	local roomsFolder = roundFolder:FindFirstChild("Rooms")
	if not roomsFolder then notify("RoomESP", "Rooms folder not found") return end

	local room = (roomsFolder:FindFirstChild("hcz-ez") and roomsFolder["hcz-ez"]:FindFirstChild(roomName))
		or (roomsFolder:FindFirstChild("lcz") and roomsFolder.lcz:FindFirstChild(roomName))

	if not room then
		notify("RoomESP", "Room not found: " .. roomName)
		return
	end

	if RoomData[roomName] then
		RoomData[roomName] = nil
		local tag = CoreGui:FindFirstChild(roomName .. "_ESP")
		if tag then tag:Destroy() end
		notify("RoomESP", roomName .. " highlight OFF")
	else
		local highlight = Instance.new("Highlight")
		highlight.Adornee    = room
		highlight.FillColor  = Color3.fromRGB(0, 140, 255)
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.Name       = roomName .. "_ESP"
		highlight.Parent     = CoreGui
		RoomData[roomName]   = highlight
		notify("RoomESP", roomName .. " highlight ON")
	end
end

-- ============================================================
--  GUI
-- ============================================================

-- Destroy any previous instance so re-running the script is safe

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "PSCP_GUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.Parent       = CoreGui

-- ── Main window ──────────────────────────────────────────────

local WIN_W, WIN_H = 260, 420

local window = Instance.new("Frame")
window.Name              = "Window"
window.Size              = UDim2.new(0, WIN_W, 0, WIN_H)
window.Position          = UDim2.new(0, 20, 0.5, -(WIN_H / 2))
window.BackgroundColor3  = Color3.fromRGB(13, 13, 17)
window.BorderSizePixel   = 0
window.Active            = true
window.Parent            = screenGui
Instance.new("UICorner", window).CornerRadius = UDim.new(0, 8)

-- Thin blue outline
local outline = Instance.new("UIStroke")
outline.Color     = Color3.fromRGB(0, 100, 180)
outline.Thickness = 1
outline.Transparency = 0.5
outline.Parent    = window

-- ── Title bar ────────────────────────────────────────────────

local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 90, 160)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = window
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

-- Cover bottom corners of title bar
local titleBarFix = Instance.new("Frame")
titleBarFix.Size             = UDim2.new(1, 0, 0, 10)
titleBarFix.Position         = UDim2.new(0, 0, 1, -10)
titleBarFix.BackgroundColor3 = Color3.fromRGB(0, 90, 160)
titleBarFix.BorderSizePixel  = 0
titleBarFix.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, -72, 1, 0)
titleLabel.Position              = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency= 1
titleLabel.Text                  = "PSCP  ESP"
titleLabel.TextColor3            = Color3.fromRGB(220, 235, 255)
titleLabel.TextSize              = 14
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
titleLabel.Parent                = titleBar

-- Forward declarations needed by minimize button closure
local scrollFrame, footer

-- Minimize button
local minimized = false
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size             = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position         = UDim2.new(1, -64, 0.5, -14)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 60)
minimizeBtn.BorderSizePixel  = 0
minimizeBtn.Text             = "─"
minimizeBtn.TextColor3       = Color3.fromRGB(180, 255, 200)
minimizeBtn.TextSize         = 13
minimizeBtn.Font             = Enum.Font.GothamBold
minimizeBtn.Parent           = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size                  = UDim2.new(0, 28, 0, 28)
closeBtn.Position              = UDim2.new(1, -32, 0.5, -14)
closeBtn.BackgroundColor3      = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel       = 0
closeBtn.Text                  = "✕"
closeBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize              = 13
closeBtn.Font                  = Enum.Font.GothamBold
closeBtn.Parent                = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	config.ExecutionCount = (config.ExecutionCount or 0) + 1
	config.PrevUser       = LocalPlayer.Name
	config.Settings.ESP      = ESPEnabled
	config.Settings.Chams    = ChamsEnabled
	config.Settings.ModWatch = ModWatchEnabled
	config.Settings.AllyMode = AllyMode
	SaveConfig()
	screenGui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	scrollFrame.Visible = not minimized
	footer.Visible      = not minimized
	window.Size = minimized
		and UDim2.new(0, WIN_W, 0, 36)   -- just the title bar
		or  UDim2.new(0, WIN_W, 0, WIN_H)
	minimizeBtn.Text = minimized and "□" or "─"
end)

-- ── Drag ─────────────────────────────────────────────────────


local dragging = false
local dragInput
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = window.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart

		TweenService:Create(
			window,
			TweenInfo.new(0.05, Enum.EasingStyle.Linear),
			{
				Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			}
		):Play()
	end
end)

-- ── Scrollable content area ──────────────────────────────────

scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name                  = "ScrollFrame"
scrollFrame.Size                  = UDim2.new(1, 0, 1, -46)
scrollFrame.Position              = UDim2.new(0, 0, 0, 40)
scrollFrame.BackgroundTransparency= 1
scrollFrame.BorderSizePixel       = 0
scrollFrame.ScrollBarThickness    = 3
scrollFrame.ScrollBarImageColor3  = Color3.fromRGB(0, 100, 180)
scrollFrame.CanvasSize            = UDim2.new(0, 0, 0, 0) -- auto-set below
scrollFrame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
scrollFrame.ScrollingDirection    = Enum.ScrollingDirection.Y
scrollFrame.Parent                = window

local content = Instance.new("Frame")
content.Name                  = "Content"
content.Size                  = UDim2.new(1, -20, 0, 0)  -- height driven by layout
content.Position              = UDim2.new(0, 10, 0, 6)
content.BackgroundTransparency= 1
content.AutomaticSize         = Enum.AutomaticSize.Y
content.Parent                = scrollFrame

local layout = Instance.new("UIListLayout")
layout.SortOrder     = Enum.SortOrder.LayoutOrder
layout.Padding       = UDim.new(0, 8)
layout.Parent        = content

-- ── Helper: section label ────────────────────────────────────

local function sectionLabel(text: string, order: number)
	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.new(1, 0, 0, 14)
	lbl.BackgroundTransparency= 1
	lbl.Text                  = text:upper()
	lbl.TextColor3            = Color3.fromRGB(0, 174, 255)
	lbl.TextSize              = 10
	lbl.Font                  = Enum.Font.GothamBold
	lbl.TextXAlignment        = Enum.TextXAlignment.Left
	lbl.LayoutOrder           = order
	lbl.Parent                = content
end

-- ── Helper: toggle button ─────────────────────────────────────

local COL_OFF = Color3.fromRGB(30, 30, 38)
local COL_ON  = Color3.fromRGB(0, 120, 200)

local function toggleButton(label: string, order: number, onToggle: (state: boolean) -> ())
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = COL_OFF
	btn.BorderSizePixel  = 0
	btn.TextColor3       = Color3.fromRGB(200, 200, 210)
	btn.TextSize         = 13
	btn.Font             = Enum.Font.Gotham
	btn.Text             = label .. "  ●  OFF"
	btn.TextXAlignment   = Enum.TextXAlignment.Left
	btn.LayoutOrder      = order
	btn.Parent           = content
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent      = btn

	local state = false
	btn.MouseButton1Click:Connect(function()
		state = not state
		onToggle(state)
		if state then
			btn.BackgroundColor3 = COL_ON
			btn.Text = label .. "  ●  ON"
			btn.TextColor3 = Color3.fromRGB(220, 240, 255)
		else
			btn.BackgroundColor3 = COL_OFF
			btn.Text = label .. "  ●  OFF"
			btn.TextColor3 = Color3.fromRGB(200, 200, 210)
		end
	end)

	return btn
end

-- ── Helper: text input row ────────────────────────────────────

local function inputRow(placeholder: string, order: number, onSubmit: (text: string) -> ())
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = order
	row.Parent           = content
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local box = Instance.new("TextBox")
	box.Size                  = UDim2.new(1, -52, 1, -8)
	box.Position              = UDim2.new(0, 8, 0, 4)
	box.BackgroundTransparency= 1
	box.Text                  = ""
	box.PlaceholderText       = placeholder
	box.PlaceholderColor3     = Color3.fromRGB(100, 100, 120)
	box.TextColor3            = Color3.fromRGB(220, 220, 230)
	box.TextSize              = 12
	box.Font                  = Enum.Font.Gotham
	box.TextXAlignment        = Enum.TextXAlignment.Left
	box.ClearTextOnFocus      = false
	box.Parent                = row

	local goBtn = Instance.new("TextButton")
	goBtn.Size             = UDim2.new(0, 38, 1, -8)
	goBtn.Position         = UDim2.new(1, -44, 0, 4)
	goBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
	goBtn.BorderSizePixel  = 0
	goBtn.Text             = "Go"
	goBtn.TextColor3       = Color3.fromRGB(220, 235, 255)
	goBtn.TextSize         = 12
	goBtn.Font             = Enum.Font.GothamBold
	goBtn.Parent           = row
	Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 4)

	local function submit()
		local t = box.Text:match("^%s*(.-)%s*$")
		if t ~= "" then onSubmit(t) end
	end
	goBtn.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enter) if enter then submit() end end)

	return row
end

-- ── Ally mode toggle ─────────────────────────────────────────

sectionLabel("Options", 1)

local allyToggle = Instance.new("TextButton")
allyToggle.Size             = UDim2.new(1, 0, 0, 30)
allyToggle.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
allyToggle.BorderSizePixel  = 0
allyToggle.TextColor3       = Color3.fromRGB(160, 160, 175)
allyToggle.TextSize         = 12
allyToggle.Font             = Enum.Font.Gotham
allyToggle.Text             = "Ally colors  ●  OFF"
allyToggle.TextXAlignment   = Enum.TextXAlignment.Left
allyToggle.LayoutOrder      = 2
allyToggle.Parent           = content
Instance.new("UICorner", allyToggle).CornerRadius = UDim.new(0, 6)
local allyPad = Instance.new("UIPadding")
allyPad.PaddingLeft = UDim.new(0, 12)
allyPad.Parent = allyToggle

allyToggle.MouseButton1Click:Connect(function()
	AllyMode = not AllyMode
	config.Settings.AllyMode = AllyMode
	SaveConfig()
	if AllyMode then
		allyToggle.Text = "Ally colors  ●  ON"
		allyToggle.TextColor3 = Color3.fromRGB(80, 200, 120)
	else
		allyToggle.Text = "Ally colors  ●  OFF"
		allyToggle.TextColor3 = Color3.fromRGB(160, 160, 175)
	end
end)

-- ── Visual section ───────────────────────────────────────────

sectionLabel("Visual", 3)

local _, setESP = toggleButton("Class ESP", 4, function(state)
	config.Settings.ESP = state
	SaveConfig()
	if not state then
		ESPEnabled = false
		for plr, entry in pairs(ActiveESP) do
			if entry.kill then entry.kill() end
			if entry.holder and entry.holder.Parent then entry.holder:Destroy() end
		end
		table.clear(ActiveESP)
		for _, v in ipairs(CoreGui:GetChildren()) do
			if v.Name:find("_ESP") then v:Destroy() end
		end
		for _, conn in ipairs(ESPConnections) do conn:Disconnect() end
		table.clear(ESPConnections)
		notify("ESP", "Disabled")
		return
	end

	ESPEnabled = true
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then ESP(player, AllyMode) end
	end
	local conn = Players.PlayerAdded:Connect(function(player)
		if ESPEnabled and player ~= LocalPlayer then ESP(player, AllyMode) end
	end)
	table.insert(ESPConnections, conn)
	notify("ESP", "Enabled")
end)

local _, setChams = toggleButton("Class Chams", 5, function(state)
	config.Settings.Chams = state
	SaveConfig()
	if not state then
		ChamsEnabled = false
		for _, v in ipairs(CoreGui:GetChildren()) do
			if v.Name:find("_CHAM") then v:Destroy() end
		end
		table.clear(ActiveChams)
		for _, conn in ipairs(ChamsConnections) do conn:Disconnect() end
		table.clear(ChamsConnections)
		notify("Chams", "Disabled")
		return
	end

	ChamsEnabled = true
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then chams(player, AllyMode) end
	end
	local conn = Players.PlayerAdded:Connect(function(player)
		if ChamsEnabled and player ~= LocalPlayer then chams(player, AllyMode) end
	end)
	table.insert(ChamsConnections, conn)
	notify("Chams", "Enabled")
end)

-- ── Room ESP ─────────────────────────────────────────────────

sectionLabel("Room ESP", 6)

inputRow("Room name…", 7, function(roomName)
	RoomESP(roomName)
end)

-- ── Server section ───────────────────────────────────────────

sectionLabel("Server", 8)

local _, setModWatch = toggleButton("Mod Watch", 9, function(state)
	config.Settings.ModWatch = state
	SaveConfig()
	if not state then
		ModWatchEnabled = false
		if ModWatchConnection then
			ModWatchConnection:Disconnect()
			ModWatchConnection = nil
		end
		notify("ModWatch", "Disabled")
		return
	end
	ModWatchEnabled    = true
	ModWatchConnection = MonitorJoins()
	notify("ModWatch", "Enabled")
end)

-- ── Decontamination timer ─────────────────────────────────────

local deconHeader = Instance.new("Frame")
deconHeader.Size                  = UDim2.new(1, 0, 0, 16)
deconHeader.BackgroundTransparency= 1
deconHeader.LayoutOrder           = 10
deconHeader.Parent                = content

local deconSectionLbl = Instance.new("TextLabel")
deconSectionLbl.Size                  = UDim2.new(1, -54, 1, 0)
deconSectionLbl.BackgroundTransparency= 1
deconSectionLbl.Text                  = "DECONTAMINATION"
deconSectionLbl.TextColor3            = Color3.fromRGB(0, 174, 255)
deconSectionLbl.TextSize              = 10
deconSectionLbl.Font                  = Enum.Font.GothamBold
deconSectionLbl.TextXAlignment        = Enum.TextXAlignment.Left
deconSectionLbl.Parent                = deconHeader

local reloadBtn = Instance.new("TextButton")
reloadBtn.Size             = UDim2.new(0, 50, 1, 0)
reloadBtn.Position         = UDim2.new(1, -50, 0, 0)
reloadBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 90)
reloadBtn.BorderSizePixel  = 0
reloadBtn.Text             = "↻  Reload"
reloadBtn.TextColor3       = Color3.fromRGB(120, 180, 255)
reloadBtn.TextSize         = 10
reloadBtn.Font             = Enum.Font.GothamBold
reloadBtn.Parent           = deconHeader
Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0, 4)

local deconBox = Instance.new("Frame")
deconBox.Size             = UDim2.new(1, 0, 0, 44)
deconBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
deconBox.BorderSizePixel  = 0
deconBox.LayoutOrder      = 11
deconBox.Parent           = content
Instance.new("UICorner", deconBox).CornerRadius = UDim.new(0, 6)

local deconAccent = Instance.new("Frame")
deconAccent.Size             = UDim2.new(0, 3, 1, 0)
deconAccent.BackgroundColor3 = Color3.fromRGB(255, 160, 30)
deconAccent.BorderSizePixel  = 0
deconAccent.Parent           = deconBox
Instance.new("UICorner", deconAccent).CornerRadius = UDim.new(0, 6)

local deconTitle = Instance.new("TextLabel")
deconTitle.Size                  = UDim2.new(1, -14, 0, 14)
deconTitle.Position              = UDim2.new(0, 12, 0, 6)
deconTitle.BackgroundTransparency= 1
deconTitle.Text                  = "TIMER"
deconTitle.TextColor3            = Color3.fromRGB(255, 160, 30)
deconTitle.TextSize              = 10
deconTitle.Font                  = Enum.Font.GothamBold
deconTitle.TextXAlignment        = Enum.TextXAlignment.Left
deconTitle.Parent                = deconBox

local deconValue = Instance.new("TextLabel")
deconValue.Size                  = UDim2.new(1, -14, 0, 18)
deconValue.Position              = UDim2.new(0, 12, 0, 20)
deconValue.BackgroundTransparency= 1
deconValue.Text                  = "—"
deconValue.TextColor3            = Color3.fromRGB(220, 220, 230)
deconValue.TextSize              = 13
deconValue.Font                  = Enum.Font.Gotham
deconValue.TextXAlignment        = Enum.TextXAlignment.Left
deconValue.Parent                = deconBox

-- ── Spawnwave timer ───────────────────────────────────────────
sectionLabel("Spawnwave", 13)
local spawnBox = Instance.new("Frame")
spawnBox.Size             = UDim2.new(1, 0, 0, 44)
spawnBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
spawnBox.BorderSizePixel  = 0
spawnBox.LayoutOrder = 14
spawnBox.Parent = content
Instance.new("UICorner", spawnBox).CornerRadius = UDim.new(0, 6)

local spawnAccent = Instance.new("Frame")
spawnAccent.Size             = UDim2.new(0, 3, 1, 0)
spawnAccent.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
spawnAccent.BorderSizePixel  = 0
spawnAccent.Parent           = spawnBox
Instance.new("UICorner", spawnAccent).CornerRadius = UDim.new(0, 6)

local spawnTitle = Instance.new("TextLabel")
spawnTitle.Size                  = UDim2.new(1, -14, 0, 14)
spawnTitle.Position              = UDim2.new(0, 12, 0, 6)
spawnTitle.BackgroundTransparency= 1
spawnTitle.Text                  = "SPAWNWAVE"
spawnTitle.TextColor3            = Color3.fromRGB(80, 200, 120)
spawnTitle.TextSize              = 10
spawnTitle.Font                  = Enum.Font.GothamBold
spawnTitle.TextXAlignment        = Enum.TextXAlignment.Left
spawnTitle.Parent                = spawnBox

local spawnValue = Instance.new("TextLabel")
spawnValue.Size                  = UDim2.new(1, -14, 0, 18)
spawnValue.Position              = UDim2.new(0, 12, 0, 20)
spawnValue.BackgroundTransparency= 1
spawnValue.Text                  = "—"
spawnValue.TextColor3            = Color3.fromRGB(220, 220, 230)
spawnValue.TextSize              = 13
spawnValue.Font                  = Enum.Font.Gotham
spawnValue.TextXAlignment        = Enum.TextXAlignment.Left
spawnValue.Parent                = spawnBox

-- task.wait loops replace Heartbeat connections for the info panels.
-- A shared flag lets the reload button force an immediate re-poll.
local forceReload = false

task.spawn(function()
	local lastNotifiedSpawn = -1
	while screenGui and screenGui.Parent do
		local node = workspace:FindFirstChild("spawntimer")
		if node and node:IsA("IntValue") then
			local val = math.floor(node.Value)
			spawnValue.Text       = tostring(val)
			spawnValue.TextColor3 = Color3.fromRGB(220, 220, 230)
			if val == 30 and lastNotifiedSpawn ~= 30 then
				notify("Spawnwave", "Incoming Spawnwave in 30 seconds!")
				lastNotifiedSpawn = 30
			elseif val ~= 30 then
				lastNotifiedSpawn = val
			end
		else
			spawnValue.Text       = "Not found"
			spawnValue.TextColor3 = Color3.fromRGB(120, 120, 130)
		end
		if forceReload then forceReload = false end
		task.wait(0.25)
	end
end)

task.spawn(function()
	while screenGui and screenGui.Parent do
		local node = workspace:FindFirstChild("DecontaminationTimer", true)
		if node and node:IsA("TextLabel") then
			local raw = (node.Text or ""):match("^%s*(.-)%s*$")
			deconValue.Text       = (raw ~= "" and raw or "—")
			deconValue.TextColor3 = Color3.fromRGB(220, 220, 230)
		else
			deconValue.Text       = "Not found"
			deconValue.TextColor3 = Color3.fromRGB(120, 120, 130)
		end
		if forceReload then forceReload = false end
		task.wait(0.25)
	end
end)

-- Wire reload button: set flag and the loops pick it up on next iteration
reloadBtn.MouseButton1Click:Connect(function()
	forceReload = true
	reloadBtn.Text       = "✓  Done"
	reloadBtn.TextColor3 = Color3.fromRGB(80, 200, 120)
	task.delay(1, function()
		if reloadBtn and reloadBtn.Parent then
			reloadBtn.Text       = "↻  Reload"
			reloadBtn.TextColor3 = Color3.fromRGB(120, 180, 255)
		end
	end)
end)

-- ── SCP Scanner ───────────────────────────────────────────────

sectionLabel("SCP Scanner", 15)

-- Results list frame (initially hidden, expands as rows are added)
local scanResultsFrame = Instance.new("Frame")
scanResultsFrame.Size             = UDim2.new(1, 0, 0, 0) -- resized after scan
scanResultsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
scanResultsFrame.BorderSizePixel  = 0
scanResultsFrame.ClipsDescendants = true
scanResultsFrame.LayoutOrder      = 17
scanResultsFrame.Visible          = false
scanResultsFrame.Parent           = content
Instance.new("UICorner", scanResultsFrame).CornerRadius = UDim.new(0, 6)

local scanResultsLayout = Instance.new("UIListLayout")
scanResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
scanResultsLayout.Padding   = UDim.new(0, 0)
scanResultsLayout.Parent    = scanResultsFrame

local scanPad = Instance.new("UIPadding")
scanPad.PaddingLeft   = UDim.new(0, 10)
scanPad.PaddingRight  = UDim.new(0, 6)
scanPad.PaddingTop    = UDim.new(0, 4)
scanPad.PaddingBottom = UDim.new(0, 4)
scanPad.Parent        = scanResultsFrame

local function addScanRow(playerName: string, scpClass: string, order: number)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder      = order
	row.Parent           = scanResultsFrame

	local dot = Instance.new("TextLabel")
	dot.Size                  = UDim2.new(0, 10, 1, 0)
	dot.BackgroundTransparency= 1
	dot.Text                  = "●"
	dot.TextColor3            = Color3.fromRGB(255, 80, 80)
	dot.TextSize              = 8
	dot.Font                  = Enum.Font.Gotham
	dot.TextXAlignment        = Enum.TextXAlignment.Left
	dot.TextYAlignment        = Enum.TextYAlignment.Center
	dot.Parent                = row

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                  = UDim2.new(0.48, -12, 1, 0)
	nameLbl.Position              = UDim2.new(0, 14, 0, 0)
	nameLbl.BackgroundTransparency= 1
	nameLbl.Text                  = playerName
	nameLbl.TextColor3            = Color3.fromRGB(220, 220, 230)
	nameLbl.TextSize              = 11
	nameLbl.Font                  = Enum.Font.Gotham
	nameLbl.TextXAlignment        = Enum.TextXAlignment.Left
	nameLbl.TextYAlignment        = Enum.TextYAlignment.Center
	nameLbl.TextTruncate          = Enum.TextTruncate.AtEnd
	nameLbl.Parent                = row

	local classLbl = Instance.new("TextLabel")
	classLbl.Size                  = UDim2.new(0.52, 0, 1, 0)
	classLbl.Position              = UDim2.new(0.48, 0, 0, 0)
	classLbl.BackgroundTransparency= 1
	classLbl.Text                  = scpClass
	classLbl.TextColor3            = classColorCache[scpClass] or Color3.fromRGB(255, 80, 80)
	classLbl.TextSize              = 11
	classLbl.Font                  = Enum.Font.GothamBold
	classLbl.TextXAlignment        = Enum.TextXAlignment.Right
	classLbl.TextYAlignment        = Enum.TextYAlignment.Center
	classLbl.TextTruncate          = Enum.TextTruncate.AtEnd
	classLbl.Parent                = row
end

local scanBtn = Instance.new("TextButton")
scanBtn.Size             = UDim2.new(1, 0, 0, 36)
scanBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
scanBtn.BorderSizePixel  = 0
scanBtn.TextColor3       = Color3.fromRGB(255, 180, 180)
scanBtn.TextSize         = 13
scanBtn.Font             = Enum.Font.GothamBold
scanBtn.Text             = "Scan for SCPs"
scanBtn.LayoutOrder      = 16
scanBtn.Parent           = content
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

scanBtn.MouseButton1Click:Connect(function()
	-- Clear previous results
	for _, child in ipairs(scanResultsFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local scpPlayers = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local teamname = player:GetAttribute("teamname")
		if teamname and teamname:sub(1, 4) == "SCP-" then
			table.insert(scpPlayers, { name = player.Name, class = teamname })
		end
	end

	if #scpPlayers == 0 then
		scanResultsFrame.Visible = true
		local noResult = Instance.new("TextLabel")
		noResult.Size                  = UDim2.new(1, 0, 0, 22)
		noResult.BackgroundTransparency= 1
		noResult.Text                  = "No SCPs found"
		noResult.TextColor3            = Color3.fromRGB(120, 120, 130)
		noResult.TextSize              = 11
		noResult.Font                  = Enum.Font.Gotham
		noResult.TextXAlignment        = Enum.TextXAlignment.Left
		noResult.LayoutOrder           = 1
		noResult.Parent                = scanResultsFrame
		scanResultsFrame.Size = UDim2.new(1, 0, 0, 30)
	else
		for i, entry in ipairs(scpPlayers) do
			addScanRow(entry.name, entry.class, i)
		end
		scanResultsFrame.Visible = true
		-- 22px per row + 8px padding top+bottom
		scanResultsFrame.Size = UDim2.new(1, 0, 0, #scpPlayers * 22 + 8)
	end
	-- Scroll to bottom so results are visible
	scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
end)

-- ── Config ───────────────────────────────────────────────────

sectionLabel("Config", 18)

local configBox = Instance.new("Frame")
configBox.Size             = UDim2.new(1, 0, 0, 52)
configBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
configBox.BorderSizePixel  = 0
configBox.LayoutOrder      = 19
configBox.Parent           = content
Instance.new("UICorner", configBox).CornerRadius = UDim.new(0, 6)

local configAccent = Instance.new("Frame")
configAccent.Size             = UDim2.new(0, 3, 1, 0)
configAccent.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
configAccent.BorderSizePixel  = 0
configAccent.Parent           = configBox
Instance.new("UICorner", configAccent).CornerRadius = UDim.new(0, 6)

local configLine1 = Instance.new("TextLabel")
configLine1.Size                  = UDim2.new(1, -14, 0, 16)
configLine1.Position              = UDim2.new(0, 12, 0, 6)
configLine1.BackgroundTransparency= 1
configLine1.Text                  = "Runs: " .. tostring(config.ExecutionCount)
	.. "   |   User: " .. tostring(config.PrevUser)
configLine1.TextColor3            = Color3.fromRGB(180, 140, 255)
configLine1.TextSize              = 10
configLine1.Font                  = Enum.Font.GothamBold
configLine1.TextXAlignment        = Enum.TextXAlignment.Left
configLine1.TextTruncate          = Enum.TextTruncate.AtEnd
configLine1.Parent                = configBox

local configLine2 = Instance.new("TextLabel")
configLine2.Size                  = UDim2.new(1, -14, 0, 14)
configLine2.Position              = UDim2.new(0, 12, 0, 26)
configLine2.BackgroundTransparency= 1
configLine2.Text                  = "File: " .. CONFIG_FILE
configLine2.TextColor3            = Color3.fromRGB(120, 100, 160)
configLine2.TextSize              = 10
configLine2.Font                  = Enum.Font.Gotham
configLine2.TextXAlignment        = Enum.TextXAlignment.Left
configLine2.TextTruncate          = Enum.TextTruncate.AtEnd
configLine2.Parent                = configBox

local saveBtn = Instance.new("TextButton")
saveBtn.Size             = UDim2.new(1, 0, 0, 32)
saveBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
saveBtn.BorderSizePixel  = 0
saveBtn.TextColor3       = Color3.fromRGB(120, 220, 120)
saveBtn.TextSize         = 12
saveBtn.Font             = Enum.Font.GothamBold
saveBtn.Text             = "💾  Save config"
saveBtn.LayoutOrder      = 20
saveBtn.Parent           = content
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

saveBtn.MouseButton1Click:Connect(function()
	config.PrevUser          = LocalPlayer.Name
	config.Settings.ESP      = ESPEnabled
	config.Settings.Chams    = ChamsEnabled
	config.Settings.ModWatch = ModWatchEnabled
	config.Settings.AllyMode = AllyMode
	SaveConfig()
	saveBtn.Text       = "✓  Saved"
	saveBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
	task.delay(1.5, function()
		if saveBtn and saveBtn.Parent then
			saveBtn.Text       = "💾  Save config"
			saveBtn.TextColor3 = Color3.fromRGB(120, 220, 120)
		end
	end)
end)

local resetConfigBtn = Instance.new("TextButton")
resetConfigBtn.Size             = UDim2.new(1, 0, 0, 28)
resetConfigBtn.BackgroundColor3 = Color3.fromRGB(40, 22, 50)
resetConfigBtn.BorderSizePixel  = 0
resetConfigBtn.TextColor3       = Color3.fromRGB(180, 120, 255)
resetConfigBtn.TextSize         = 11
resetConfigBtn.Font             = Enum.Font.Gotham
resetConfigBtn.Text             = "Reset config to defaults"
resetConfigBtn.LayoutOrder      = 21
resetConfigBtn.Parent           = content
Instance.new("UICorner", resetConfigBtn).CornerRadius = UDim.new(0, 6)

resetConfigBtn.MouseButton1Click:Connect(function()
	config = {
		ExecutionCount = 1,
		Settings = { ESP = false, Chams = false, ModWatch = false, AllyMode = false },
		PrevUser = LocalPlayer.Name,
	}
	SaveConfig()
	configLine1.Text = "Runs: 1   |   User: " .. LocalPlayer.Name
	notify("Config", "Reset to defaults — re-run to apply")
end)

-- ── Startup: apply saved settings ────────────────────────────

task.defer(function()
	local s = config.Settings

	if s.AllyMode then
		AllyMode = true
		allyToggle.Text       = "Ally colors  ●  ON"
		allyToggle.TextColor3 = Color3.fromRGB(80, 200, 120)
	end

	if s.ESP      then setESP(true)      end
	if s.Chams    then setChams(true)    end
	if s.ModWatch then setModWatch(true) end

	if s.ESP or s.Chams or s.ModWatch then
		notify("Config", "Settings restored from last session", 4)
	end
end)

-- ── Footer ────────────────────────────────────────────────────

footer = Instance.new("TextLabel")
footer.Size                  = UDim2.new(1, 0, 0, 16)
footer.Position              = UDim2.new(0, 0, 1, -18)
footer.BackgroundTransparency= 1
footer.Text                  = config.FooterText
footer.TextColor3            = Color3.fromRGB(60, 60, 80)
footer.TextSize              = 10
footer.Font                  = Enum.Font.Gotham
footer.TextXAlignment        = Enum.TextXAlignment.Center
footer.Parent                = window
