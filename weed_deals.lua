-- [Services] -----------------------------------------------------------------------------------------------------------------------------------------------------------------
local Services = {
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    UserInput = game:GetService("UserInputService"),
    Camera = game:GetService("Workspace").CurrentCamera,
    Mouse = game:GetService("Players").LocalPlayer:GetMouse(),
    RunService = game:GetService("RunService"),
    Lighting = game:GetService("Lighting"),
}

-- [Funcs]
local Funcs = {}; 

-- [Framework]
local Framework = {}; 

-- [Require modules]
Framework.Network = require(game:GetService("ReplicatedFirst").ClientModules.Old.framework.network);
Framework.Remoteevent = debug.getupvalue(Framework.Network.send, 1);
Framework.Particle = require(game:GetService("ReplicatedFirst").ClientModules.Old.framework.particle);
Framework.Camera = require(game:GetService("ReplicatedFirst").ClientModules.Old.framework.camera);
Framework.Char = debug.getupvalue(Framework.Camera.step, 8);
Framework.Physics = require(game:GetService("ReplicatedFirst").SharedModules.Old.Utilities.Math.physics:Clone());
Framework.Replication = debug.getupvalue(Framework.Camera.setspectate, 1);
Framework.Loadplayer = debug.getupvalue(Framework.Replication.getupdater, 2);
Framework.GunModules = game:GetService("ReplicatedStorage").GunModules:Clone();

-- [Up Values]
debug.setupvalue(Framework.Loadplayer, 1, "Load Player")

-- [Getgc modules]
for i,v in pairs(getgc(true)) do
    if (type(v) == "table") then
        if (rawget(v, "gammo")) then
            Framework.Gamelogic = v
        end
        if (rawget(v, "getbodyparts")) then
            Framework.Getbodyparts = v.getbodyparts    
        end
        if (rawget(v, "setmovementmode")) then
            Framework.Movement = v
        end
    end
end

-- [Nexus UI Library Source] --------------------------------------------------------------------------------------------------------------------------------------------------
getgenv().runService = game:GetService"RunService"
getgenv().textService = game:GetService"TextService"
getgenv().inputService = game:GetService"UserInputService"
getgenv().tweenService = game:GetService"TweenService"

local runService = runService
local textService = textService
local inputService = inputService
local tweenService = tweenService

if getgenv().library then
	getgenv().library:Unload()
end

-- [UI Library Settings]
local library = {
	tabs = {},
	draggable = true,
	flags = {},
	title = "weed.deals | lucious#9999",
	open = false,
	mousestate = inputService.MouseIconEnabled,
	popup = nil,
	instances = {},
	connections = {},
	options = {},
	notifications = {},
	tabSize = 0,
	theme = {},
	foldername = "weed_configs",
	fileext = ".txt"
}

getgenv().library = library

local dragging, dragInput, dragStart, startPos, dragObject
local blacklistedKeys = { 
	Enum.KeyCode.Unknown,
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Slash,
	Enum.KeyCode.Tab,
	Enum.KeyCode.Escape
}
local whitelistedMouseinputs = { 
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3
}

library.round = function(num, bracket)
	bracket = bracket or 1
	local a
	if typeof(num) == "Vector2" then
		a = Vector2.new(library.round(num.X), library.round(num.Y))
	elseif typeof(num) == "Color3" then
		return library.round(num.r * 255), library.round(num.g * 255), library.round(num.b * 255)
	else
		a = math.floor(num / bracket + (math.sign(num) * 0.5)) * bracket
		if a < 0 then
			a = a + bracket
		end
		return a
	end
	return a
end

local chromaColor
spawn(function()
	while library and wait() do
		chromaColor = Color3.fromHSV(tick() % 6 / 6, 1, 1)
	end
end)

function library:Create(class, properties)
	properties = properties or {}
	if not class then
		return
	end
	local a = class == "Square" or class == "Line" or class == "Text" or class == "Quad" or class == "Circle" or class == "Triangle"
	local t = a and Drawing or Instance
	local inst = t.new(class)
	for property, value in next, properties do
		inst[property] = value
	end
	table.insert(self.instances, {
		object = inst,
		method = a
	})
	return inst
end

function library:AddConnection(connection, name, callback)
	callback = type(name) == "function" and name or callback
	connection = connection:connect(callback)
	if name ~= callback then
		self.connections[name] = connection
	else
		table.insert(self.connections, connection)
	end
	return connection
end

function library:Unload()
	inputService.MouseIconEnabled = self.mousestate
	for _, c in next, self.connections do
		c:Disconnect()
	end
	for _, i in next, self.instances do
		if i.method then
			pcall(function()
				i.object:Remove()
			end)
		else
			i.object:Destroy()
		end
	end
	for _, o in next, self.options do
		if o.type == "toggle" then
			pcall(function()
				o:SetState()
			end)
		end
	end
	library = nil
	getgenv().library = nil
end

function library:LoadConfig(config)
	if table.find(self:GetConfigs(), config) then
		local Read, Config = pcall(function()
			return game:GetService"HttpService":JSONDecode(readfile(self.foldername .. "/" .. config .. self.fileext))
		end)
		Config = Read and Config or {}
		for _, option in next, self.options do
			if option.hasInit then
				if option.type ~= "button" and option.flag and not option.skipflag then
					if option.type == "toggle" then
						spawn(function()
							option:SetState(Config[option.flag] == 1)
						end)
					elseif option.type == "color" then
						if Config[option.flag] then
							spawn(function()
								option:SetColor(Config[option.flag])
							end)
							if option.trans then
								spawn(function()
									option:SetTrans(Config[option.flag .. " Transparency"])
								end)
							end
						end
					elseif option.type == "bind" then
						spawn(function()
							option:SetKey(Config[option.flag])
						end)
					else
						spawn(function()
							option:SetValue(Config[option.flag])
						end)
					end
				end
			end
		end
	end
end

function library:SaveConfig(config)
	local Config = {}
	if table.find(self:GetConfigs(), config) then
		Config = game:GetService"HttpService":JSONDecode(readfile(self.foldername .. "/" .. config .. self.fileext))
	end
	for _, option in next, self.options do
		if option.type ~= "button" and option.flag and not option.skipflag then
			if option.type == "toggle" then
				Config[option.flag] = option.state and 1 or 0
			elseif option.type == "color" then
				Config[option.flag] = {
					option.color.r,
					option.color.g,
					option.color.b
				}
				if option.trans then
					Config[option.flag .. " Transparency"] = option.trans
				end
			elseif option.type == "bind" then
				Config[option.flag] = option.key
			elseif option.type == "list" then
				Config[option.flag] = option.value
			else
				Config[option.flag] = option.value
			end
		end
	end
	writefile(self.foldername .. "/" .. config .. self.fileext, game:GetService"HttpService":JSONEncode(Config))
end

function library:GetConfigs()
	if not isfolder(self.foldername) then
		makefolder(self.foldername)
		return {}
	end
	local files = {}
	local a = 0
	for i, v in next, listfiles(self.foldername) do
		if v:sub(#v - #self.fileext + 1, #v) == self.fileext then
			a = a + 1
			v = v:gsub(self.foldername .. "\\", "")
			v = v:gsub(self.fileext, "")
			table.insert(files, a, v)
		end
	end
	return files
end

local function createLabel(option, parent)
	option.main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -12, 0, 24),
		BackgroundTransparency = 1,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Parent = parent
	})
	setmetatable(option, {
		__newindex = function(t, i, v)
			if i == "Text" then
				option.main.Text = tostring(v)
				option.main.Size = UDim2.new(1, -12, 0, textService:GetTextSize(option.main.Text, 15, Enum.Font.Code, Vector2.new(option.main.AbsoluteSize.X, 9e9)).Y + 6)
			end
		end
	})
	option.Text = option.text
end

local function createDivider(option, parent)
	option.hasInit = true
	option.main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Parent = parent
	})
	library:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = Color3.fromRGB(71, 69, 71),
		BorderColor3 = Color3.new(),
		Parent = option.main
	})
	option.title = library:Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		TextColor3 =  Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = option.main
	})
	setmetatable(option, {
		__newindex = function(t, i, v)
			if i == "Text" then
				if v then
					option.title.Text = tostring(v)
					option.title.Size = UDim2.new(0, textService:GetTextSize(option.title.Text, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 12, 0, 20)
					option.main.Size = UDim2.new(1, 0, 0, 18)
				else
					option.title.Text = ""
					option.title.Size = UDim2.new()
					option.main.Size = UDim2.new(1, 0, 0, 6)
				end
			end
		end
	})
	option.Text = option.text
end

local function createToggle(option, parent)
	option.hasInit = true
	option.main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent = parent
	})
	local tickbox
	local tickboxOverlay
	if option.style then
		tickbox = library:Create("ImageLabel", {
			Position = UDim2.new(0, 6, 0, 4),
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.new(),
			Parent = option.main
		})
		library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.fromRGB(60, 60, 60),
			Parent = tickbox
		})
		library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.fromRGB(40, 40, 40),
			Parent = tickbox
		})
		tickboxOverlay = library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = library.flags["Menu Accent Color"],
			Visible = option.state,
			Parent = tickbox
		})
		library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://5941353943",
			ImageTransparency = 0.6,
			Parent = tickbox
		})
		table.insert(library.theme, tickboxOverlay)
	else
		tickbox = library:Create("Frame", {
			Position = UDim2.new(0, 6, 0, 4),
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundColor3 = library.flags["Menu Accent Color"],
			BorderColor3 = Color3.new(),
			Parent = option.main
		})
		tickboxOverlay = library:Create("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = option.state and 1 or 0,
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BorderColor3 = Color3.new(),
			Image = "rbxassetid://4155801252",
			ImageTransparency = 0.6,
			ImageColor3 = Color3.new(),
			Parent = tickbox
		})
		library:Create("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2592362371",
			ImageColor3 = Color3.fromRGB(60, 60, 60),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 62, 62),
			Parent = tickbox
		})
		library:Create("ImageLabel", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2592362371",
			ImageColor3 = Color3.new(),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 62, 62),
			Parent = tickbox
		})
		table.insert(library.theme, tickbox)
	end
	option.interest = library:Create("Frame", {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent = option.main
	})
	option.title = library:Create("TextLabel", {
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = option.text,
		TextColor3 =  option.state and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(180, 180, 180),
		TextSize = 15,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = option.interest
	})
	option.interest.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			option:SetState(not option.state)
		end
		if input.UserInputType.Name == "MouseMovement" then
			if not library.warning and not library.slider then
				if option.style then
					tickbox.ImageColor3 = library.flags["Menu Accent Color"]
				else
					tickbox.BorderColor3 = library.flags["Menu Accent Color"]
					tickboxOverlay.BorderColor3 = library.flags["Menu Accent Color"]
				end
			end
			if option.tip then
				library.tooltip.Text = option.tip
				library.tooltip.Size = UDim2.new(0, textService:GetTextSize(option.tip, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 20)
			end
		end
	end)
	option.interest.InputChanged:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	option.interest.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.style then
				tickbox.ImageColor3 = Color3.new()
			else
				tickbox.BorderColor3 = Color3.new()
				tickboxOverlay.BorderColor3 = Color3.new()
			end
			library.tooltip.Position = UDim2.new(2)
		end
	end)

	function option:SetState(state, nocallback)
		state = typeof(state) == "boolean" and state
		state = state or false
		library.flags[self.flag] = state
		self.state = state
		option.title.TextColor3 = state and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(160, 160, 160)
		if option.style then
			tickboxOverlay.Visible = state
		else
			tickboxOverlay.BackgroundTransparency = state and 1 or 0
		end
		if not nocallback then
			self.callback(state)
		end
	end
	if option.state then
		delay(1, function()
			if library then
				option.callback(true)
			end
		end)
	end
	setmetatable(option, {
		__newindex = function(t, i, v)
			if i == "Text" then
				option.title.Text = tostring(v)
			end
		end
	})
end

local function createButton(option, parent)
	option.hasInit = true
	option.main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Parent = parent
	})
	option.title = library:Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -5),
		Size = UDim2.new(1, -12, 0, 18),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(),
		Text = option.text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.Code,
		Parent = option.main
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.title
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.title
	})
	library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(253, 253, 253)),
		}),
		Rotation = -90,
		Parent = option.title
	})
	option.title.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			option.callback()
			if library then
				library.flags[option.flag] = true
			end
			if option.tip then
				library.tooltip.Text = option.tip
				library.tooltip.Size = UDim2.new(0, textService:GetTextSize(option.tip, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 20)
			end
		end
		if input.UserInputType.Name == "MouseMovement" then
			if not library.warning and not library.slider then
				option.title.BorderColor3 = library.flags["Menu Accent Color"]
			end
		end
	end)
	option.title.InputChanged:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	option.title.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			option.title.BorderColor3 = Color3.new()
			library.tooltip.Position = UDim2.new(2)
		end
	end)
end

local function createBind(option, parent)
	option.hasInit = true
	local binding
	local holding
	local Loop
	if option.sub then
		option.main = option:getMain()
	else
		option.main = option.main or library:Create("Frame", {
			LayoutOrder = option.position,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Parent = parent
		})
		library:Create("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			Text = option.text,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.main
		})
	end

	local bindinput = library:Create(option.sub and "TextButton" or "TextLabel", {
		Position = UDim2.new(1, -6 - (option.subpos or 0), 0, option.sub and 2 or 3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = option.main
	})

	if option.sub then
		bindinput.AutoButtonColor = false
	end

	local interest = option.sub and bindinput or option.main
	local inContact
	interest.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			binding = true
			bindinput.Text = "[...]"
			bindinput.Size = UDim2.new(0, -textService:GetTextSize(bindinput.Text, 16, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 16)
			bindinput.TextColor3 = library.flags["Menu Accent Color"]
		end
	end)

	library:AddConnection(inputService.InputBegan, function(input)
		if inputService:GetFocusedTextBox() then
			return
		end
		if binding then
			local key = (table.find(whitelistedMouseinputs, input.UserInputType) and not option.nomouse) and input.UserInputType
			option:SetKey(key or (not table.find(blacklistedKeys, input.KeyCode)) and input.KeyCode)
		else
			if (input.KeyCode.Name == option.key or input.UserInputType.Name == option.key) and not binding then
				if option.mode == "toggle" then
					library.flags[option.flag] = not library.flags[option.flag]
					option.callback(library.flags[option.flag], 0)
				else
					library.flags[option.flag] = true
					if Loop then
						Loop:Disconnect()
						option.callback(true, 0)
					end
					Loop = library:AddConnection(runService.RenderStepped, function(step)
						if not inputService:GetFocusedTextBox() then
							option.callback(nil, step)
						end
					end)
				end
			end
		end
	end)
	library:AddConnection(inputService.InputEnded, function(input)
		if option.key ~= "none" then
			if input.KeyCode.Name == option.key or input.UserInputType.Name == option.key then
				if Loop then
					Loop:Disconnect()
					library.flags[option.flag] = false
					option.callback(true, 0)
				end
			end
		end
	end)

	function option:SetKey(key)
		binding = false
		bindinput.TextColor3 = Color3.fromRGB(160, 160, 160)
		if Loop then
			Loop:Disconnect()
			library.flags[option.flag] = false
			option.callback(true, 0)
		end
		self.key = (key and key.Name) or key or self.key
		if self.key == "Backspace" then
			self.key = "none"
			bindinput.Text = "[NONE]"
		else
			local a = self.key
			if self.key:match"Mouse" then
				a = self.key:gsub("Button", ""):gsub("Mouse", "M")
			elseif self.key:match"Shift" or self.key:match"Alt" or self.key:match"Control" then
				a = self.key:gsub("Left", "L"):gsub("Right", "R")
			end
			bindinput.Text = "[" .. a:gsub("Control", "CTRL"):upper() .. "]"
		end
		bindinput.Size = UDim2.new(0, -textService:GetTextSize(bindinput.Text, 16, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 16)
	end
	option:SetKey()
end

local function createSlider(option, parent)
	option.hasInit = true
	if option.sub then
		option.main = option:getMain()
		option.main.Size = UDim2.new(1, 0, 0, 42)
	else
		option.main = library:Create("Frame", {
			LayoutOrder = option.position,
			Size = UDim2.new(1, 0, 0, option.textpos and 24 or 40),
			BackgroundTransparency = 1,
			Parent = parent
		})
	end
	option.slider = library:Create("Frame", {
		Position = UDim2.new(0, 6, 0, (option.sub and 22 or option.textpos and 4 or 20)),
		Size = UDim2.new(1, -12, 0, 16),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(),
		Parent = option.main
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(),
		ImageTransparency = 0.8,
		Parent = option.slider
	})
	option.fill = library:Create("Frame", {
		BackgroundColor3 = library.flags["Menu Accent Color"],
		BorderSizePixel = 0,
		Parent = option.slider
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.slider
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.slider
	})
	option.title = library:Create("TextBox", {
		Position = UDim2.new((option.sub or option.textpos) and 0.5 or 0, (option.sub or option.textpos) and 0 or 6, 0, 0),
		Size = UDim2.new(0, 0, 0, (option.sub or option.textpos) and 14 or 18),
		BackgroundTransparency = 1,
		Text = (option.text == "nil" and "" or option.text .. ": ") .. option.value .. option.suffix,
		TextSize = (option.sub or option.textpos) and 14 or 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(210, 210, 210),
		TextXAlignment = Enum.TextXAlignment[(option.sub or option.textpos) and "Center" or "Left"],
		Parent = (option.sub or option.textpos) and option.slider or option.main
	})
	table.insert(library.theme, option.fill)
	library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 115, 115)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		Rotation = -90,
		Parent = option.fill
	})
	if option.min >= 0 then
		option.fill.Size = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 1, 0)
	else
		option.fill.Position = UDim2.new((0 - option.min) / (option.max - option.min), 0, 0, 0)
		option.fill.Size = UDim2.new(option.value / (option.max - option.min), 0, 1, 0)
	end
	local manualInput
	option.title.Focused:connect(function()
		if not manualInput then
			option.title:ReleaseFocus()
			option.title.Text = (option.text == "nil" and "" or option.text .. ": ") .. option.value .. option.suffix
		end
	end)
	option.title.FocusLost:connect(function()
		option.slider.BorderColor3 = Color3.new()
		if manualInput then
			if tonumber(option.title.Text) then
				option:SetValue(tonumber(option.title.Text))
			else
				option.title.Text = (option.text == "nil" and "" or option.text .. ": ") .. option.value .. option.suffix
			end
		end
		manualInput = false
	end)
	local interest = (option.sub or option.textpos) and option.slider or option.main
	interest.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			if inputService:IsKeyDown(Enum.KeyCode.LeftControl) or inputService:IsKeyDown(Enum.KeyCode.RightControl) then
				manualInput = true
				option.title:CaptureFocus()
			else
				library.slider = option
				option.slider.BorderColor3 = library.flags["Menu Accent Color"]
				option:SetValue(option.min + ((input.Position.X - option.slider.AbsolutePosition.X) / option.slider.AbsoluteSize.X) * (option.max - option.min))
			end
		end
		if input.UserInputType.Name == "MouseMovement" then
			if not library.warning and not library.slider then
				option.slider.BorderColor3 = library.flags["Menu Accent Color"]
			end
			if option.tip then
				library.tooltip.Text = option.tip
				library.tooltip.Size = UDim2.new(0, textService:GetTextSize(option.tip, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 20)
			end
		end
	end)
	interest.InputChanged:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	interest.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			library.tooltip.Position = UDim2.new(2)
			if option ~= library.slider then
				option.slider.BorderColor3 = Color3.new()
			end
		end
	end)

	function option:SetValue(value, nocallback)
		if typeof(value) ~= "number" then
			value = 0
		end
		value = library.round(value, option.float)
		value = math.clamp(value, self.min, self.max)
		if self.min >= 0 then
			option.fill:TweenSize(UDim2.new((value - self.min) / (self.max - self.min), 0, 1, 0), "Out", "Quad", 0.05, true)
		else
			option.fill:TweenPosition(UDim2.new((0 - self.min) / (self.max - self.min), 0, 0, 0), "Out", "Quad", 0.05, true)
			option.fill:TweenSize(UDim2.new(value / (self.max - self.min), 0, 1, 0), "Out", "Quad", 0.1, true)
		end
		library.flags[self.flag] = value
		self.value = value
		option.title.Text = (option.text == "nil" and "" or option.text .. ": ") .. option.value .. option.suffix
		if not nocallback then
			self.callback(value)
		end
	end
	delay(1, function()
		if library then
			option:SetValue(option.value)
		end
	end)
end

local function createList(option, parent)
	option.hasInit = true
	if option.sub then
		option.main = option:getMain()
		option.main.Size = UDim2.new(1, 0, 0, 48)
	else
		option.main = library:Create("Frame", {
			LayoutOrder = option.position,
			Size = UDim2.new(1, 0, 0, option.text == "nil" and 30 or 48),
			BackgroundTransparency = 1,
			Parent = parent
		})
		if option.text ~= "nil" then
			library:Create("TextLabel", {
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -12, 0, 18),
				BackgroundTransparency = 1,
				Text = option.text,
				TextSize = 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.fromRGB(210, 210, 210),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = option.main
			})
		end
	end

	local function getMultiText()
		local s = ""
		for _, value in next, option.values do
			s = s .. (option.value[value] and (tostring(value) .. ", ") or "")
		end
		return string.sub(s, 1, #s - 2)
	end
	option.listvalue = library:Create("TextLabel", {
		Position = UDim2.new(0, 6, 0, (option.text == "nil" and not option.sub) and 4 or 22),
		Size = UDim2.new(1, -12, 0, 22),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(),
		Text = " " .. (typeof(option.value) == "string" and option.value or getMultiText()),
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = option.main
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(),
		ImageTransparency = 0.8,
		Parent = option.listvalue
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.listvalue
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.listvalue
	})
	option.arrow = library:Create("ImageLabel", {
		Position = UDim2.new(1, -16, 0, 7),
		Size = UDim2.new(0, 8, 0, 8),
		Rotation = 90,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4918373417",
		ImageColor3 = Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
		ImageTransparency = 0.4,
		Parent = option.listvalue
	})
	option.holder = library:Create("TextButton", {
		ZIndex = 4,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3 = Color3.new(),
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		Parent = library.base
	})
	option.content = library:Create("ScrollingFrame", {
		ZIndex = 4,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarImageColor3 = Color3.new(),
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		Parent = option.holder
	})
	library:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.holder
	})
	library:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.holder
	})
	local layout = library:Create("UIListLayout", {
		Padding = UDim.new(0, 2),
		Parent = option.content
	})
	library:Create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		Parent = option.content
	})
	local valueCount = 0
	layout.Changed:connect(function()
		option.holder.Size = UDim2.new(0, option.listvalue.AbsoluteSize.X, 0, 8 + (valueCount > option.max and (-2 + (option.max * 22)) or layout.AbsoluteContentSize.Y))
		option.content.CanvasSize = UDim2.new(0, 0, 0, 8 + layout.AbsoluteContentSize.Y)
	end)
	local interest = option.sub and option.listvalue or option.main
	option.listvalue.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			if library.popup == option then
				library.popup:Close()
				return
			end
			if library.popup then
				library.popup:Close()
			end
			option.arrow.Rotation = -90
			option.open = true
			option.holder.Visible = true
			local pos = option.main.AbsolutePosition
			option.holder.Position = UDim2.new(0, pos.X + 6, 0, pos.Y + ((option.text == "nil" and not option.sub) and 66 or 84))
			library.popup = option
			option.listvalue.BorderColor3 = library.flags["Menu Accent Color"]
		end
		if input.UserInputType.Name == "MouseMovement" then
			if not library.warning and not library.slider then
				option.listvalue.BorderColor3 = library.flags["Menu Accent Color"]
			end
		end
	end)
	option.listvalue.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if not option.open then
				option.listvalue.BorderColor3 = Color3.new()
			end
		end
	end)
	interest.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Text = option.tip
				library.tooltip.Size = UDim2.new(0, textService:GetTextSize(option.tip, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 20)
			end
		end
	end)
	interest.InputChanged:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	interest.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			library.tooltip.Position = UDim2.new(2)
		end
	end)

	local selected
	function option:AddValue(value, state)
		if self.labels[value] then
			return
		end
		valueCount = valueCount + 1
		if self.multiselect then
			self.values[value] = state
		else
			if not table.find(self.values, value) then
				table.insert(self.values, value)
			end
		end
		local label = library:Create("TextLabel", {
			ZIndex = 4,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = value,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextTransparency = self.multiselect and (self.value[value] and 1 or 0) or self.value == value and 1 or 0,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.content
		})
		self.labels[value] = label
		local labelOverlay = library:Create("TextLabel", {
			ZIndex = 4,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0.8,
			Text = " " .. value,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = library.flags["Menu Accent Color"],
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = self.multiselect and self.value[value] or self.value == value,
			Parent = label
		})
		selected = selected or self.value == value and labelOverlay
		table.insert(library.theme, labelOverlay)
		label.InputBegan:connect(function(input)
			if input.UserInputType.Name == "MouseButton1" then
				if self.multiselect then
					self.value[value] = not self.value[value]
					self:SetValue(self.value)
				else
					self:SetValue(value)
					self:Close()
				end
			end
		end)
	end
	for i, value in next, option.values do
		option:AddValue(tostring(typeof(i) == "number" and value or i))
	end

	function option:RemoveValue(value)
		local label = self.labels[value]
		if label then
			label:Destroy()
			self.labels[value] = nil
			valueCount = valueCount - 1
			if self.multiselect then
				self.values[value] = nil
				self:SetValue(self.value)
			else
				table.remove(self.values, table.find(self.values, value))
				if self.value == value then
					selected = nil
					self:SetValue(self.values[1] or "")
				end
			end
		end
	end

	function option:SetValue(value, nocallback)
		if self.multiselect and typeof(value) ~= "table" then
			value = {}
			for i, v in next, self.values do
				value[v] = false
			end
		end
		self.value = typeof(value) == "table" and value or tostring(table.find(self.values, value) and value or self.values[1])
		library.flags[self.flag] = self.value
		option.listvalue.Text = " " .. (self.multiselect and getMultiText() or self.value)
		if self.multiselect then
			for name, label in next, self.labels do
				label.TextTransparency = self.value[name] and 1 or 0
				if label:FindFirstChild"TextLabel" then
					label.TextLabel.Visible = self.value[name]
				end
			end
		else
			if selected then
				selected.TextTransparency = 0
				if selected:FindFirstChild"TextLabel" then
					selected.TextLabel.Visible = false
				end
			end
			if self.labels[self.value] then
				selected = self.labels[self.value]
				selected.TextTransparency = 1
				if selected:FindFirstChild"TextLabel" then
					selected.TextLabel.Visible = true
				end
			end
		end
		if not nocallback then
			self.callback(self.value)
		end
	end
	delay(1, function()
		if library then
			option:SetValue(option.value)
		end
	end)

	function option:Close()
		library.popup = nil
		option.arrow.Rotation = 90
		self.open = false
		option.holder.Visible = false
		option.listvalue.BorderColor3 = Color3.new()
	end
	return option
end

local function createBox(option, parent)
	option.hasInit = true
	option.main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, option.text == "nil" and 28 or 44),
		BackgroundTransparency = 1,
		Parent = parent
	})
	if option.text ~= "nil" then
		option.title = library:Create("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 0, 18),
			BackgroundTransparency = 1,
			Text = option.text,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.main
		})
	end
	option.holder = library:Create("Frame", {
		Position = UDim2.new(0, 6, 0, option.text == "nil" and 4 or 20),
		Size = UDim2.new(1, -12, 0, 20),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(),
		Parent = option.main
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(),
		ImageTransparency = 0.8,
		Parent = option.holder
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.holder
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.holder
	})
	local inputvalue = library:Create("TextBox", {
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		BackgroundTransparency = 1,
		Text = "  " .. option.value,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ClearTextOnFocus = false,
		Parent = option.holder
	})
	inputvalue.FocusLost:connect(function(enter)
		option.holder.BorderColor3 = Color3.new()
		option:SetValue(inputvalue.Text, enter)
	end)
	inputvalue.Focused:connect(function()
		option.holder.BorderColor3 = library.flags["Menu Accent Color"]
	end)
	inputvalue.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			inputvalue.Text = ""
		end
		if input.UserInputType.Name == "MouseMovement" then
			if not library.warning and not library.slider then
				option.holder.BorderColor3 = library.flags["Menu Accent Color"]
			end
			if option.tip then
				library.tooltip.Text = option.tip
				library.tooltip.Size = UDim2.new(0, textService:GetTextSize(option.tip, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 20)
			end
		end
	end)
	inputvalue.InputChanged:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	inputvalue.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if not inputvalue:IsFocused() then
				option.holder.BorderColor3 = Color3.new()
			end
			library.tooltip.Position = UDim2.new(2)
		end
	end)

	function option:SetValue(value, enter)
		if tostring(value) == "" then
			inputvalue.Text = self.value
		else
			library.flags[self.flag] = tostring(value)
			self.value = tostring(value)
			inputvalue.Text = self.value
			self.callback(value, enter)
		end
	end
	delay(1, function()
		if library then
			option:SetValue(option.value)
		end
	end)
end

local function createColorPickerWindow(option)
	option.mainHolder = library:Create("TextButton", {
		ZIndex = 4,
		Size = UDim2.new(0, option.trans and 200 or 184, 0, 200),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3 = Color3.new(),
		AutoButtonColor = false,
		Visible = false,
		Parent = library.base
	})
	library:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.mainHolder
	})
	library:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.mainHolder
	})
	local hue, sat, val = Color3.toHSV(option.color)
	hue, sat, val = hue == 0 and 1 or hue, sat + 0.005, val - 0.005
	local editinghue
	local editingsatval
	local editingtrans
	local transMain
	if option.trans then
		transMain = library:Create("ImageLabel", {
			ZIndex = 5,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2454009026",
			ImageColor3 = Color3.fromHSV(hue, 1, 1),
			Rotation = 180,
			Parent = library:Create("ImageLabel", {
				ZIndex = 4,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.new(0, 10, 1, -12),
				BorderColor3 = Color3.new(),
				Image = "rbxassetid://4632082392",
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.new(0, 5, 0, 5),
				Parent = option.mainHolder
			})
		})
		option.transSlider = library:Create("Frame", {
			ZIndex = 5,
			Position = UDim2.new(0, 0, option.trans, 0),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = Color3.fromRGB(38, 41, 65),
			BorderColor3 = Color3.fromRGB(255, 255, 255),
			Parent = transMain
		})
		transMain.InputBegan:connect(function(Input)
			if Input.UserInputType.Name == "MouseButton1" then
				editingtrans = true
				option:SetTrans(1 - ((Input.Position.Y - transMain.AbsolutePosition.Y) / transMain.AbsoluteSize.Y))
			end
		end)
		transMain.InputEnded:connect(function(Input)
			if Input.UserInputType.Name == "MouseButton1" then
				editingtrans = false
			end
		end)
	end

	local hueMain = library:Create("Frame", {
		ZIndex = 4,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -6),
		Size = UDim2.new(1, option.trans and -28 or -12, 0, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(),
		Parent = option.mainHolder
	})

	local Gradient = library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueMain
	})

	local hueSlider = library:Create("Frame", {
		ZIndex = 4,
		Position = UDim2.new(1 - hue, 0, 0, 0),
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = Color3.fromRGB(38, 41, 65),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		Parent = hueMain
	})
	hueMain.InputBegan:connect(function(Input)
		if Input.UserInputType.Name == "MouseButton1" then
			editinghue = true
			X = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
			X = math.clamp((Input.Position.X - hueMain.AbsolutePosition.X) / X, 0, 0.995)
			option:SetColor(Color3.fromHSV(1 - X, sat, val))
		end
	end)
	hueMain.InputEnded:connect(function(Input)
		if Input.UserInputType.Name == "MouseButton1" then
			editinghue = false
		end
	end)

	local satval = library:Create("ImageLabel", {
		ZIndex = 4,
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, option.trans and -28 or -12, 1, -28),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderColor3 = Color3.new(),
		Image = "rbxassetid://4155801252",
		ClipsDescendants = true,
		Parent = option.mainHolder
	})

	local satvalSlider = library:Create("Frame", {
		ZIndex = 4,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(sat, 0, 1 - val, 0),
		Size = UDim2.new(0, 4, 0, 4),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = satval
	})
	satval.InputBegan:connect(function(Input)
		if Input.UserInputType.Name == "MouseButton1" then
			editingsatval = true
			X = (satval.AbsolutePosition.X + satval.AbsoluteSize.X) - satval.AbsolutePosition.X
			Y = (satval.AbsolutePosition.Y + satval.AbsoluteSize.Y) - satval.AbsolutePosition.Y
			X = math.clamp((Input.Position.X - satval.AbsolutePosition.X) / X, 0.005, 1)
			Y = math.clamp((Input.Position.Y - satval.AbsolutePosition.Y) / Y, 0, 0.995)
			option:SetColor(Color3.fromHSV(hue, X, 1 - Y))
		end
	end)
	library:AddConnection(inputService.InputChanged, function(Input)
		if Input.UserInputType.Name == "MouseMovement" then
			if editingsatval then
				X = (satval.AbsolutePosition.X + satval.AbsoluteSize.X) - satval.AbsolutePosition.X
				Y = (satval.AbsolutePosition.Y + satval.AbsoluteSize.Y) - satval.AbsolutePosition.Y
				X = math.clamp((Input.Position.X - satval.AbsolutePosition.X) / X, 0.005, 1)
				Y = math.clamp((Input.Position.Y - satval.AbsolutePosition.Y) / Y, 0, 0.995)
				option:SetColor(Color3.fromHSV(hue, X, 1 - Y))
			elseif editinghue then
				X = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
				X = math.clamp((Input.Position.X - hueMain.AbsolutePosition.X) / X, 0, 0.995)
				option:SetColor(Color3.fromHSV(1 - X, sat, val))
			elseif editingtrans then
				option:SetTrans(1 - ((Input.Position.Y - transMain.AbsolutePosition.Y) / transMain.AbsoluteSize.Y))
			end
		end
	end)
	satval.InputEnded:connect(function(Input)
		if Input.UserInputType.Name == "MouseButton1" then
			editingsatval = false
		end
	end)
	function option:updateVisuals(Color)
		hue, sat, val = Color3.toHSV(Color)
		hue = hue == 0 and 1 or hue
		satval.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		if option.trans then
			transMain.ImageColor3 = Color3.fromHSV(hue, 1, 1)
		end
		hueSlider.Position = UDim2.new(1 - hue, 0, 0, 0)
		satvalSlider.Position = UDim2.new(sat, 0, 1 - val, 0)
	end
	return option
end

local function createColor(option, parent)
	option.hasInit = true
	if option.sub then
		option.main = option:getMain()
	else
		option.main = library:Create("Frame", {
			LayoutOrder = option.position,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Parent = parent
		})
		option.title = library:Create("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			Text = option.text,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.main
		})
	end
	option.visualize = library:Create(option.sub and "TextButton" or "Frame", {
		Position = UDim2.new(1, -(option.subpos or 0) - 24, 0, 4),
		Size = UDim2.new(0, 18, 0, 12),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = option.color,
		BorderColor3 = Color3.new(),
		Parent = option.main
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(),
		ImageTransparency = 0.6,
		Parent = option.visualize
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.visualize
	})
	library:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.visualize
	})
	local interest = option.sub and option.visualize or option.main
	if option.sub then
		option.visualize.Text = ""
		option.visualize.AutoButtonColor = false
	end
	interest.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			if not option.mainHolder then
				createColorPickerWindow(option)
			end
			if library.popup == option then
				library.popup:Close()
				return
			end
			if library.popup then
				library.popup:Close()
			end
			option.open = true
			local pos = option.main.AbsolutePosition
			option.mainHolder.Position = UDim2.new(0, pos.X + 36 + (option.trans and -16 or 0), 0, pos.Y + 56)
			option.mainHolder.Visible = true
			library.popup = option
			option.visualize.BorderColor3 = library.flags["Menu Accent Color"]
		end
		if input.UserInputType.Name == "MouseMovement" then
			if not library.warning and not library.slider then
				option.visualize.BorderColor3 = library.flags["Menu Accent Color"]
			end
			if option.tip then
				library.tooltip.Text = option.tip
				library.tooltip.Size = UDim2.new(0, textService:GetTextSize(option.tip, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 20)
			end
		end
	end)
	interest.InputChanged:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if option.tip then
				library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	interest.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseMovement" then
			if not option.open then
				option.visualize.BorderColor3 = Color3.new()
			end
			library.tooltip.Position = UDim2.new(2)
		end
	end)
	function option:SetColor(newColor, nocallback)
		if typeof(newColor) == "table" then
			newColor = Color3.new(newColor[1], newColor[2], newColor[3])
		end
		newColor = newColor or Color3.new(1, 1, 1)
		if self.mainHolder then
			self:updateVisuals(newColor)
		end
		option.visualize.BackgroundColor3 = newColor
		library.flags[self.flag] = newColor
		self.color = newColor
		if not nocallback then
			self.callback(newColor)
		end
	end
	if option.trans then
		function option:SetTrans(value, manual)
			value = math.clamp(tonumber(value) or 0, 0, 1)
			if self.transSlider then
				self.transSlider.Position = UDim2.new(0, 0, value, 0)
			end
			self.trans = value
			library.flags[self.flag .. " Transparency"] = 1 - value
			self.calltrans(value)
		end
		option:SetTrans(option.trans)
	end
	delay(1, function()
		if library then
			option:SetColor(option.color)
		end
	end)
    
	function option:Close()
		library.popup = nil
		self.open = false
		self.mainHolder.Visible = false
		option.visualize.BorderColor3 = Color3.new()
	end
end

function library:AddTab(title, pos)
	local tab = {
		canInit = true,
		columns = {},
		title = tostring(title)
	}
	table.insert(self.tabs, pos or #self.tabs + 1, tab)

	function tab:AddColumn()
		local column = {
			sections = {},
			position = #self.columns,
			canInit = true,
			tab = self
		}
		table.insert(self.columns, column)

		function column:AddSection(title)
			local section = {
				title = tostring(title),
				options = {},
				canInit = true,
				column = self
			}
			table.insert(self.sections, section)
        
			function section:AddLabel(text)
				local option = {
					text = text
				}
				option.section = self
				option.type = "label"
				option.position = #self.options
				option.canInit = true
				table.insert(self.options, option)
				if library.hasInit and self.hasInit then
					createLabel(option, self.content)
				else
					option.Init = createLabel
				end
				return option
			end

			function section:AddDivider(text)
				local option = {
					text = text
				}
				option.section = self
				option.type = "divider"
				option.position = #self.options
				option.canInit = true
				table.insert(self.options, option)
				if library.hasInit and self.hasInit then
					createDivider(option, self.content)
				else
					option.Init = createDivider
				end
				return option
			end

			function section:AddToggle(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.state = typeof(option.state) == "boolean" and option.state or false
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.type = "toggle"
				option.position = #self.options
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.subcount = 0
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				option.style = option.style == 2
				library.flags[option.flag] = option.state
				table.insert(self.options, option)
				library.options[option.flag] = option

				function option:AddColor(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddColor(subOption)
				end

				function option:AddBind(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddBind(subOption)
				end

				function option:AddList(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddList(subOption)
				end

				function option:AddSlider(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddSlider(subOption)
				end
				if library.hasInit and self.hasInit then
					createToggle(option, self.content)
				else
					option.Init = createToggle
				end
				return option
			end

			function section:AddButton(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.type = "button"
				option.position = #self.options
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.subcount = 0
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				table.insert(self.options, option)
				library.options[option.flag] = option

				function option:AddBind(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						option.main.Size = UDim2.new(1, 0, 0, 40)
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddBind(subOption)
				end

				function option:AddColor(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						option.main.Size = UDim2.new(1, 0, 0, 40)
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddColor(subOption)
				end
				if library.hasInit and self.hasInit then
					createButton(option, self.content)
				else
					option.Init = createButton
				end
				return option
			end

			function section:AddBind(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.key = (option.key and option.key.Name) or option.key or "none"
				option.nomouse = typeof(option.nomouse) == "boolean" and option.nomouse or false
				option.mode = typeof(option.mode) == "string" and (option.mode == "toggle" or option.mode == "hold" and option.mode) or "toggle"
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.type = "bind"
				option.position = #self.options
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				table.insert(self.options, option)
				library.options[option.flag] = option
				if library.hasInit and self.hasInit then
					createBind(option, self.content)
				else
					option.Init = createBind
				end
				return option
			end

			function section:AddSlider(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.min = typeof(option.min) == "number" and option.min or 0
				option.max = typeof(option.max) == "number" and option.max or 0
				option.value = option.min < 0 and 0 or math.clamp(typeof(option.value) == "number" and option.value or option.min, option.min, option.max)
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.float = typeof(option.value) == "number" and option.float or 1
				option.suffix = option.suffix and tostring(option.suffix) or ""
				option.textpos = option.textpos == 2
				option.type = "slider"
				option.position = #self.options
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.subcount = 0
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				library.flags[option.flag] = option.value
				table.insert(self.options, option)
				library.options[option.flag] = option
				function option:AddColor(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddColor(subOption)
				end

				function option:AddBind(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddBind(subOption)
				end
				if library.hasInit and self.hasInit then
					createSlider(option, self.content)
				else
					option.Init = createSlider
				end
				return option
			end

			function section:AddList(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.values = typeof(option.values) == "table" and option.values or {}
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.multiselect = typeof(option.multiselect) == "boolean" and option.multiselect or false
				option.value = option.multiselect and (typeof(option.value) == "table" and option.value or {}) or tostring(option.value or option.values[1] or "")
				if option.multiselect then
					for i, v in next, option.values do
						option.value[v] = false
					end
				end
				option.max = option.max or 4
				option.open = false
				option.type = "list"
				option.position = #self.options
				option.labels = {}
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.subcount = 0
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				library.flags[option.flag] = option.value
				table.insert(self.options, option)
				library.options[option.flag] = option

				function option:AddValue(value, state)
					if self.multiselect then
						self.values[value] = state
					else
						table.insert(self.values, value)
					end
				end

				function option:AddColor(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddColor(subOption)
				end

				function option:AddBind(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddBind(subOption)
				end
				if library.hasInit and self.hasInit then
					createList(option, self.content)
				else
					option.Init = createList
				end
				return option
			end

			function section:AddBox(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.value = tostring(option.value or "")
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.type = "box"
				option.position = #self.options
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				library.flags[option.flag] = option.value
				table.insert(self.options, option)
				library.options[option.flag] = option
				if library.hasInit and self.hasInit then
					createBox(option, self.content)
				else
					option.Init = createBox
				end
				return option
			end

			function section:AddColor(option)
				option = typeof(option) == "table" and option or {}
				option.section = self
				option.text = tostring(option.text)
				option.color = typeof(option.color) == "table" and Color3.new(option.color[1], option.color[2], option.color[3]) or option.color or Color3.new(1, 1, 1)
				option.callback = typeof(option.callback) == "function" and option.callback or function()
				end
				option.calltrans = typeof(option.calltrans) == "function" and option.calltrans or (option.calltrans == 1 and option.callback) or function()
				end
				option.open = false
				option.trans = tonumber(option.trans)
				option.subcount = 1
				option.type = "color"
				option.position = #self.options
				option.flag = (library.flagprefix and library.flagprefix .. " " or "") .. (option.flag or option.text)
				option.canInit = (option.canInit ~= nil and option.canInit) or true
				option.tip = option.tip and tostring(option.tip)
				library.flags[option.flag] = option.color
				table.insert(self.options, option)
				library.options[option.flag] = option
				function option:AddColor(subOption)
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.sub = true
					subOption.subpos = self.subcount * 24
					function subOption:getMain()
						return option.main
					end
					self.subcount = self.subcount + 1
					return section:AddColor(subOption)
				end
				if option.trans then
					library.flags[option.flag .. " Transparency"] = option.trans
				end
				if library.hasInit and self.hasInit then
					createColor(option, self.content)
				else
					option.Init = createColor
				end
				return option
			end

			function section:SetTitle(newTitle)
				self.title = tostring(newTitle)
				if self.titleText then
					self.titleText.Text = tostring(newTitle)
					self.titleText.Size = UDim2.new(0, textService:GetTextSize(self.title, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10, 0, 3)
				end
			end

			function section:Init()
				if self.hasInit then
					return
				end
				self.hasInit = true
				self.main = library:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.new(),
					Parent = column.main
				})
				self.content = library:Create("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.fromRGB(60, 60, 60),
					BorderMode = Enum.BorderMode.Inset,
					Parent = self.main
				})
				library:Create("ImageLabel", {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.new(0, 1, 0, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2592362371",
					ImageColor3 = Color3.new(),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = self.main
				})
				table.insert(library.theme, library:Create("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = library.flags["Menu Accent Color"],
					BorderSizePixel = 0,
					BorderMode = Enum.BorderMode.Inset,
					Parent = self.main
				}))
				local layout = library:Create("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
					Parent = self.content
				})
				library:Create("UIPadding", {
					PaddingTop = UDim.new(0, 12),
					Parent = self.content
				})
				self.titleText = library:Create("TextLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(0, textService:GetTextSize(self.title, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10, 0, 3),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderSizePixel = 0,
					Text = self.title,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = self.main
				})
				layout.Changed:connect(function()
					self.main.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 16)
				end)
				for _, option in next, self.options do
					if option.canInit then
						option.Init(option, self.content)
					end
				end
			end
			if library.hasInit and self.hasInit then
				section:Init()
			end
			return section
		end

		function column:Init()
			if self.hasInit then
				return
			end
			self.hasInit = true
			self.main = library:Create("ScrollingFrame", {
				ZIndex = 2,
				Position = UDim2.new(0, 6 + (self.position * 239), 0, 2),
				Size = UDim2.new(0, 233, 1, -4),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarImageColor3 = Color3.fromRGB(),
				ScrollBarThickness = 4,
				VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Visible = false,
				Parent = library.columnHolder
			})
			local layout = library:Create("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				Parent = self.main
			})
			library:Create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				Parent = self.main
			})
			layout.Changed:connect(function()
				self.main.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
			end)
			for _, section in next, self.sections do
				if section.canInit and #section.options > 0 then
					section:Init()
				end
			end
		end
		if library.hasInit and self.hasInit then
			column:Init()
		end
		return column
	end

	function tab:Init()
		if self.hasInit then
			return
		end
		self.hasInit = true
		local size = textService:GetTextSize(self.title, 18, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10
		self.button = library:Create("TextLabel", {
			Position = UDim2.new(0, library.tabSize, 0, 22),
			Size = UDim2.new(0, size, 0, 30),
			BackgroundTransparency = 1,
			Text = self.title,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 15,
			Font = Enum.Font.Code,
			TextWrapped = true,
			ClipsDescendants = true,
			Parent = library.main
		})
		library.tabSize = library.tabSize + size
		self.button.InputBegan:connect(function(input)
			if input.UserInputType.Name == "MouseButton1" then
				library:selectTab(self)
			end
		end)
		for _, column in next, self.columns do
			if column.canInit then
				column:Init()
			end
		end
	end
	if self.hasInit then
		tab:Init()
	end
	return tab
end

function library:AddWarning(warning)
	warning = typeof(warning) == "table" and warning or {}
	warning.text = tostring(warning.text)
	warning.type = warning.type == "confirm" and "confirm" or ""
	local answer
	function warning:Show()
		library.warning = warning
		if warning.main and warning.type == "" then
			return
		end
		if library.popup then
			library.popup:Close()
		end
		if not warning.main then
			warning.main = library:Create("TextButton", {
				ZIndex = 2,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 0.6,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = library.main
			})
			warning.message = library:Create("TextLabel", {
				ZIndex = 2,
				Position = UDim2.new(0, 20, 0.5, -60),
				Size = UDim2.new(1, -40, 0, 40),
				BackgroundTransparency = 1,
				TextSize = 16,
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				TextWrapped = true,
				RichText = true,
				Parent = warning.main
			})
			if warning.type == "confirm" then
				local button = library:Create("TextLabel", {
					ZIndex = 2,
					Position = UDim2.new(0.5, -105, 0.5, -10),
					Size = UDim2.new(0, 100, 0, 20),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BorderColor3 = Color3.new(),
					Text = "Yes",
					TextSize = 16,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = warning.main
				})
				library:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2454009026",
					ImageColor3 = Color3.new(),
					ImageTransparency = 0.8,
					Parent = button
				})
				library:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2592362371",
					ImageColor3 = Color3.fromRGB(60, 60, 60),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = button
				})
				local button1 = library:Create("TextLabel", {
					ZIndex = 2,
					Position = UDim2.new(0.5, 5, 0.5, -10),
					Size = UDim2.new(0, 100, 0, 20),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BorderColor3 = Color3.new(),
					Text = "No",
					TextSize = 16,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = warning.main
				})
				library:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2454009026",
					ImageColor3 = Color3.new(),
					ImageTransparency = 0.8,
					Parent = button1
				})
				library:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2592362371",
					ImageColor3 = Color3.fromRGB(60, 60, 60),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = button1
				})
				button.InputBegan:connect(function(input)
					if input.UserInputType.Name == "MouseButton1" then
						answer = true
					end
				end)
				button1.InputBegan:connect(function(input)
					if input.UserInputType.Name == "MouseButton1" then
						answer = false
					end
				end)
			else
				local button = library:Create("TextLabel", {
					ZIndex = 2,
					Position = UDim2.new(0.5, -50, 0.5, -10),
					Size = UDim2.new(0, 100, 0, 20),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.new(),
					Text = "OK",
					TextSize = 16,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = warning.main
				})
				library:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2454009026",
					ImageColor3 = Color3.new(),
					ImageTransparency = 0.8,
					Parent = button
				})
				library:Create("ImageLabel", {
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -2, 1, -2),
					BackgroundTransparency = 1,
					Image = "rbxassetid://3570695787",
					ImageColor3 = Color3.fromRGB(50, 50, 50),
					Parent = button
				})
				button.InputBegan:connect(function(input)
					if input.UserInputType.Name == "MouseButton1" then
						answer = true
					end
				end)
			end
		end
		warning.main.Visible = true
		warning.message.Text = warning.text
		repeat
			wait()
		until answer ~= nil
		spawn(warning.Close)
		library.warning = nil
		return answer
	end

	function warning:Close()
		answer = nil
		if not warning.main then
			return
		end
		warning.main.Visible = false
	end
	return warning
end

function library:Close()
	self.open = not self.open
	if self.open then
		inputService.MouseIconEnabled = false
	else
		inputService.MouseIconEnabled = self.mousestate
	end
	if self.main then
		if self.popup then
			self.popup:Close()
		end
		self.main.Visible = self.open
		self.cursor.Visible  = self.open
		self.cursor1.Visible  = self.open
	end
end

function library:Init()
	if self.hasInit then
		return
	end
	self.hasInit = true
	self.base = library:Create("ScreenGui", {
		IgnoreGuiInset = true
	})
	if runService:IsStudio() then
		self.base.Parent = script.Parent.Parent
	elseif syn then
		syn.protect_gui(self.base)
		self.base.Parent = game:GetService"CoreGui"
	end
	self.main = self:Create("ImageButton", {
		AutoButtonColor = false,
		Position = UDim2.new(0, 100, 0, 46),
		Size = UDim2.new(0, 90, 0, 90), --500, 600
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Tile,
		Modal = true,
		Visible = false,
		Parent = self.base
	})
	local top = self:Create("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.new(),
		Parent = self.main
	})
	self:Create("TextLabel", {
		Position = UDim2.new(0, 6, 0, -1),
		Size = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = tostring(self.title),
		Font = Enum.Font.Code,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.main
	})
	table.insert(library.theme, self:Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = library.flags["Menu Accent Color"],
		BorderSizePixel = 0,
		Parent = self.main
	}))
	library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ImageColor3 = Color3.new(),
		ImageTransparency = 0.4,
		Parent = top
	})
	self.tabHighlight = self:Create("Frame", {
		BackgroundColor3 = library.flags["Menu Accent Color"],
		BorderSizePixel = 0,
		Parent = self.main
	})
	table.insert(library.theme, self.tabHighlight)
	self.columnHolder = self:Create("Frame", {
		Position = UDim2.new(0, 5, 0, 55),
		Size = UDim2.new(1, -10, 1, -60),
		BackgroundTransparency = 1,
		Parent = self.main
	})
	self.cursor = self:Create("Triangle", {
		Color = Color3.fromRGB(180, 180, 180),
		Transparency = 0.6,
	})
	self.cursor1 = self:Create("Triangle", {
		Color = Color3.fromRGB(240, 240, 240),
		Transparency = 0.6,
	})
	self.tooltip = self:Create("TextLabel", {
		ZIndex = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		Visible = true,
		Parent = self.base
	})
	self:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, 10, 1, 0),
		Style = Enum.FrameStyle.RobloxRound,
		Parent = self.tooltip
	})
	self:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = self.main
	})
	self:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = self.main
	})
	top.InputBegan:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			dragObject = self.main
			dragging = true
			dragStart = input.Position
			startPos = dragObject.Position
			if library.popup then
				library.popup:Close()
			end
		end
	end)
	top.InputChanged:connect(function(input)
		if dragging and input.UserInputType.Name == "MouseMovement" then
			dragInput = input
		end
	end)
	top.InputEnded:connect(function(input)
		if input.UserInputType.Name == "MouseButton1" then
			dragging = false
		end
	end)
	function self:selectTab(tab)
		if self.currentTab == tab then
			return
		end
		if library.popup then
			library.popup:Close()
		end
		if self.currentTab then
			self.currentTab.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			for _, column in next, self.currentTab.columns do
				column.main.Visible = false
			end
		end
		self.main.Size = UDim2.new(0, 16 + ((#tab.columns < 2 and 2 or #tab.columns) * 239), 0, 600)
		self.currentTab = tab
		tab.button.TextColor3 = library.flags["Menu Accent Color"]
		self.tabHighlight:TweenPosition(UDim2.new(0, tab.button.Position.X.Offset, 0, 50), "Out", "Quad", 0.2, true)
		self.tabHighlight:TweenSize(UDim2.new(0, tab.button.AbsoluteSize.X, 0, -1), "Out", "Quad", 0.1, true)
		for _, column in next, tab.columns do
			column.main.Visible = true
		end
	end
	spawn(function()
		while library do
			wait(1)
			local Configs = self:GetConfigs()
			for _, config in next, Configs do
				if not table.find(self.options["Config List"].values, config) then
					self.options["Config List"]:AddValue(config)
				end
			end
			for i, config in next, self.options["Config List"].values do
				if not table.find(Configs, config) then
					self.options["Config List"]:RemoveValue(config)
				end
			end
		end
	end)
	for _, tab in next, self.tabs do
		if tab.canInit then
			tab:Init()
			self:selectTab(tab)
		end
	end
	self:AddConnection(inputService.InputEnded, function(input)
		if input.UserInputType.Name == "MouseButton1" and self.slider then
			self.slider.slider.BorderColor3 = Color3.new()
			self.slider = nil
		end
	end)
	self:AddConnection(inputService.InputChanged, function(input)
		if self.open then
			if input.UserInputType.Name == "MouseMovement" then
				if self.cursor then
					local mouse = inputService:GetMouseLocation()
					local MousePos = Vector2.new(mouse.X, mouse.Y)
					self.cursor.PointA = MousePos
					self.cursor.PointB = MousePos + Vector2.new(12, 12)
					self.cursor.PointC = MousePos + Vector2.new(12, 12)
					self.cursor1.PointA = MousePos
					self.cursor1.PointB = MousePos + Vector2.new(11, 11)
					self.cursor1.PointC = MousePos + Vector2.new(11, 11)
				end
				if self.slider then
					self.slider:SetValue(self.slider.min + ((input.Position.X - self.slider.slider.AbsolutePosition.X) / self.slider.slider.AbsoluteSize.X) * (self.slider.max - self.slider.min))
				end
			end
			if input == dragInput and dragging and library.draggable then
				local delta = input.Position - dragStart
				local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y
				dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), "Out", "Quint", 0.1, true)
			end
		end
	end)

	local Meta = getrawmetatable(game)
	local Old_index = Meta.__index
	local Old_new = Meta.__newindex
	setreadonly(Meta, false)
	Meta.__index = newcclosure(function(t, i)
		if checkcaller() then
			return Old_index(t, i)
		end
		if library and i == "MouseIconEnabled" then
			return library.mousestate
		end
		return Old_index(t, i)
	end)
	Meta.__newindex = newcclosure(function(t, i, v)
		if checkcaller() then
			return Old_new(t, i, v)
		end
		if library and i == "MouseIconEnabled" then
			library.mousestate = v
			if library.open then
				return
			end
		end
		return Old_new(t, i, v)
	end)
	setreadonly(Meta, true)
	if not getgenv().silent then
		delay(1, function()
			self:Close()
		end)
	end
end
 [Main Source] --------------------------------------------------------------------------------------------------------------------------------------------------------------

-- [Creating Circles]
Funcs.CircleOne = library:Create("Circle", {
    Radius = 0,
    Thickness = 1,
    NumSides = 100,
    Filled = false,
    Visible = false,
    Transparency = 1,
    Color = library.flags.CircleColor,
    Position = Vector2.new(),
});

Funcs.CircleTwo = library:Create("Circle", {
    Radius = 0,
    Thickness = 1,
    NumSides = 100,
    Filled = false,
    Visible = false,
    Transparency = 1,
    Color = library.flags.CircleColor,
    Position = Vector2.new(),
});

-- [Fov Circles]
library:AddConnection(Services.RunService.RenderStepped, function()
    if (library.flags.CircleEnabled) then
        Funcs.CircleOne.Visible = true
        Funcs.CircleOne.Color = library.flags.CircleColor
        Funcs.CircleOne.Radius = library.flags.AimbotFov * Framework.Char.unaimedfov / workspace.CurrentCamera.FieldOfView
        Funcs.CircleOne.NumSides = library.flags.CircleNumSides
        Funcs.CircleOne.Position = Services.UserInput:GetMouseLocation();
    else
        Funcs.CircleOne.Visible = false
    end
    if (library.flags.Circle2Enabled) then
        Funcs.CircleTwo.Visible = true
        Funcs.CircleTwo.Color = library.flags.Circle2Color
        Funcs.CircleTwo.Radius = library.flags.SilentAimFOV * Framework.Char.unaimedfov / workspace.CurrentCamera.FieldOfView
        Funcs.CircleTwo.NumSides = library.flags.Circle2NumSides
        Funcs.CircleTwo.Position = Services.UserInput:GetMouseLocation();
    else
        Funcs.CircleTwo.Visible = false
    end
end)

-- [Loop Toggles]
library:AddConnection(Services.RunService.Heartbeat, function()
	if (library.flags.TriggerEnabled and library.flags.TriggerBind) then
        if (Framework.Gamelogic.currentgun and Framework.Gamelogic.currentgun.isaiming()) then  
            wait(library.flags.TriggerSpeed / 1000)
            Framework.Gamelogic.currentgun:shoot(true)
            Wait(Services.RunService.RenderStepped)
            Framework.Gamelogic.currentgun:shoot(false)
        end
    end
    if (library.flags.LocalVisualsEnabled and library.flags.CustomArm) then
        if (Framework.Gamelogic.currentgun and Services.Camera:FindFirstChild(Framework.Gamelogic.currentgun.name) and not Framework.Gamelogic.currentgun.isaiming()) then
            for i,v in pairs(Services.Workspace.Camera["Left Arm"]:GetChildren()) do
                if (v:IsA("BasePart")) then
                    v.Material = library.flags.ArmMaterial
                    v.Color = library.flags.ArmColor
                    v.Transparency = library.flags.ArmTransparency
                end
                if (library.flags.ArmAnimation == "Bubbles") then
                    library.flags.ArmAnimation = "rbxassetid://" .. 1461576423
                elseif (library.flags.ArmAnimation == "Scanning") then
                    library.flags.ArmAnimation = "rbxassetid://" .. 5843010904
                end
                if (library.flags.TextureEnabled) then
                    if (v:IsA("MeshPart")) then
                        v.TextureID = library.flags.ArmAnimation 
                    end
                end
            end
            for i,v in pairs(Services.Workspace.Camera["Right Arm"]:GetChildren()) do
                if (v:IsA("BasePart")) then
                    v.Material = library.flags.ArmMaterial
                    v.Color = library.flags.ArmColor
                    v.Transparency = library.flags.ArmTransparency
                end
                if (library.flags.TextureEnabled) then
                    if (v:IsA("MeshPart")) then
                        v.TextureID = library.flags.ArmAnimation 
                    end
                end
            end
        end
    end
    if (library.flags.LocalVisualsEnabled and library.flags.CustomWeapon) then
        if (Framework.Gamelogic.currentgun and Services.Camera:FindFirstChild(Framework.Gamelogic.currentgun.name) and not Framework.Gamelogic.currentgun.isaiming()) then
            for i,v in pairs(Services.Workspace.Camera[Framework.Gamelogic.currentgun.name]:GetChildren()) do 
                if (v:IsA("MeshPart") or v:IsA("UnionOperation")) then
                    v.Material = library.flags.WeaponMaterial
                    v.Color = library.flags.WeaponColor
                    v.Transparency = library.flags.WeaponTransparency
                end
                if (library.flags.WeaponAnimation == "Bubbles") then 
                    library.flags.WeaponAnimation = "rbxassetid://" .. 1461576423
                elseif (library.flags.WeaponAnimation == "Scanning") then
                    library.flags.WeaponAnimation = "rbxassetid://" .. 5843010904
                end
                if (library.flags.TextureEnabled) then
                    if (v:IsA("MeshPart")) then
                        v.TextureID = library.flags.WeaponAnimation
                    end
                end
            end
        end
    end
	if (library.flags.CameraVisualsEnabled and library.flags.ChangeCameraFOV) then
		if (Framework.Camera.type == "firstperson" and Framework.Char.alive) then
			Framework.Char.setunaimedfov(library.flags.CameraFOV)
		end
	else
		if (Framework.Camera.type == "firstperson" and Framework.Char.alive) then
			Framework.Char.setunaimedfov(120)
		end
	end
end)

-- [Network Request]
local Send = Framework.Network.send
Framework.Network.send = function(self, ...)
    local Args = {...}
    if (Args[1] == "repupdate") then
        if (library.flags.ThirdPersonEnabled) then -- [Thx]
            local Updater = Framework.Replication.getupdater(Services.LocalPlayer)
            Services.LocalPlayer.Character.HumanoidRootPart.CanCollide = true
            Services.LocalPlayer.Character.Head.CanCollide = true
            if (Updater and Services.LocalPlayer.Character) then
                Updater.updatecharacter(Services.LocalPlayer.Character) 
                Updater.updatestate({ 
                    lookangles = Args[3], -- this is just for temporarily, im going to switch this to setlookangles later you dw.
                    stance = Framework.Movement.movementmode, -- this is just for temporarily.
                    sprint = Framework.Movement.sprinting(), -- this is just for temporarily.
                    aim = Framework.Gamelogic.currentgun and Framework.Gamelogic.currentgun.isaiming(), -- this is just for temporarily.
                    weapon = Framework.Gamelogic.currentgun and Framework.Gamelogic.currentgun.name, 
                })

                for i,v in pairs(Services.LocalPlayer.Character:GetDescendants()) do
                    if (v:IsA("Decal") or v:IsA("MeshPart") or v:IsA("Part") and v.Name ~= "HumanoidRootPart" and v.Transparency == 1) then
                        v.Transparency = 0
                    end
                end
            end
        end
    end
    return Send(self, unpack(Args))
end

-- [Legit Tab UI] ------------------------------------------------------------------------------------------------------------------------------------------------------------
local LegitTab = library:AddTab("Legit"); 
local LegitColunm1 = LegitTab:AddColumn();
local LegitMain = LegitColunm1:AddSection("Aim Assist")

LegitMain:AddDivider("Main");
LegitMain:AddToggle{text = "Enabled", flag = "AimbotEnabled"}
LegitMain:AddSlider{text = "Aimbot FOV", flag = "AimbotFov", min = 0, max = 750, value = 105, suffix = "°"}
LegitMain:AddSlider{text = "Smoothing Factor", flag = "Smoothing", min = 0, max = 30, value = 3, suffix = "%"}
LegitMain:AddList({text = "Hit Box", flag = "AimbotHitbox", value = "Head", values = {"Head", "Torso"}});
LegitMain:AddList({text = "Aimbot Key", flag = "AimbotKey", value = "On Aim", values = {"On Aim", "On Shoot"}});
LegitMain:AddDivider("Draw Fov");
LegitMain:AddToggle{text = "Enabled", flag = "CircleEnabled"}:AddColor({flag = "CircleColor", color = Color3.new(1, 1, 1)});
LegitMain:AddSlider{text = "Num Sides", flag = "CircleNumSides", min = 3, max = 48, value = 48, suffix = "°"}

local LegitSecond = LegitColunm1:AddSection("Extend Hitbox")
LegitSecond:AddDivider("Main");
LegitSecond:AddToggle{text = "Enabled", flag = "HitboxEnabled"}
LegitSecond:AddList({text = "Hit Box", flag = "ExtendHitbox", value = "Head", values = {"Head", "Torso"}});
LegitSecond:AddSlider{text = "Extend Rate", flag = "ExtendRate", min = 0, max = 10, value = 10, suffix = "%"}

local LegitThird = LegitColunm1:AddSection("Trigger Bot")
LegitThird:AddDivider("Main");
LegitThird:AddToggle{text = "Enabled", flag = "TriggerEnabled"}:AddBind({flag = "TriggerBind", key = "One"});
LegitThird:AddSlider{text = "Trigger Speed", flag = "TriggerSpeed", min = 0, max = 1000, value = 10, suffix = "%"}

local LegitColunm2 = LegitTab:AddColumn();
local LegitForth = LegitColunm2:AddSection("Bullet Redirection")
LegitForth:AddDivider("Main");
LegitForth:AddToggle{text = "Enabled", flag = "SilentAimEnabled"}
LegitForth:AddSlider{text = "Silent Aim FOV", flag = "SilentAimFOV", min = 0, max = 750, value = 105, suffix = "°"}
LegitForth:AddSlider{text = "Hit Chances", flag = "HitChances", min = 0, max = 100, value = 100, suffix = "%"}
LegitForth:AddList({text = "Redirection Mode", flag = "RedirectionMode", value = "P Mode", values = {"P Mode", "Normal Mode"}});
LegitForth:AddList({text = "Hit Box", flag = "SilentAimHitbox", value = "Head", values = {"Head", "Torso"}});
LegitForth:AddDivider("Draw Fov");
LegitForth:AddToggle{text = "Enabled", flag = "Circle2Enabled"}:AddColor({flag = "Circle2Color", color = Color3.new(1, 1, 1)});
LegitForth:AddSlider{text = "Num Sides", flag = "Circle2NumSides", min = 3, max = 48, value = 48, suffix = "°"}
LegitForth:AddDivider("Checks");
LegitForth:AddToggle{text = "Enabled", flag = "VisibleCheck"}

local LegitFifth = LegitColunm2:AddSection("Recoil Control")
LegitFifth:AddDivider("Main");
LegitFifth:AddToggle{text = "Enabled", flag = "RecoilControlEnabled"}
LegitFifth:AddSlider{text = "Model Kick", flag = "ModelKick", min = 5, max = 100, value = 100, suffix = "%"}
LegitFifth:AddSlider{text = "Camera Kick", flag = "CameraKick", min = 5, max = 100, value = 100, suffix = "%"}

-- [Rage Tab UI] ------------------------------------------------------------------------------------------------------------------------------------------------------------
local RageTab = library:AddTab("Rage"); 
local RageColunm1 = RageTab:AddColumn();
local RageMain = RageColunm1:AddSection("Auto Wall")

RageMain:AddDivider("Main");
RageMain:AddToggle{text = "Enabled", flag = "AutoWallEnabled"}

-- [Visuals Tab UI] ------------------------------------------------------------------------------------------------------------------------------------------------------------
local VisualsTab = library:AddTab("Visuals"); 
local VisualsColunm1 = VisualsTab:AddColumn();
local VisualsMain = VisualsColunm1:AddSection("Local Visuals")

VisualsMain:AddDivider("Main");
VisualsMain:AddToggle{text = "Enabled", flag = "LocalVisualsEnabled"}
VisualsMain:AddToggle{text = "Custom Arm", flag = "CustomArm"}:AddColor({flag = "ArmColor", color = Color3.new(0.599623620510101318359375, 0.447115242481231689453125, 0.97174417972564697265625)});
VisualsMain:AddSlider{text = "Transparency", flag = "ArmTransparency", min = 0.10, max = 0.95, float = 0.01, value = 0.85, suffix = "%"}
VisualsMain:AddList({text = "Material", flag = "ArmMaterial", value = "ForceField", values = {"ForceField", "Neon", "SmoothPlastic"}});
VisualsMain:AddToggle{text = "Custom Weapon", flag = "CustomWeapon"}:AddColor({flag = "WeaponColor", color = Color3.new(1, 1, 1)});
VisualsMain:AddSlider{text = "Transparency", flag = "WeaponTransparency", min = 0.10, max = 0.95, float = 0.01, value = 0.85, suffix = "%"}
VisualsMain:AddList({text = "Material", flag = "WeaponMaterial", value = "ForceField", values = {"ForceField", "Neon", "SmoothPlastic"}});
VisualsMain:AddDivider("Mesh");
VisualsMain:AddToggle{text = "Enabled", flag = "TextureEnabled"}
VisualsMain:AddList({text = "Arm Animation", flag = "ArmAnimation", value = "Bubbles", values = {"Bubbles", "Scanning"}});
VisualsMain:AddList({text = "Weapon Animation", flag = "WeaponAnimation", value = "Bubbles", values = {"Bubbles", "Scanning"}});
VisualsMain:AddDivider("Third Person");
VisualsMain:AddToggle{text = "Enabled", flag = "ThirdPersonEnabled"}:AddColor({flag = "ThirdPersonColor", color = Color3.new(1, 1, 1)});
VisualsMain:AddList({text = "Material", flag = "ThirdPersonMaterial", value = "ForceField", values = {"ForceField", "SmoothPlastic"}});

local VisualsColunm2 = VisualsTab:AddColumn();
local VisualsSecond = VisualsColunm2:AddSection("Camera Visuals")

VisualsSecond:AddDivider("Main");
VisualsSecond:AddToggle{text = "Enabled", flag = "CameraVisualsEnabled"}
VisualsSecond:AddToggle{text = "Change Camera FOV", flag = "ChangeCameraFOV"}
VisualsSecond:AddSlider{text = "Camera FOV", flag = "CameraFOV", min = 10, max = 120, value = 120, suffix = "°"}
VisualsSecond:AddToggle{text = "Remove Round Lock", flag = "RemoveRoundLock"}
VisualsSecond:AddToggle{text = "No Camera Bob", flag = "NoCameraBob"}
VisualsSecond:AddToggle{text = "No Gun Bob", flag = "NoGunBob"}
VisualsSecond:AddToggle{text = "Remove Gun Scope", flag = "RemoveGunScope"}
VisualsSecond:AddToggle{text = "Anti Suppression", flag = "AntiSuppression"}

-- [Library Settings UI] -----------------------------------------------------------------------------------------------------------------------------------------------------
local SettingsTab = library:AddTab("Settings"); 
local SettingsColumn = SettingsTab:AddColumn(); 
local SettingsColumn2 = SettingsTab:AddColumn(); 
local SettingSection = SettingsColumn:AddSection("Menu"); 
local ConfigSection = SettingsColumn2:AddSection("Configs");
local Warning = library:AddWarning({type = "confirm"});

SettingSection:AddBind({text = "Open / Close", flag = "UI Toggle", nomouse = true, key = "Delete", callback = function()
    library:Close();
end});

SettingSection:AddColor({text = "Accent Color", flag = "Menu Accent Color", color = Color3.new(0.599623620510101318359375, 0.447115242481231689453125, 0.97174417972564697265625), callback = function(color)
    if library.currentTab then
        library.currentTab.button.TextColor3 = color;
    end
    for i,v in pairs(library.theme) do
        v[(v.ClassName == "TextLabel" and "TextColor3") or (v.ClassName == "ImageLabel" and "ImageColor3") or "BackgroundColor3"] = color;
    end
end});

-- [Background List]
local backgroundlist = {
    Floral = "rbxassetid://5553946656",
    Flowers = "rbxassetid://6071575925",
    Circles = "rbxassetid://6071579801",
    Hearts = "rbxassetid://6073763717"
};

-- [Background List]
local back = SettingSection:AddList({text = "Background", max = 4, flag = "background", values = {"Floral", "Flowers", "Circles", "Hearts"}, value = "Floral", callback = function(v)
    if library.main then
        library.main.Image = backgroundlist[v];
    end
end});

-- [Background Color Picker]
back:AddColor({flag = "backgroundcolor", color = Color3.new(), callback = function(color)
    if library.main then
        library.main.ImageColor3 = color;
    end
end, trans = 1, calltrans = function(trans)
    if library.main then
        library.main.ImageTransparency = 1 - trans;
    end
end});

-- [Tile Size Slider]
SettingSection:AddSlider({text = "Tile Size", min = 50, max = 500, value = 50, callback = function(size)
    if library.main then
        library.main.TileSize = UDim2.new(0, size, 0, size);
    end
end});

-- [Discord Button]
SettingSection:AddButton({text = "Discord", callback = function()
end});

-- [Config Box]
ConfigSection:AddBox({text = "Config Name", skipflag = true});

-- [Config List]
ConfigSection:AddList({text = "Configs", skipflag = true, value = "", flag = "Config List", values = library:GetConfigs()});

-- [Create Button]
ConfigSection:AddButton({text = "Create", callback = function()
    library:GetConfigs();
    writefile(library.foldername .. "/" .. library.flags["Config Name"] .. library.fileext, "{}");
    library.options["Config List"]:AddValue(library.flags["Config Name"]);
end});

-- [Save Button]
ConfigSection:AddButton({text = "Save", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"]);
    Warning.text = "Are you sure you want to save the current settings to config <font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. library.flags["Config List"] .. "</font>?";
    if Warning:Show() then
        library:SaveConfig(library.flags["Config List"]);
    end
end});

-- [Load Button]
ConfigSection:AddButton({text = "Load", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"]);
    Warning.text = "Are you sure you want to load config <font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. library.flags["Config List"] .. "</font>?";
    if Warning:Show() then
        library:LoadConfig(library.flags["Config List"]);
    end
end});

-- [Delete Button]
ConfigSection:AddButton({text = "Delete", callback = function()
    local r, g, b = library.round(library.flags["Menu Accent Color"]);
    Warning.text = "Are you sure you want to delete config <font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. library.flags["Config List"] .. "</font>?";
    if Warning:Show() then
        local config = library.flags["Config List"];
        if table.find(library:GetConfigs(), config) and isfile(library.foldername .. "/" .. config .. library.fileext) then
            library.options["Config List"]:RemoveValue(config);
            delfile(library.foldername .. "/" .. config .. library.fileext);
        end
    end
end});

-- [Init] --------------------------------------------------------------------------------------------------------------------------------------------------------------------
library:Init();
library:selectTab(library.tabs[1]);
