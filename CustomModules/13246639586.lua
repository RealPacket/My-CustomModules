-- Credits to Inf Yield & all the other scripts that helped me make bypasses
local GuiLibrary = shared.GuiLibrary
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local camera = workspace.CurrentCamera
local targetInfo = shared.VapeTargetInfo
local requestFn = syn and syn.request
	or http and http.request
	or http_request
	or fluxus and fluxus.request
	or getgenv().request
	or request
local getasset = getsynasset or getcustomasset
local chatconnection
local connectionstodisconnect = {}
local entityLibrary = shared.vapeentity

local RenderStepTable = {}
local StepTable = {}

local function BindToRenderStep(name, num, func)
	if RenderStepTable[name] == nil then
		RenderStepTable[name] = RunService.RenderStepped:Connect(func)
	end
end
local function UnbindFromRenderStep(name)
	if RenderStepTable[name] then
		RenderStepTable[name]:Disconnect()
		RenderStepTable[name] = nil
	end
end

local function addvectortocframe(cframe, vec)
	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cframe:GetComponents()
	return CFrame.new(x + vec.X, y + vec.Y, z + vec.Z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
end

local function BindToStepped(name, num, func)
	if StepTable[name] == nil then
		StepTable[name] = RunService.Stepped:Connect(func)
	end
end
local function UnbindFromStepped(name)
	if StepTable[name] then
		StepTable[name]:Disconnect()
		StepTable[name] = nil
	end
end

local function createwarning(title, text, delay)
	pcall(function()
		local frame = GuiLibrary.CreateNotification(title, text, delay, "vape/assets/WarningNotification.png")
		frame.Frame.BackgroundColor3 = Color3.fromRGB(236, 129, 44)
		frame.Frame.Frame.BackgroundColor3 = Color3.fromRGB(236, 129, 44)
	end)
end

local function friendCheck(plr, recolor)
	return (recolor and GuiLibrary.ObjectsThatCanBeSaved["Recolor visualsToggle"].Api.Enabled or not recolor)
		and GuiLibrary.ObjectsThatCanBeSaved["Use FriendsToggle"].Api.Enabled
		and table.find(GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectList, plr.Name)
		and GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectListEnabled[table.find(
			GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.ObjectList,
			plr.Name
		)]
end

local function getPlayerColor(plr)
	return (
		friendCheck(plr, true)
			and Color3.fromHSV(
				GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].ApiHue,
				GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Sat,
				GuiLibrary.ObjectsThatCanBeSaved["Friends ColorSliderColor"].Api.Value
			)
		or tostring(plr.TeamColor) ~= "White" and plr.TeamColor.Color
	)
end

local function getcustomassetfunc(path)
	if not isfile(path) then
		task.spawn(function()
			local textlabel = Instance.new("TextLabel")
			textlabel.Size = UDim2.new(1, 0, 0, 36)
			textlabel.Text = "Downloading " .. path
			textlabel.BackgroundTransparency = 1
			textlabel.TextStrokeTransparency = 0
			textlabel.TextSize = 30
			textlabel.Font = Enum.Font.SourceSans
			textlabel.TextColor3 = Color3.new(1, 1, 1)
			textlabel.Position = UDim2.new(0, 0, 0, -36)
			textlabel.Parent = GuiLibrary.MainGui
			repeat
				task.wait()
			until isfile(path)
			textlabel:Destroy()
		end)
		local req = requestFn({
			Url = "https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/"
				.. path:gsub("vape/assets", "assets"),
			Method = "GET",
		})
		writefile(path, req.Body)
	end
	return getasset(path)
end

local function runcode(func)
	func()
end

local function retoggleMod(mod)
	for i = 1, 2 do
		mod.ToggleButton(true)
	end
end

type store = {
	getState: (self: store) -> { any },
	changed: {
		connect: (self: any, f: (newState: { any }, oldState: { any }) -> ()) -> (),
	},
	dispatch: (action: any) -> (),
	destruct: (self: store) -> (),
	flush: () -> (),
}

type skywars = {
	BlockFunctionHandler: any,
	BlockUtil: any,
	AfkController: any,
	Store: store,
	StoreChanged: (k: string, handler: (newState: { any }, oldState: { any }) -> ()) -> (),
	TeamController: any,
	BlockController: any,
	EventHandler: any,
	Events: { any },
	HealthController: any,
	HotbarController: any,
	ItemTable: any,
	MeleeController: any,
	ScreenController: any,
	SprintingController: any,
	VelocityController: any,
}
local skywars: skywars = {}
local getfunctions
runcode(function()
	getfunctions = function()
		local Flamework = require(ReplicatedStorage.rbxts_include.node_modules["@flamework"].core.out).Flamework
		repeat
			task.wait()
		until Flamework.isInitialized
		local controllers = {}
		local controllerids = {}
		local eventnames = {}
		for i, v in pairs(debug.getupvalue(Flamework.Testing.patchDependency, 1).idToObj) do
			controllers[tostring(v)] = v
			controllerids[tostring(v)] = i
			local controllerevents = {}
			for i2, v2 in pairs(v) do
				if type(v2) == "function" then
					local eventsfound = {}
					for _, v3 in pairs(debug.getconstants(v2)) do
						if tostring(v3):find("-") == 9 then
							table.insert(eventsfound, tostring(v3))
						end
					end
					if #eventsfound > 0 then
						controllerevents[i2] = eventsfound
					end
				end
			end
			eventnames[tostring(v)] = controllerevents
		end
		local Events = require(ReplicatedStorage.TS.events).GlobalEvents.client
		skywars = {
			EventHandler = Events,
			Events = eventnames,
			StoreChanged = require(PlayerScripts.TS.ui.rodux["global-store"]).GlobalStoreChanged,
			AfkController = require(PlayerScripts.TS.controllers["afk-controller"]).AfkController,
			TeamController = require(PlayerScripts.TS.controllers["team-controller"]).TeamController,
			BlockController = require(PlayerScripts.TS.controllers["block-controller"]).BlockController,
			SprintingController = require(PlayerScripts.TS.controllers["sprinting-controller"]).SprintingController,
			BlockFunctionHandler = require(PlayerScripts.TS.events).Functions,
			HotbarController = controllers.HotbarController,
			BlockUtil = require(ReplicatedStorage.TS.util["block-util"]).BlockUtil,
			VelocityController = require(PlayerScripts.TS.controllers["player-velocity-controller"]).PlayerVelocityController,
			ScreenController = controllers.ScreenController,
			MeleeController = Flamework.resolveDependency(controllerids.MeleeController),
			ItemTable = require(ReplicatedStorage.TS.item.item).Items,
			HealthController = Flamework.resolveDependency(controllerids.HealthController),
		}
	end
end)
-- garbage but it works 😑
runcode(function()
	local globalStore = require(PlayerScripts.TS.ui.rodux["global-store"]).GlobalStore
	local store = require(ReplicatedStorage.rbxts_include.node_modules["@rbxts"].rodux.src.Store)
	local storeWrapper = globalStore
	for k, v in store do
		if not storeWrapper[k] and type(v) == "function" then
			storeWrapper[k] = v
		end
	end
	skywars.Store = storeWrapper
end)

shared.vapeteamcheck = function(plr)
	return (
		GuiLibrary.ObjectsThatCanBeSaved["Teams by colorToggle"].Api.Enabled
			and (skywars.TeamController:getPlayerTeam(plr) ~= skywars.TeamController:getPlayerTeam(LocalPlayer))
		or not GuiLibrary.ObjectsThatCanBeSaved["Teams by colorToggle"].Api.Enabled
	)
end

getfunctions()

---@param plr Player
---@param check boolean
local function targetCheck(plr, check)
	return (
		check and skywars.HealthController:getHealth(plr) > 0 and not plr.Character:FindFirstChild("ForceField")
		or not check
	)
end

---@param player Player
local function isAlive(player)
	if not player then
		player = LocalPlayer
	end
	return player
		and player.Character
		and player.Character.Parent ~= nil
		and player.Character:FindFirstChild("HumanoidRootPart")
		and player.Character:FindFirstChild("Head")
		and player.Character:FindFirstChild("Humanoid")
end

local function isPlayerTargetable(plr, target, friend)
	if type(plr) == "table" then
		plr = plr.Player
	end
	return plr ~= LocalPlayer
		and plr
		and (friend and not friendCheck(plr) or not friend)
		and isAlive(plr)
		and targetCheck(plr, target)
		and shared.vapeteamcheck(plr)
end

local function vischeck(char, part)
	return not unpack(
		camera:GetPartsObscuringTarget(
			{ LocalPlayer.Character[part].Position, char[part].Position },
			{ LocalPlayer.Character, char }
		)
	)
end

local function GetAllNearestHumanoidToPosition(player, distance, amount)
	local returnedplayer = {}
	local currentamount = 0
	if isAlive() then
		for i, v in pairs(Players:GetPlayers()) do
			if
				isPlayerTargetable((player and v or nil), true, true)
				and v.Character:FindFirstChild("HumanoidRootPart")
				and v.Character:FindFirstChild("Head")
				and currentamount < amount
			then
				local mag = (LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).magnitude
				if mag <= distance then
					table.insert(returnedplayer, v)
					currentamount = currentamount + 1
				end
			end
		end
	end
	return returnedplayer
end

local RunLoops = { RenderStepTable = {}, StepTable = {}, HeartTable = {} }

function RunLoops:BindToRenderStep(name, func)
	if RunLoops.RenderStepTable[name] == nil then
		RunLoops.RenderStepTable[name] = RunService.RenderStepped:Connect(func)
	end
end

function RunLoops:UnbindFromRenderStep(name)
	if RunLoops.RenderStepTable[name] then
		RunLoops.RenderStepTable[name]:Disconnect()
		RunLoops.RenderStepTable[name] = nil
	end
end

function RunLoops:BindToStepped(name, func)
	if RunLoops.StepTable[name] == nil then
		RunLoops.StepTable[name] = RunService.Stepped:Connect(func)
	end
end

function RunLoops:UnbindFromStepped(name)
	if RunLoops.StepTable[name] then
		RunLoops.StepTable[name]:Disconnect()
		RunLoops.StepTable[name] = nil
	end
end

function RunLoops:BindToHeartbeat(name, func)
	if RunLoops.HeartTable[name] == nil then
		RunLoops.HeartTable[name] = RunService.Heartbeat:Connect(func)
	end
end

function RunLoops:UnbindFromHeartbeat(name)
	if RunLoops.HeartTable[name] then
		RunLoops.HeartTable[name]:Disconnect()
		RunLoops.HeartTable[name] = nil
	end
end

local raycastWallProperties = RaycastParams.new()
local function raycastWallCheck(char, checktable)
	if not checktable.IgnoreObject then
		checktable.IgnoreObject = raycastWallProperties
		local filter = { LocalPlayer.Character, camera }
		for i, v in pairs(entityLibrary.entityList) do
			if v.Targetable then
				table.insert(filter, v.Character)
			end
		end
		for i, v in pairs(checktable.IgnoreTable or {}) do
			table.insert(filter, v)
		end
		raycastWallProperties.FilterDescendantsInstances = filter
	end
	local ray = workspace.Raycast(
		workspace,
		checktable.Origin,
		(char[checktable.AimPart].Position - checktable.Origin),
		checktable.IgnoreObject
	)
	return not ray
end

local function EntityNearPosition(distance, checktab)
	checktab = checktab or {}
	if entityLibrary.isAlive then
		local sortedentities = {}
		for i, v in pairs(entityLibrary.entityList) do -- loop through playersService
			if not v.Targetable then
				continue
			end
			if not targetCheck(v, true) and checktab.TargetCheck then
				continue
			end
			if targetCheck(v, true) then -- checks
				local playerPosition = v.RootPart.Position
				local mag = (entityLibrary.character.HumanoidRootPart.Position - playerPosition).magnitude
				if checktab.Prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - playerPosition).magnitude
				end
				if mag <= distance then -- mag check
					table.insert(sortedentities, { entity = v, Magnitude = v.Target and -1 or mag })
				end
			end
		end
		table.sort(sortedentities, function(a, b)
			return a.Magnitude < b.Magnitude
		end)
		for i, v in pairs(sortedentities) do
			if checktab.WallCheck then
				if not raycastWallCheck(v.entity, checktab) then
					continue
				end
			end
			return v.entity
		end
	end
end

local function AllNearPosition(distance, amount, checktab)
	local returnedplayer = {}
	local currentamount = 0
	checktab = checktab or {}
	if entityLibrary.isAlive then
		local sortedentities = {}
		for _, v in pairs(entityLibrary.entityList) do
			if not v.Targetable then
				continue
			end
			if targetCheck(v, true) then
				local playerPosition = v.RootPart.Position
				local mag = (entityLibrary.character.HumanoidRootPart.Position - playerPosition).magnitude
				if checktab.Prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - playerPosition).magnitude
				end
				if mag <= distance then
					table.insert(sortedentities, { entity = v, Magnitude = mag })
				end
			end
		end
		table.sort(sortedentities, function(a, b)
			return a.Magnitude < b.Magnitude
		end)
		for i, v in pairs(sortedentities) do
			if checktab.WallCheck then
				if not raycastWallCheck(v.entity, checktab) then
					continue
				end
			end
			table.insert(returnedplayer, v.entity)
			currentamount = currentamount + 1
			if currentamount >= amount then
				break
			end
		end
	end
	return returnedplayer
end

local function CalculateObjectPosition(pos)
	local newpos = camera:WorldToViewportPoint(camera.CFrame:PointToWorldSpace(camera.CFrame:PointToObjectSpace(pos)))
	return Vector2.new(newpos.X, newpos.Y)
end

local function CalculateLine(startVector, endVector, obj)
	local Distance = (startVector - endVector).Magnitude
	obj.Size = UDim2.new(0, Distance, 0, 2)
	obj.Position = UDim2.new(0, (startVector.X + endVector.X) / 2, 0, ((startVector.Y + endVector.Y) / 2) - 36)
	obj.Rotation = math.atan2(endVector.Y - startVector.Y, endVector.X - startVector.X) * (180 / math.pi)
end

local oldpos = Vector3.new(0, 0, 0)

local function getScaffold(vec, diagonaltoggle)
	local realvec = Vector3.new(
		math.floor((vec.X / 3) + 0.5) * 3,
		math.floor((vec.Y / 3) + 0.5) * 3,
		math.floor((vec.Z / 3) + 0.5) * 3
	)
	local newpos = (oldpos - realvec)
	if isAlive() then
		local angle = math.deg(
			math.atan2(-LocalPlayer.Character.Humanoid.MoveDirection.X, -LocalPlayer.Character.Humanoid.MoveDirection.Z)
		)
		local goingdiagonal = (angle >= 130 and angle <= 150)
			or (angle <= -35 and angle >= -50)
			or (angle >= 35 and angle <= 50)
			or (angle <= -130 and angle >= -150)
		if
			goingdiagonal
			and ((newpos.X == 0 and newpos.Z ~= 0) or (newpos.X ~= 0 and newpos.Z == 0))
			and diagonaltoggle
		then
			return oldpos
		end
	end
	return realvec
end

GuiLibrary.SelfDestructEvent.Event:Connect(function()
	if chatconnection then
		chatconnection:Disconnect()
	end
	for i3, v3 in pairs(connectionstodisconnect) do
		if v3.Disconnect then
			v3:Disconnect()
		end
	end
end)

local function getSword()
	for _, v in ipairs(skywars.HotbarController:getHotbarItems()) do
		local item = skywars.ItemTable[v.Type]
		if item.Melee then
			return item
		end
	end
	return nil
end

local function getPickaxe()
	for _, v in ipairs(skywars.HotbarController:getHotbarItems()) do
		local item = skywars.ItemTable[v.Type]
		if item.Pickaxe then
			return item
		end
	end
	return nil
end

local function getItem(itemname)
	for _, v in ipairs(skywars.HotbarController:getHotbarItems()) do
		if v.Type == itemname then
			local item = skywars.ItemTable[v.Type]
			if item then
				return item, v
			end
		end
	end
	return nil, nil
end

local function getBlock()
	for _, v in ipairs(skywars.HotbarController:getHotbarItems()) do
		local item = skywars.ItemTable[v.Type]
		if item.Block then
			return item, v
		end
	end
	return nil, nil
end

local function getHeldItem()
	local item = skywars.HotbarController:getHeldItemInfo()
	return item, item and item.Name or nil
end

local function equipItem(itemname)
	skywars.EventHandler[skywars.Events.HotbarController.updateActiveItem[1]]:fire(itemname)
end

GuiLibrary.RemoveObject("AutoClickerOptionsButton")

runcode(function()
	local autoclickercps = {
		GetRandomValue = function()
			return 1
		end,
	}
	local autoclicker = { Enabled = false }
	local autoclickertick = tick()
	local autoclickermousedown = false
	local autoclickerconnection1
	local autoclickerconnection2
	autoclicker = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "AutoClicker",
		Function = function(callback)
			if callback then
				autoclickerconnection1 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						autoclickermousedown = true
					end
				end)
				autoclickerconnection2 = UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						autoclickermousedown = false
					end
				end)
				BindToRenderStep("AutoClicker", 1, function()
					if
						isAlive()
						and autoclickermousedown
						and autoclickertick <= tick()
						and not GuiLibrary.MainGui.ScaledGui.ClickGui.Visible
					then
						autoclickertick = tick() + (1 / autoclickercps.GetRandomValue())
						if
							skywars.HotbarController:getHeldItemInfo()
							and skywars.HotbarController:getHeldItemInfo().Melee
						then
							skywars.MeleeController:strike({
								UserInputType = Enum.UserInputType.MouseButton1,
							})
						end
					end
				end)
			else
				if autoclickerconnection1 then
					autoclickerconnection1:Disconnect()
				end
				if autoclickerconnection2 then
					autoclickerconnection2:Disconnect()
				end
				UnbindFromRenderStep("AutoClicker")
			end
		end,
		HoverText = "Hold attack button to automatically click",
	})
	autoclickercps = autoclicker.CreateTwoSlider({
		Name = "CPS",
		Min = 1,
		Max = 20,
		Function = function() end,
		Default = 8,
		Default2 = 12,
	})
end)

runcode(function()
	local Velocity = { Enabled = false }
	local Horizontal = { Value = 100 }
	local Vertical = { Value = 100 }
	local Hori = Horizontal.Value / 100
	local Verti = Vertical.Value / 100
	local events = ReplicatedStorage["events-ZLx"]
	---@type RemoteEvent
	local event = events[skywars.Events.PlayerVelocityController.onStart[1]]
	local target = getconnections(event.OnClientEvent)[1]
	local old

	Velocity = GuiLibrary.ObjectsThatCanBeSaved.CombatWindow.Api.CreateOptionsButton({
		Name = "Velocity",
		Function = function(state)
			if not state then
				return
			end
			old = hookfunction(target.Function, function(vec)
				if not Velocity.Enabled then
					return old(vec)
				end
				if Horizontal.Value == 0 and Horizontal.Value == 0 then
					return
				end
				vec = Vector3.new(vec.X / Hori, vec.Y / Verti, vec.Z / Hori)
				return old(vec)
			end)
		end,
		HoverText = "Reduces knockback taken",
	})
	Horizontal = Velocity.CreateSlider({
		Name = "Horizontal",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function()
			Hori = Horizontal.Value / 100
		end,
		Default = 0,
	})
	Vertical = Velocity.CreateSlider({
		Name = "Vertical",
		Min = 0,
		Max = 100,
		Percent = true,
		Function = function()
			Verti = Vertical.Value / 100
		end,
		Default = 0,
	})
end)

local Killaura = { Enabled = false }
local Scaffold = { Enabled = false }
GuiLibrary.RemoveObject("KillauraOptionsButton")
GuiLibrary.RemoveObject("HitBoxesOptionsButton")
runcode(function()
	local killaurabox = Instance.new("BoxHandleAdornment")
	killaurabox.Transparency = 0.5
	killaurabox.Color3 = Color3.new(1, 0, 0)
	killaurabox.Adornee = nil
	killaurabox.AlwaysOnTop = true
	killaurabox.Size = Vector3.new(3, 6, 3)
	killaurabox.ZIndex = 11
	killaurabox.Parent = GuiLibrary.MainGui
	local killauratargetframe = { Players = { Enabled = false } }
	local killaurarange = { Value = 14 }
	local killauratargets = { Value = 10 }
	local killauramouse = { Enabled = false }
	local killauratarget = { Enabled = false }
	local killauraswing = { Enabled = false }
	local killaurahandcheck = { Enabled = false }
	-- local killauradelay = tick()
	Killaura = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Killaura",
		Function = function(callback)
			if callback then
				BindToStepped("Killaura", 1, function()
					if not killauratargetframe.Players.Enabled then
						return
					end
					local plrs =
						AllNearPosition(killaurarange.Value + 0.5, killauratargets.Value, { Prediction = true })
					local handcheck = (
						killaurahandcheck.Enabled
							and skywars.HotbarController:getHeldItemInfo()
							and skywars.HotbarController:getHeldItemInfo().Melee
						or not killaurahandcheck.Enabled
					)
					targetInfo.Targets.Killaura = nil
					for _, plr in pairs(plrs) do
						if handcheck then
							targetInfo.Targets.Killaura = {
								Player = plr.Player,
								Humanoid = {
									Health = (skywars.HealthController:getHealth(plr) or 100),
									MaxHealth = 100,
								},
							}
						end
					end
					if killauratarget.Enabled and #plrs > 0 and handcheck then
						killaurabox.Adornee = (killauratarget.Enabled and plrs[#plrs].Character or nil)
					else
						killaurabox.Adornee = nil
					end
					if
						-- killauradelay <= tick()
						--[[and]]
						(
							killauramouse.Enabled and UserInputService:IsMouseButtonPressed(0)
							or not killauramouse.Enabled
						) and handcheck
					then
						local sword = getSword()
						if (not killauraswing.Enabled) and #plrs > 0 and handcheck then
							skywars.MeleeController:playAnimation(sword)
						end
						local _, olditemname = getHeldItem()
						if sword then
							for _, plr in pairs(plrs) do
								equipItem(sword.Name)
								skywars.EventHandler[skywars.Events.MeleeController.strikeDesktop[1]]:fire(plr.Player)
								equipItem(olditemname)
							end
						end
						-- killauradelay = tick() + 0.1
					end
				end)
			else
				UnbindFromStepped("Killaura")
				targetInfo.Targets.Killaura = nil
			end
		end,
	})
	killauratargetframe = Killaura.CreateTargetWindow({})
	killaurarange = Killaura.CreateSlider({
		Name = "Attack range",
		Min = 1,
		Max = 13,
		Function = function(val) end,
		Default = 13,
	})
	killauratargets = Killaura.CreateSlider({
		Name = "Max targets",
		Min = 1,
		Max = 10,
		Function = function(val) end,
		Default = 10,
	})
	killauramouse = Killaura.CreateToggle({
		Name = "Require mouse down",
		Function = function() end,
		HoverText = "Only attacks when left click is held.",
		Default = false,
	})
	killauratarget = Killaura.CreateToggle({
		Name = "Show target",
		Function = function() end,
		HoverText = "Shows a red box over the opponent.",
	})
	killauraswing = Killaura.CreateToggle({
		Name = "No Swing",
		Function = function() end,
		HoverText = "Removes the swinging animation.",
	})
	killaurahandcheck = Killaura.CreateToggle({
		Name = "Limit to items",
		Function = function() end,
		HoverText = "Only attacks when your sword is held.",
	})
end)

runcode(function()
	local scaffoldtext = Instance.new("TextLabel")
	scaffoldtext.Font = Enum.Font.SourceSans
	scaffoldtext.TextSize = 20
	scaffoldtext.BackgroundTransparency = 1
	scaffoldtext.TextColor3 = Color3.fromRGB(255, 0, 0)
	scaffoldtext.Size = UDim2.new(0, 0, 0, 0)
	scaffoldtext.Position = UDim2.new(0.5, 0, 0.5, 30)
	scaffoldtext.Text = "0"
	scaffoldtext.Visible = false
	scaffoldtext.Parent = GuiLibrary.MainGui

	local ScaffoldExpand = { Value = 1 }
	local ScaffoldDiagonal = { Enabled = false }
	local ScaffoldTower = { Enabled = false }
	local ScaffoldDownwards = { Enabled = false }
	local ScaffoldStopMotion = { Enabled = false }
	local ScaffoldBlockCount = { Enabled = false }
	local ScaffoldHandCheck = { Enabled = false }
	local scaffoldstopmotionval = false
	local scaffoldstopmotionpos = Vector3.new(0, 0, 0)
	local oldpos
	Scaffold = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Scaffold",
		Function = function(callback)
			if callback then
				scaffoldtext.Visible = ScaffoldBlockCount.Enabled
				BindToStepped("Scaffold", 1, function()
					local helditem = skywars.HotbarController:getHeldItemInfo()
					local handcheck = (
						ScaffoldHandCheck.Enabled and helditem and helditem.Block or not ScaffoldHandCheck.Enabled
					)
					local block, otherblock = getBlock()
					if helditem and helditem.Block then
						block, otherblock = getItem(helditem.Name)
					end

					if block and isAlive() and handcheck then
						if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
							if not scaffoldstopmotionval then
								scaffoldstopmotionval = true
								scaffoldstopmotionpos = LocalPlayer.Character.HumanoidRootPart.CFrame.Position
							end
						else
							scaffoldstopmotionval = false
						end
						local woolamount = otherblock.Quantity
						scaffoldtext.Text = (woolamount and tostring(woolamount) or "0")
						if woolamount then
							if woolamount >= 128 then
								scaffoldtext.TextColor3 = Color3.fromRGB(9, 255, 198)
							elseif woolamount >= 64 then
								scaffoldtext.TextColor3 = Color3.fromRGB(255, 249, 18)
							else
								scaffoldtext.TextColor3 = Color3.fromRGB(255, 0, 0)
							end
						end
						if
							ScaffoldTower.Enabled
							and UserInputService:IsKeyDown(Enum.KeyCode.Space)
							and not UserInputService:GetFocusedTextBox()
						then
							LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 50, 0)
							if ScaffoldStopMotion.Enabled and scaffoldstopmotionval then
								LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
									Vector3.new(
										scaffoldstopmotionpos.X,
										LocalPlayer.Character.HumanoidRootPart.CFrame.Y,
										scaffoldstopmotionpos.Z
									)
								)
							end
						end
						for i = 1, ScaffoldExpand.Value do
							local newpos = getScaffold(
								(
									LocalPlayer.Character.Head.Position
									+ (
										(
											not scaffoldstopmotionval
												and LocalPlayer.Character.Humanoid.MoveDirection
											or Vector3.new(0, 0, 0)
										) * (i * 3.5)
									)
								)
									+ Vector3.new(
										0,
										-math.floor(
											LocalPlayer.Character.Humanoid.HipHeight
												* (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and ScaffoldDownwards["Enabled"] and 5 or 3)
												* (LocalPlayer.Character:GetAttribute("Transparency") and 1.1 or 1)
										),
										0
									),
								ScaffoldDiagonal.Enabled and (LocalPlayer.Character.HumanoidRootPart.Velocity.Y < 2)
							)
							newpos = Vector3.new(
								newpos.X,
								math.clamp(
									newpos.Y
										- (
											UserInputService:IsKeyDown(Enum.KeyCode.Space)
												and ScaffoldTower.Enabled
												and 4
											or 0
										),
									-999,
									999
								),
								newpos.Z
							)
							if newpos ~= oldpos then
								skywars.BlockController:placeBlock(newpos, {
									ToolRef = nil,
									Block = block,
								})
							end
						end
					end
				end)
			else
				UnbindFromStepped("Scaffold")
				scaffoldtext.Visible = false
			end
		end,
	})
	ScaffoldExpand = Scaffold.CreateSlider({
		Name = "Expand",
		Min = 1,
		Max = 8,
		Function = function(val) end,
		Default = 1,
		HoverText = "Build range",
	})
	ScaffoldDiagonal = Scaffold.CreateToggle({
		Name = "Diagonal",
		Function = function(callback) end,
		Default = true,
	})
	ScaffoldTower = Scaffold.CreateToggle({
		Name = "Tower",
		Function = function(callback)
			if ScaffoldStopMotion.Object then
				ScaffoldTower.Object.ToggleArrow.Visible = callback
				ScaffoldStopMotion["Object"].Visible = callback
			end
		end,
	})
	ScaffoldDownwards = Scaffold.CreateToggle({
		Name = "Downwards",
		Function = function(callback) end,
		HoverText = "Goes down when left shift is held.",
	})
	ScaffoldStopMotion = Scaffold.CreateToggle({
		Name = "Stop Motion",
		Function = function() end,
		HoverText = "Stops your movement when going up",
	})
	ScaffoldStopMotion.Object.BackgroundTransparency = 0
	ScaffoldStopMotion.Object.BorderSizePixel = 0
	ScaffoldStopMotion.Object.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	ScaffoldStopMotion.Object.Visible = ScaffoldTower["Enabled"]
	ScaffoldBlockCount = Scaffold.CreateToggle({
		Name = "Block Count",
		Function = function(callback)
			if Scaffold.Enabled then
				scaffoldtext.Visible = callback
			end
		end,
		HoverText = "Shows the amount of blocks in the middle.",
	})
	ScaffoldHandCheck = Scaffold.CreateToggle({
		Name = "Whitelist Only",
		Function = function() end,
		HoverText = "Only builds with blocks in your hand.",
	})
end)

runcode(function()
	local ChestOpen
	local ChestStealer = { Enabled = false }
	local ChestStealRange = { Value = 40 }
	local ChestBlacklist = {}
	ChestStealer = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "ChestStealer",
		Function = function(callback)
			if callback then
				ChestOpen = skywars.EventHandler[skywars.Events.ChestController.onStart[1]]:connect(
					function(chest, items)
						if not ChestBlacklist[chest] then
							ChestBlacklist[chest] = true
							for i, v in pairs(items) do
								skywars.EventHandler[skywars.Events.ChestController.updateChest[1]](
									chest,
									v.Type,
									-v.Quantity
								)
							end
							skywars.EventHandler[skywars.Events.ChestController.closeChest[1]](chest)
						end
					end
				)
				task.spawn(function()
					repeat
						task.wait(0.3)
						if isAlive() then
							for _, v in CollectionService:GetTagged("block:chest") do
								if v.PrimaryPart then
									if
										(LocalPlayer.Character.HumanoidRootPart.Position - v.PrimaryPart.Position).magnitude
											<= ChestStealRange.Value
										and not ChestBlacklist[v]
									then
										skywars.EventHandler[skywars.Events.ChestController.openChest[1]](v)
									end
								end
							end
						end
					until not ChestStealer.Enabled
				end)
			else
				if ChestOpen then
					ChestOpen:Disconnect()
				end
			end
		end,
	})
	ChestStealRange = ChestStealer.CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 20,
		Function = function() end,
		Default = 10,
	})

	local DropStealer = { Enabled = false, Connection = nil }
	local DropStealRange = { Value = 20 }
	local DropStealInfinite = { Enabled = false }
	local oldCFrame = CFrame.new()
	local oldPosition = oldCFrame.Position
	local isStealing = false
	local function handleDrop(drop)
		if not DropStealer.Enabled then
			return
		end
		--- @type Vector3
		local itemPosition = drop:GetPivot().Position
		local mag = (oldPosition - itemPosition).Magnitude
		if mag < DropStealRange.Value and not DropStealInfinite.Enabled then
			return
		end
		if not isStealing then
			oldCFrame = LocalPlayer.Character:GetPivot()
			oldPosition = oldCFrame.Position
		end
		isStealing = true
		LocalPlayer.Character:PivotTo(drop:GetPivot())
		task.wait(0.2)
		LocalPlayer.Character:PivotTo(oldCFrame)
		isStealing = false
	end
	DropStealer = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "DropStealer",
		Function = function(callback)
			if not callback and DropStealer.Connection then
				return DropStealer.Connection:Disconnect()
			end
			task.spawn(function()
				if isAlive() then
					for _, item in CollectionService:GetTagged("item") do
						handleDrop(item)
					end
					DropStealer.Connection = CollectionService:GetInstanceAddedSignal("item"):Connect(handleDrop)
				end
			end)
		end,
	})
	DropStealRange = DropStealer.CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 100,
		Function = function() end,
		Default = 40,
	})
	DropStealInfinite = DropStealer.CreateToggle({
		Name = "Infinite Range",
		Function = function(state)
			DropStealRange.Object.Visible = not state
		end,
		Default = false,
	})
end)

runcode(function()
	local Funny = { Connection = nil }
	local oldCFrame = CFrame.new()
	local ChestBlacklist = {}
	local ChestOpen

	---@param chest Model
	local function handleChest(chest)
		if not LocalPlayer.Character or not chest then
			return
		end
		oldCFrame = LocalPlayer.Character:GetPivot()
		local position = chest:GetPivot()
		position = CFrame.new(position.X, position.Y + 5, position.Z)
		LocalPlayer.Character:PivotTo(position)
		task.wait()
		if not ChestBlacklist[chest] then
			skywars.EventHandler[skywars.Events.ChestController.openChest[1]](chest)
		end
		task.wait(0.1)
		LocalPlayer.Character:PivotTo(oldCFrame)
	end

	Funny = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Funny",
		Function = function(state)
			if not state then
				if Funny.Connection then
					Funny.Connection:Disconnect()
				end

				if ChestOpen then
					ChestOpen:Disconnect()
				end
			end

			ChestOpen = skywars.EventHandler[skywars.Events.ChestController.onStart[1]]:connect(function(chest, items)
				if not Funny.Enabled then
					return
				end
				if not ChestBlacklist[chest] then
					ChestBlacklist[chest] = true
					for _, v in items do
						skywars.EventHandler[skywars.Events.ChestController.updateChest[1]](chest, v.Type, -v.Quantity)
					end
					skywars.EventHandler[skywars.Events.ChestController.closeChest[1]](chest)
				end
			end)

			Funny.Connection = CollectionService:GetInstanceAddedSignal("block:chest"):Connect(handleChest)

			for _, chest in CollectionService:GetTagged("block:chest") do
				if not Funny.Enabled then
					break
				end
				handleChest(chest)
			end
		end,
	})
end)

GuiLibrary.RemoveObject("TargetStrafeOptionsButton")

runcode(function()
	local TargetStrafe = { Enabled = false }
	local Range = { Value = 0 }
	local TeamCheck = { Enabled = false }
	local oldMove
	local controlModule
	TargetStrafe = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "TargetStrafe",
		Function = function(callback)
			if callback then
				if not controlModule then
					local suc = pcall(function()
						controlModule = require(PlayerScripts.PlayerModule).controls
					end)
					if not suc then
						controlModule = {}
					end
				end
				oldMove = controlModule.moveFunction
				controlModule.moveFunction = function(self, vec, facecam, ...)
					if not entityLibrary.isAlive then
						return oldMove(self, vec, facecam, ...)
					end
					local plr = EntityNearPosition(Range.Value, {
						TeamCheck = TeamCheck.Enabled,
					})

					if not plr then
						return oldMove(self, vec, facecam, ...)
					end

					facecam = false
					--code stolen from roblox since the way I tried to make it apparently sucks
					local c, s
					local targetCFrame = CFrame.lookAt(
						entityLibrary.character.HumanoidRootPart.Position,
						Vector3.new(plr.RootPart.Position.X, 0, plr.RootPart.Position.Z)
					)
					local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = targetCFrame:GetComponents()
					if R12 < 1 and R12 > -1 then
						c = R22
						s = R02
					else
						c = R00
						s = -R01 * math.sign(R12)
					end
					local norm = math.sqrt(c * c + s * s)
					local cameraRelativeMoveVector = controlModule:GetMoveVector()
					vec = Vector3.new(
						(c * cameraRelativeMoveVector.X + s * cameraRelativeMoveVector.Z) / norm,
						0,
						(c * cameraRelativeMoveVector.Z - s * cameraRelativeMoveVector.X) / norm
					)
					return oldMove(self, vec, facecam, ...)
				end
			else
				controlModule.moveFunction = oldMove
			end
		end,
	})
	Range = TargetStrafe.CreateSlider({
		Name = "Range",
		Function = function() end,
		Min = 0,
		Max = 100,
		Default = 14,
	})

	TeamCheck = TargetStrafe.CreateToggle({
		Name = "Team Check",
		Function = function() end,
		Default = true,
	})
end)

runcode(function()
	local AutoReport = { Enabled = false }
	local oldplr
	AutoReport = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoReport",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.2 + (math.random(1, 10) / 10))
						local plr
						repeat
							task.wait()
							plr = Players:GetPlayers()[math.random(1, #Players:GetPlayers())]
						until plr ~= oldplr and plr ~= LocalPlayer
						skywars.EventHandler[skywars.Events.ReportController.submitReport[1]]:fire(plr.UserId)
					until not AutoReport.Enabled
				end)
			end
		end,
	})
end)

local function HealthbarColorTransferFunction(healthPercent)
	local healthColorToPosition = {
		[Vector3.new(Color3.fromRGB(255, 28, 0).R, Color3.fromRGB(255, 28, 0).G, Color3.fromRGB(255, 28, 0).B)] = 0.1,
		[Vector3.new(Color3.fromRGB(250, 235, 0).R, Color3.fromRGB(250, 235, 0).G, Color3.fromRGB(250, 235, 0).B)] = 0.5,
		[Vector3.new(Color3.fromRGB(27, 252, 107).R, Color3.fromRGB(27, 252, 107).G, Color3.fromRGB(27, 252, 107).B)] = 0.8,
	}
	local min = 0.1
	local minColor = Color3.fromRGB(255, 28, 0)
	local max = 0.8
	local maxColor = Color3.fromRGB(27, 252, 107)
	if healthPercent < min then
		return minColor
	elseif healthPercent > max then
		return maxColor
	end

	local numeratorSum = Vector3.new(0, 0, 0)
	local denominatorSum = 0
	for colorSampleValue, samplePoint in pairs(healthColorToPosition) do
		local distance = healthPercent - samplePoint
		if distance == 0 then
			return Color3.new(colorSampleValue.X, colorSampleValue.Y, colorSampleValue.Z)
		else
			local wi = 1 / (distance * distance)
			numeratorSum = numeratorSum + wi * colorSampleValue
			denominatorSum = denominatorSum + wi
		end
	end
	local result = numeratorSum / denominatorSum
	return Color3.new(result.X, result.Y, result.Z)
end

-- GuiLibrary.RemoveObject("ESPOptionsButton")

-- runcode(function()
-- 	local ESPColor = {Value = 0.44}
-- 	local ESPHealthBar = {Enabled = false}
-- 	local ESPBoundingBox = {Enabled = true}
-- 	local ESPName = {Enabled = true}
-- 	local ESPMethod = {Value = "2D"}
-- 	local ESPTeammates = {Enabled = true}
-- 	local espfolderdrawing = {}
-- 	local espconnections = {}
-- 	local methodused

-- 	local function floorESPPosition(pos)
-- 		return Vector2.new(math.floor(pos.X), math.floor(pos.Y))
-- 	end

-- 	local function ESPWorldToViewport(pos)
-- 		local newpos = worldtoviewportpoint(camera.CFrame:pointToWorldSpace(camera.CFrame:pointToObjectSpace(pos)))
-- 		return Vector2.new(newpos.X, newpos.Y)
-- 	end

-- 	local espfuncs1 = {
-- 		Drawing2D = function(plr)
-- 			if ESPTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
-- 			local thing = {}
-- 			thing.Quad1 = Drawing.new("Square")
-- 			thing.Quad1.Transparency = ESPBoundingBox.Enabled and 1 or 0
-- 			thing.Quad1.ZIndex = 2
-- 			thing.Quad1.Filled = false
-- 			thing.Quad1.Thickness = 1
-- 			thing.Quad1.Color = getPlayerColor(plr.Player) or Color3.fromHSV(ESPColor.Hue, ESPColor.Sat, ESPColor.Value)
-- 			thing.QuadLine2 = Drawing.new("Square")
-- 			thing.QuadLine2.Transparency = ESPBoundingBox.Enabled and 0.5 or 0
-- 			thing.QuadLine2.ZIndex = 1
-- 			thing.QuadLine2.Thickness = 1
-- 			thing.QuadLine2.Filled = false
-- 			thing.QuadLine2.Color = Color3.new()
-- 			thing.QuadLine3 = Drawing.new("Square")
-- 			thing.QuadLine3.Transparency = ESPBoundingBox.Enabled and 0.5 or 0
-- 			thing.QuadLine3.ZIndex = 1
-- 			thing.QuadLine3.Thickness = 1
-- 			thing.QuadLine3.Filled = false
-- 			thing.QuadLine3.Color = Color3.new()
-- 			if ESPHealthBar.Enabled then
-- 				thing.Quad3 = Drawing.new("Line")
-- 				thing.Quad3.Thickness = 1
-- 				thing.Quad3.ZIndex = 2
-- 				thing.Quad3.Color = Color3.new(0, 1, 0)
-- 				thing.Quad4 = Drawing.new("Line")
-- 				thing.Quad4.Thickness = 3
-- 				thing.Quad4.Transparency = 0.5
-- 				thing.Quad4.ZIndex = 1
-- 				thing.Quad4.Color = Color3.new()
-- 			end
-- 			if ESPName.Enabled then
-- 				thing.Drop = Drawing.new("Text")
-- 				thing.Drop.Color = Color3.new()
-- 				thing.Drop.Text = (plr.Player.DisplayName or plr.Player.Name)
-- 				thing.Drop.ZIndex = 1
-- 				thing.Drop.Center = true
-- 				thing.Drop.Size = 20
-- 				thing.Text = Drawing.new("Text")
-- 				thing.Text.Text = thing.Drop.Text
-- 				thing.Text.ZIndex = 2
-- 				thing.Text.Color = thing.Quad1.Color
-- 				thing.Text.Center = true
-- 				thing.Text.Size = 20
-- 			end
-- 			espfolderdrawing[plr.Player] = {entity = plr, Main = thing}
-- 		end,
-- 		DrawingSkeleton = function(plr)
-- 			if ESPTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
-- 			local thing = {}
-- 			thing.Head = Drawing.new("Line")
-- 			thing.Head2 = Drawing.new("Line")
-- 			thing.Torso = Drawing.new("Line")
-- 			thing.Torso2 = Drawing.new("Line")
-- 			thing.Torso3 = Drawing.new("Line")
-- 			thing.LeftArm = Drawing.new("Line")
-- 			thing.RightArm = Drawing.new("Line")
-- 			thing.LeftLeg = Drawing.new("Line")
-- 			thing.RightLeg = Drawing.new("Line")
-- 			local color = getPlayerColor(plr.Player) or Color3.fromHSV(ESPColor.Hue, ESPColor.Sat, ESPColor.Value)
-- 			for i,v in pairs(thing) do v.Thickness = 2 v.Color = color end
-- 			espfolderdrawing[plr.Player] = {entity = plr, Main = thing}
-- 		end,
-- 		Drawing3D = function(plr)
-- 			if ESPTeammates.Enabled and (not plr.Targetable) and (not plr.Friend) then return end
-- 			local thing = {}
-- 			thing.Line1 = Drawing.new("Line")
-- 			thing.Line2 = Drawing.new("Line")
-- 			thing.Line3 = Drawing.new("Line")
-- 			thing.Line4 = Drawing.new("Line")
-- 			thing.Line5 = Drawing.new("Line")
-- 			thing.Line6 = Drawing.new("Line")
-- 			thing.Line7 = Drawing.new("Line")
-- 			thing.Line8 = Drawing.new("Line")
-- 			thing.Line9 = Drawing.new("Line")
-- 			thing.Line10 = Drawing.new("Line")
-- 			thing.Line11 = Drawing.new("Line")
-- 			thing.Line12 = Drawing.new("Line")
-- 			local color = getPlayerColor(plr.Player) or Color3.fromHSV(ESPColor.Hue, ESPColor.Sat, ESPColor.Value)
-- 			for i,v in pairs(thing) do v.Thickness = 1 v.Color = color end
-- 			espfolderdrawing[plr.Player] = {entity = plr, Main = thing}
-- 		end
-- 	}
-- 	local espfuncs2 = {
-- 		Drawing2D = function(ent)
-- 			local v = espfolderdrawing[ent]
-- 			espfolderdrawing[ent] = nil
-- 			if v then
-- 				for i2,v2 in pairs(v.Main) do
-- 					pcall(function() v2.Visible = false v2:Remove() end)
-- 				end
-- 			end
-- 		end,
-- 		Drawing3D = function(ent)
-- 			local v = espfolderdrawing[ent]
-- 			espfolderdrawing[ent] = nil
-- 			if v then
-- 				for i2,v2 in pairs(v.Main) do
-- 					pcall(function() v2.Visible = false v2:Remove() end)
-- 				end
-- 			end
-- 		end,
-- 		DrawingSkeleton = function(ent)
-- 			local v = espfolderdrawing[ent]
-- 			espfolderdrawing[ent] = nil
-- 			if v then
-- 				for i2,v2 in pairs(v.Main) do
-- 					pcall(function() v2.Visible = false v2:Remove() end)
-- 				end
-- 			end
-- 		end
-- 	}
-- 	local espupdatefuncs = {
-- 		Drawing2D = function(ent)
-- 			local v = espfolderdrawing[ent.Player]
-- 			if v and v.Main.Quad3 then
-- 				local color = Color3.fromHSV(math.clamp(ent.Humanoid.Health / ent.Humanoid.MaxHealth, 0, 1) / 2.5, 0.89, 1)
-- 				v.Main.Quad3.Color = color
-- 			end
-- 			if v and v.Text then
-- 				v.Text.Text = (ent.Player.DisplayName or ent.Player.Name)
-- 				v.Drop.Text = v.Text.Text
-- 			end
-- 		end
-- 	}
-- 	local espcolorfuncs = {
-- 		Drawing2D = function(hue, sat, value)
-- 			local color = Color3.fromHSV(hue, sat, value)
-- 			for i,v in pairs(espfolderdrawing) do
-- 				v.Main.Quad1.Color = getPlayerColor(v.entity.Player) or color
-- 				if v.Main.Text then
-- 					v.Main.Text.Color = v.Main.Quad1.Color
-- 				end
-- 			end
-- 		end,
-- 		Drawing3D = function(hue, sat, value)
-- 			local color = Color3.fromHSV(hue, sat, value)
-- 			for i,v in pairs(espfolderdrawing) do
-- 				local newcolor = getPlayerColor(v.entity.Player) or color
-- 				for i2,v2 in pairs(v.Main) do
-- 					v2.Color = newcolor
-- 				end
-- 			end
-- 		end,
-- 		DrawingSkeleton = function(hue, sat, value)
-- 			local color = Color3.fromHSV(hue, sat, value)
-- 			for i,v in pairs(espfolderdrawing) do
-- 				local newcolor = getPlayerColor(v.entity.Player) or color
-- 				for i2,v2 in pairs(v.Main) do
-- 					v2.Color = newcolor
-- 				end
-- 			end
-- 		end,
-- 	}
-- 	local esploop = {
-- 		Drawing2D = function()
-- 			for i,v in pairs(espfolderdrawing) do
-- 				local rootPos, rootVis = worldtoviewportpoint(v.entity.RootPart.Position)
-- 				if not rootVis then
-- 					v.Main.Quad1.Visible = false
-- 					v.Main.QuadLine2.Visible = false
-- 					v.Main.QuadLine3.Visible = false
-- 					if v.Main.Quad3 then
-- 						v.Main.Quad3.Visible = false
-- 						v.Main.Quad4.Visible = false
-- 					end
-- 					if v.Main.Text then
-- 						v.Main.Text.Visible = false
-- 						v.Main.Drop.Visible = false
-- 					end
-- 					continue
-- 				end
-- 				local topPos, topVis = worldtoviewportpoint((CFrame.new(v.entity.RootPart.Position, v.entity.RootPart.Position + camera.CFrame.lookVector) * CFrame.new(2, 3, 0)).p)
-- 				local bottomPos, bottomVis = worldtoviewportpoint((CFrame.new(v.entity.RootPart.Position, v.entity.RootPart.Position + camera.CFrame.lookVector) * CFrame.new(-2, -3.5, 0)).p)
-- 				local sizex, sizey = topPos.X - bottomPos.X, topPos.Y - bottomPos.Y
-- 				local posx, posy = (rootPos.X - sizex / 2),  ((rootPos.Y - sizey / 2))
-- 				v.Main.Quad1.Position = floorESPPosition(Vector2.new(posx, posy))
-- 				v.Main.Quad1.Size = floorESPPosition(Vector2.new(sizex, sizey))
-- 				v.Main.Quad1.Visible = true
-- 				v.Main.QuadLine2.Position = floorESPPosition(Vector2.new(posx - 1, posy + 1))
-- 				v.Main.QuadLine2.Size = floorESPPosition(Vector2.new(sizex + 2, sizey - 2))
-- 				v.Main.QuadLine2.Visible = true
-- 				v.Main.QuadLine3.Position = floorESPPosition(Vector2.new(posx + 1, posy - 1))
-- 				v.Main.QuadLine3.Size = floorESPPosition(Vector2.new(sizex - 2, sizey + 2))
-- 				v.Main.QuadLine3.Visible = true
-- 				if v.Main.Quad3 then
-- 					local healthposy = sizey * math.clamp(v.entity.Humanoid.Health / v.entity.Humanoid.MaxHealth, 0, 1)
-- 					v.Main.Quad3.Visible = v.entity.Humanoid.Health > 0
-- 					v.Main.Quad3.From = floorESPPosition(Vector2.new(posx - 4, posy + (sizey - (sizey - healthposy))))
-- 					v.Main.Quad3.To = floorESPPosition(Vector2.new(posx - 4, posy))
-- 					v.Main.Quad4.Visible = true
-- 					v.Main.Quad4.From = floorESPPosition(Vector2.new(posx - 4, posy))
-- 					v.Main.Quad4.To = floorESPPosition(Vector2.new(posx - 4, (posy + sizey)))
-- 				end
-- 				if v.Main.Text then
-- 					v.Main.Text.Visible = true
-- 					v.Main.Drop.Visible = true
-- 					v.Main.Text.Position = floorESPPosition(Vector2.new(posx + (sizex / 2), posy + (sizey - 25)))
-- 					v.Main.Drop.Position = v.Main.Text.Position + Vector2.new(1, 1)
-- 				end
-- 			end
-- 		end,
-- 		Drawing3D = function()
-- 			for i,v in pairs(espfolderdrawing) do
-- 				local rootPos, rootVis = worldtoviewportpoint(v.entity.RootPart.Position)
-- 				if not rootVis then
-- 					for i,v in pairs(v.Main) do
-- 						v.Visible = false
-- 					end
-- 					continue
-- 				end
-- 				for i,v in pairs(v.Main) do
-- 					v.Visible = true
-- 				end
-- 				local point1 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(1.5, 3, 1.5))
-- 				local point2 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(1.5, -3, 1.5))
-- 				local point3 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(-1.5, 3, 1.5))
-- 				local point4 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(-1.5, -3, 1.5))
-- 				local point5 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(1.5, 3, -1.5))
-- 				local point6 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(1.5, -3, -1.5))
-- 				local point7 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(-1.5, 3, -1.5))
-- 				local point8 = ESPWorldToViewport(v.entity.RootPart.Position + Vector3.new(-1.5, -3, -1.5))
-- 				v.Main.Line1.From = point1
-- 				v.Main.Line1.To = point2
-- 				v.Main.Line2.From = point3
-- 				v.Main.Line2.To = point4
-- 				v.Main.Line3.From = point5
-- 				v.Main.Line3.To = point6
-- 				v.Main.Line4.From = point7
-- 				v.Main.Line4.To = point8
-- 				v.Main.Line5.From = point1
-- 				v.Main.Line5.To = point3
-- 				v.Main.Line6.From = point1
-- 				v.Main.Line6.To = point5
-- 				v.Main.Line7.From = point5
-- 				v.Main.Line7.To = point7
-- 				v.Main.Line8.From = point7
-- 				v.Main.Line8.To = point3
-- 				v.Main.Line9.From = point2
-- 				v.Main.Line9.To = point4
-- 				v.Main.Line10.From = point2
-- 				v.Main.Line10.To = point6
-- 				v.Main.Line11.From = point6
-- 				v.Main.Line11.To = point8
-- 				v.Main.Line12.From = point8
-- 				v.Main.Line12.To = point4
-- 			end
-- 		end,
-- 		DrawingSkeleton = function()
-- 			for i,v in pairs(espfolderdrawing) do
-- 				local rootPos, rootVis = worldtoviewportpoint(v.entity.RootPart.Position)
-- 				if not rootVis then
-- 					for i,v in pairs(v.Main) do
-- 						v.Visible = false
-- 					end
-- 					continue
-- 				end
-- 				for i,v in pairs(v.Main) do
-- 					v.Visible = true
-- 				end
-- 				local rigcheck = v.entity.Humanoid.RigType == Enum.HumanoidRigType.R6
-- 				local head = ESPWorldToViewport((v.entity.Head.CFrame).p)
-- 				local headfront = ESPWorldToViewport((v.entity.Head.CFrame * CFrame.new(0, 0, -0.5)).p)
-- 				local toplefttorso = ESPWorldToViewport((v.entity.Character[(rigcheck and "Torso" or "UpperTorso")].CFrame * CFrame.new(-1.5, 0.8, 0)).p)
-- 				local toprighttorso = ESPWorldToViewport((v.entity.Character[(rigcheck and "Torso" or "UpperTorso")].CFrame * CFrame.new(1.5, 0.8, 0)).p)
-- 				local toptorso = ESPWorldToViewport((v.entity.Character[(rigcheck and "Torso" or "UpperTorso")].CFrame * CFrame.new(0, 0.8, 0)).p)
-- 				local bottomtorso = ESPWorldToViewport((v.entity.Character[(rigcheck and "Torso" or "UpperTorso")].CFrame * CFrame.new(0, -0.8, 0)).p)
-- 				local bottomlefttorso = ESPWorldToViewport((v.entity.Character[(rigcheck and "Torso" or "UpperTorso")].CFrame * CFrame.new(-0.5, -0.8, 0)).p)
-- 				local bottomrighttorso = ESPWorldToViewport((v.entity.Character[(rigcheck and "Torso" or "UpperTorso")].CFrame * CFrame.new(0.5, -0.8, 0)).p)
-- 				local leftarm = ESPWorldToViewport((v.entity.Character[(rigcheck and "Left Arm" or "LeftHand")].CFrame * CFrame.new(0, -0.8, 0)).p)
-- 				local rightarm = ESPWorldToViewport((v.entity.Character[(rigcheck and "Right Arm" or "RightHand")].CFrame * CFrame.new(0, -0.8, 0)).p)
-- 				local leftleg = ESPWorldToViewport((v.entity.Character[(rigcheck and "Left Leg" or "LeftFoot")].CFrame * CFrame.new(0, -0.8, 0)).p)
-- 				local rightleg = ESPWorldToViewport((v.entity.Character[(rigcheck and "Right Leg" or "RightFoot")].CFrame * CFrame.new(0, -0.8, 0)).p)
-- 				v.Main.Torso.From = toplefttorso
-- 				v.Main.Torso.To = toprighttorso
-- 				v.Main.Torso2.From = toptorso
-- 				v.Main.Torso2.To = bottomtorso
-- 				v.Main.Torso3.From = bottomlefttorso
-- 				v.Main.Torso3.To = bottomrighttorso
-- 				v.Main.LeftArm.From = toplefttorso
-- 				v.Main.LeftArm.To = leftarm
-- 				v.Main.RightArm.From = toprighttorso
-- 				v.Main.RightArm.To = rightarm
-- 				v.Main.LeftLeg.From = bottomlefttorso
-- 				v.Main.LeftLeg.To = leftleg
-- 				v.Main.RightLeg.From = bottomrighttorso
-- 				v.Main.RightLeg.To = rightleg
-- 				v.Main.Head.From = toptorso
-- 				v.Main.Head.To = head
-- 				v.Main.Head2.From = head
-- 				v.Main.Head2.To = headfront
-- 			end
-- 		end
-- 	}

-- 	local ESP = {Enabled = false}
-- 	ESP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
-- 		Name = "ESP",
-- 		Function = function(callback)
-- 			if callback then
-- 				methodused = "Drawing"..ESPMethod.Value
-- 				if espfuncs2[methodused] then
-- 					table.insert(ESP.Connections, entityLibrary.entityRemovedEvent:Connect(espfuncs2[methodused]))
-- 				end
-- 				if espfuncs1[methodused] then
-- 					local addfunc = espfuncs1[methodused]
-- 					for i,v in pairs(entityLibrary.entityList) do
-- 						if espfolderdrawing[v.Player] then espfuncs2[methodused](v.Player) end
-- 						addfunc(v)
-- 					end
-- 					table.insert(ESP.Connections, entityLibrary.entityAddedEvent:Connect(function(ent)
-- 						if espfolderdrawing[ent.Player] then espfuncs2[methodused](ent.Player) end
-- 						addfunc(ent)
-- 					end))
-- 				end
-- 				if espupdatefuncs[methodused] then
-- 					table.insert(ESP.Connections, entityLibrary.entityUpdatedEvent:Connect(espupdatefuncs[methodused]))
-- 					for i,v in pairs(entityLibrary.entityList) do
-- 						espupdatefuncs[methodused](v)
-- 					end
-- 				end
-- 				if espcolorfuncs[methodused] then
-- 					table.insert(ESP.Connections, GuiLibrary.ObjectsThatCanBeSaved.FriendsListTextCircleList.Api.FriendColorRefresh.Event:Connect(function()
-- 						espcolorfuncs[methodused](ESPColor.Hue, ESPColor.Sat, ESPColor.Value)
-- 					end))
-- 				end
-- 				if esploop[methodused] then
-- 					RunLoops:BindToRenderStep("ESP", esploop[methodused])
-- 				end
-- 			else
-- 				RunLoops:UnbindFromRenderStep("ESP")
-- 				if espfuncs2[methodused] then
-- 					for i,v in pairs(espfolderdrawing) do
-- 						espfuncs2[methodused](i)
-- 					end
-- 				end
-- 			end
-- 		end,
-- 		HoverText = "Extra Sensory Perception\nRenders an ESP on players."
-- 	})
-- 	ESPColor = ESP.CreateColorSlider({
-- 		Name = "Player Color",
-- 		Function = function(hue, sat, val)
-- 			if ESP.Enabled and espcolorfuncs[methodused] then
-- 				espcolorfuncs[methodused](hue, sat, val)
-- 			end
-- 		end
-- 	})
-- 	ESPMethod = ESP.CreateDropdown({
-- 		Name = "Mode",
-- 		List = {"2D", "3D", "Skeleton"},
-- 		Function = function(val)
-- 			if ESP.Enabled then ESP.ToggleButton(true) ESP.ToggleButton(true) end
-- 			ESPBoundingBox.Object.Visible = (val == "2D")
-- 			ESPHealthBar.Object.Visible = (val == "2D")
-- 			ESPName.Object.Visible = (val == "2D")
-- 		end,
-- 	})
-- 	ESPBoundingBox = ESP.CreateToggle({
-- 		Name = "Bounding Box",
-- 		Function = function() if ESP.Enabled then ESP.ToggleButton(true) ESP.ToggleButton(true) end end,
-- 		Default = true
-- 	})
-- 	ESPTeammates = ESP.CreateToggle({
-- 		Name = "Priority Only",
-- 		Function = function() if ESP.Enabled then ESP.ToggleButton(true) ESP.ToggleButton(true) end end,
-- 		Default = true
-- 	})
-- 	ESPHealthBar = ESP.CreateToggle({
-- 		Name = "Health Bar",
-- 		Function = function(callback) if ESP.Enabled then ESP.ToggleButton(true) ESP.ToggleButton(true) end end
-- 	})
-- 	ESPName = ESP.CreateToggle({
-- 		Name = "Name",
-- 		Function = function(callback) if ESP.Enabled then ESP.ToggleButton(true) ESP.ToggleButton(true) end end
-- 	})
-- end)

GuiLibrary.RemoveObject("NameTagsOptionsButton")
runcode(function()
	local NameTagsFolder = Instance.new("Folder")
	NameTagsFolder.Name = "NameTagsFolder"
	NameTagsFolder.Parent = GuiLibrary.MainGui
	Players.PlayerRemoving:Connect(function(plr)
		if NameTagsFolder:FindFirstChild(plr.Name) then
			NameTagsFolder[plr.Name]:Destroy()
		end
	end)
	local NameTagsColor = { Value = 0.44 }
	local NameTagsDisplayName = { Enabled = false }
	local NameTagsHealth = { Enabled = false }
	local NameTagsDistance = { Enabled = false }
	local NameTags = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "NameTags",
		Function = function(callback)
			if callback then
				BindToRenderStep("NameTags", 500, function()
					for i, plr in pairs(Players:GetChildren()) do
						local thing
						if NameTagsFolder:FindFirstChild(plr.Name) then
							thing = NameTagsFolder[plr.Name]
							thing.Visible = false
						else
							thing = Instance.new("TextLabel")
							thing.BackgroundTransparency = 0.5
							thing.BackgroundColor3 = Color3.new(0, 0, 0)
							thing.BorderSizePixel = 0
							thing.Visible = false
							thing.RichText = true
							thing.Name = plr.Name
							thing.Font = Enum.Font.SourceSans
							thing.TextSize = 14
							if
								plr.Character
								and plr.Character:FindFirstChild("Humanoid")
								and plr.Character:FindFirstChild("HumanoidRootPart")
							then
								local rawText = (
									NameTagsDisplayName.Enabled and plr.DisplayName ~= nil and plr.DisplayName
									or plr.Name
								)
								if NameTagsHealth.Enabled then
									rawText = (
										NameTagsDisplayName.Enabled and plr.DisplayName ~= nil and plr.DisplayName
										or plr.Name
									)
										.. " "
										.. math.floor((skywars.HealthController:getHealth(plr) or 100))
								end
								local color = HealthbarColorTransferFunction(
									(skywars.HealthController:getHealth(plr) or 100) / 100
								)
								local modifiedText = (
									NameTagsDistance.Enabled
										and isAlive()
										and '<font color="rgb(85, 255, 85)">[</font>' .. math.floor(
											(
												LocalPlayer.Character.HumanoidRootPart.Position
												- plr.Character.HumanoidRootPart.Position
											).magnitude
										) .. '<font color="rgb(85, 255, 85)">]</font> '
									or ""
								)
									.. (NameTagsDisplayName.Enabled and plr.DisplayName ~= nil and plr.DisplayName or plr.Name)
									.. (
										NameTagsHealth.Enabled
											and ' <font color="rgb(' .. tostring(math.floor(color.R * 255)) .. "," .. tostring(
												math.floor(color.G * 255)
											) .. "," .. tostring(math.floor(color.B * 255)) .. ')">' .. math.floor(
												(skywars.HealthController:getHealth(plr) or 100)
											) .. "</font>"
										or ""
									)
								local nametagSize = TextService:GetTextSize(
									rawText,
									thing.TextSize,
									thing.Font,
									Vector2.new(100000, 100000)
								)
								thing.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
								thing.Text = modifiedText
							else
								local nametagSize = TextService:GetTextSize(
									plr.Name,
									thing.TextSize,
									thing.Font,
									Vector2.new(100000, 100000)
								)
								thing.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
								thing.Text = plr.Name
							end
							thing.TextColor3 = getPlayerColor(plr)
								or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
							thing.Parent = NameTagsFolder
						end

						if isAlive(plr) and plr ~= LocalPlayer then
							local headPos, headVis = camera:WorldToViewportPoint(
								(plr.Character.HumanoidRootPart:GetRenderCFrame() * CFrame.new(
									0,
									plr.Character.Head.Size.Y + plr.Character.HumanoidRootPart.Size.Y,
									0
								)).Position
							)
							headPos = headPos

							if headVis then
								local rawText = (
									NameTagsDistance.Enabled
										and isAlive()
										and "[" .. math.floor(
											(
												LocalPlayer.Character.HumanoidRootPart.Position
												- plr.Character.HumanoidRootPart.Position
											).magnitude
										) .. "] "
									or ""
								)
									.. (NameTagsDisplayName.Enabled and plr.DisplayName ~= nil and plr.DisplayName or plr.Name)
									.. (
										NameTagsHealth.Enabled
											and " " .. math.floor((skywars.HealthController:getHealth(plr) or 100))
										or ""
									)
								local color = HealthbarColorTransferFunction(
									(skywars.HealthController:getHealth(plr) or 100) / 100
								)
								local modifiedText = (
									NameTagsDistance.Enabled
										and isAlive()
										and '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">' .. math.floor(
											(
												LocalPlayer.Character.HumanoidRootPart.Position
												- plr.Character.HumanoidRootPart.Position
											).magnitude
										) .. '</font><font color="rgb(85, 255, 85)">]</font> '
									or ""
								)
									.. (NameTagsDisplayName.Enabled and plr.DisplayName ~= nil and plr.DisplayName or plr.Name)
									.. (
										NameTagsHealth.Enabled
											and ' <font color="rgb(' .. tostring(math.floor(color.R * 255)) .. "," .. tostring(
												math.floor(color.G * 255)
											) .. "," .. tostring(math.floor(color.B * 255)) .. ')">' .. math.floor(
												(skywars.HealthController:getHealth(plr) or 100)
											) .. "</font>"
										or ""
									)
								local nametagSize = TextService:GetTextSize(
									rawText,
									thing.TextSize,
									thing.Font,
									Vector2.new(100000, 100000)
								)
								thing.Size = UDim2.new(0, nametagSize.X + 4, 0, nametagSize.Y)
								thing.Text = modifiedText
								thing.TextColor3 = getPlayerColor(plr)
									or Color3.fromHSV(NameTagsColor.Hue, NameTagsColor.Sat, NameTagsColor.Value)
								thing.Visible = headVis
								thing.Position = UDim2.new(
									0,
									headPos.X - thing.Size.X.Offset / 2,
									0,
									(headPos.Y - thing.Size.Y.Offset) - 36
								)
							end
						end
					end
				end)
			else
				UnbindFromRenderStep("NameTags")
				NameTagsFolder:ClearAllChildren()
			end
		end,
		HoverText = "Renders nametags on entities through walls.",
	})
	NameTagsColor = NameTags.CreateColorSlider({
		Name = "Player Color",
		Function = function(val) end,
	})
	NameTagsDisplayName = NameTags.CreateToggle({
		Name = "Use Display Name",
		Function = function() end,
	})
	NameTagsHealth = NameTags.CreateToggle({
		Name = "Health",
		Function = function() end,
	})
	NameTagsDistance = NameTags.CreateToggle({
		Name = "Distance",
		Function = function() end,
	})
end)

runcode(function()
	local colors = {
		Red = BrickColor.new("Terra Cotta"),
		Blue = BrickColor.new("Cyan"),
	}
	local AutoWin = { Enabled = false }
	local EnemyPortal = nil

	for _, portal in workspace.BlockContainer.Map.Portals:GetChildren() do
		if portal.BrickColor == colors[skywars.TeamController:getPlayerTeam(LocalPlayer)] then
			EnemyPortal = portal
		end
	end

	AutoWin = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoWin",
		Function = function(state)
			if not state then
				return
			end

			while AutoWin.Enabled do
				LocalPlayer.Character:PivotTo(EnemyPortal.CFrame)
				task.wait(0.4)
			end
		end,
	})
end)

runcode(function()
	local AutoToxic = { Enabled = false }
	local AutoToxicGG = { Enabled = false }
	local AutoToxicWin = { Enabled = false }
	local AutoToxicDeath = { Enabled = false }
	local AutoToxicRespond = { Enabled = false }
	local AutoToxicFinalKill = { Enabled = false }
	local AutoToxicPhrases = { RefreshValues = function() end, ObjectList = {} }
	local AutoToxicPhrases2 = { RefreshValues = function() end, ObjectList = {} }
	local AutoToxicPhrases3 = { RefreshValues = function() end, ObjectList = {} }
	local AutoToxicPhrases4 = { RefreshValues = function() end, ObjectList = {} }
	local AutoToxicPhrases5 = { RefreshValues = function() end, ObjectList = {} }
	local victorySaid = false
	local lastSaid = ""
	local lastSaid2 = ""
	local ignoredplayers = {}

	local function toxicfindstr(str, tab)
		if tab then
			for i, v in pairs(tab) do
				if str:lower():find(v) then
					return true
				end
			end
		end
		return false
	end

	skywars.EventHandler[skywars.Events.GameController.onStart[2]]:connect(function(winstuff)
		local v14 = winstuff and winstuff.placements and #winstuff.placements > 0 and winstuff.placements[1] or nil
		if v14 == LocalPlayer and not victorySaid then
			victorySaid = true
			if AutoToxic.Enabled then
				if AutoToxicGG.Enabled then
					ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("gg", "All")
					if shared.ggfunction then
						shared.ggfunction()
					end
				end
				if AutoToxicWin.Enabled then
					ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(
						#AutoToxicPhrases.ObjectList > 0
								and AutoToxicPhrases.ObjectList[math.random(1, #AutoToxicPhrases.ObjectList)]
							or "EZ L TRASH KIDS",
						"All"
					)
				end
			end
		end
	end)

	chatconnection = TextChatService.MessageReceived:Connect(function(tab)
		local plr = tab.TextSource
		if
			(
				#AutoToxicPhrases5.ObjectList > 0 and toxicfindstr(tab.Text, AutoToxicPhrases5.ObjectList)
				or #AutoToxicPhrases5.ObjectList == 0
					and (tab.Text:lower():find("hack") or tab.Text:lower():find("exploit") or tab.Text
						:lower()
						:find("cheat"))
			)
			and plr ~= LocalPlayer
			and table.find(ignoredplayers, plr.UserId) == nil
			and AutoToxic.Enabled
			and AutoToxicRespond.Enabled
		then
			local custommsg = #AutoToxicPhrases4.ObjectList > 0
				and AutoToxicPhrases4.ObjectList[math.random(1, #AutoToxicPhrases4.ObjectList)]
			if custommsg == lastSaid2 then
				custommsg = #AutoToxicPhrases4.ObjectList > 0
					and AutoToxicPhrases4.ObjectList[math.random(1, #AutoToxicPhrases4.ObjectList)]
			else
				lastSaid2 = custommsg
			end
			if custommsg then
				custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
			end
			local msg = custommsg or "waaaa waaaa " .. (plr.DisplayName or plr.Name)
			TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
			table.insert(ignoredplayers, plr.UserId)
		end
	end)

	local justsaid = ""
	local leavesaid = false
	connectionstodisconnect[#connectionstodisconnect + 1] = skywars.EventHandler[skywars.Events.GameController.onStart[1]]:connect(
		function(p7, p8)
			if p7 == LocalPlayer and leavesaid == false then
				leavesaid = true
				if AutoToxic.Enabled and AutoToxicDeath.Enabled then
					ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(
						#AutoToxicPhrases3.ObjectList > 0
								and AutoToxicPhrases3.ObjectList[math.random(1, #AutoToxicPhrases3.ObjectList)]
							or "My gaming chair expired midfight.",
						"All"
					)
				end
			end
			if AutoToxic.Enabled then
				if p8 and p8 == LocalPlayer then
					local plr = p7
					if plr and AutoToxicFinalKill.Enabled then
						local custommsg = #AutoToxicPhrases2.ObjectList > 0
							and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)]
						if custommsg == lastSaid then
							custommsg = #AutoToxicPhrases2.ObjectList > 0
								and AutoToxicPhrases2.ObjectList[math.random(1, #AutoToxicPhrases2.ObjectList)]
						else
							lastSaid = custommsg
						end
						if custommsg then
							custommsg = custommsg:gsub("<name>", (plr.DisplayName or plr.Name))
						end
						local msg = custommsg or "L " .. (plr.DisplayName or plr.Name)
						ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
					end
				end
			end
		end
	)

	AutoToxic = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoToxic",
		Function = function() end,
	})
	AutoToxicGG = AutoToxic.CreateToggle({
		Name = "AutoGG",
		Function = function() end,
		Default = true,
	})
	AutoToxicWin = AutoToxic.CreateToggle({
		Name = "Win",
		Function = function() end,
		Default = true,
	})
	AutoToxicDeath = AutoToxic.CreateToggle({
		Name = "Death",
		Function = function() end,
		Default = true,
	})
	AutoToxicRespond = AutoToxic.CreateToggle({
		Name = "Respond",
		Function = function() end,
		Default = true,
	})
	AutoToxicFinalKill = AutoToxic.CreateToggle({
		Name = "Kill",
		Function = function() end,
		Default = true,
	})
	AutoToxicPhrases = AutoToxic.CreateTextList({
		Name = "ToxicList",
		TempText = "phrase (win)",
	})
	AutoToxicPhrases2 = AutoToxic.CreateTextList({
		Name = "ToxicList2",
		TempText = "phrase (kill) <name>",
	})
	AutoToxicPhrases3 = AutoToxic.CreateTextList({
		Name = "ToxicList3",
		TempText = "phrase (death)",
	})
	AutoToxicPhrases4 = AutoToxic.CreateTextList({
		Name = "ToxicList4",
		TempText = "phrase (text to respond with) <name>",
	})
	AutoToxicPhrases4.Object.AddBoxBKG.AddBox.TextSize = 12
	AutoToxicPhrases5 = AutoToxic.CreateTextList({
		Name = "ToxicList5",
		TempText = "phrase (text to respond to)",
	})
	AutoToxicPhrases5.Object.AddBoxBKG.AddBox.TextSize = 12
end)

runcode(function()
	local NoFall = { Enabled = false }
	local nofallconnection
	local pos = CFrame.new(0, 500, 0)
	NoFall = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "NoFall",
		Function = function(callback)
			if callback then
				if isAlive() then
					task.spawn(function()
						repeat
							task.wait()
							if
								isAlive()
								and LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall
							then
								LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
								local ray
								pos = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 70, 0)
								local start = LocalPlayer.Character.HumanoidRootPart.CFrame
								ray = nil
								repeat
									task.wait()
									local raycastparameters = RaycastParams.new()
									raycastparameters.FilterDescendantsInstances = { workspace.BlockContainer }
									raycastparameters.FilterType = Enum.RaycastFilterType.Whitelist
									if not LocalPlayer.Character then
										continue
									end
									ray = workspace:Raycast(
										LocalPlayer.Character:GetPivot().Position,
										Vector3.new(0, -LocalPlayer.Character.Humanoid.HipHeight, 0),
										raycastparameters
									)
								until ray ~= nil
								local oldlanded = (
									ray
										and ray.Position
										and ray.Position + Vector3.new(
											0,
											LocalPlayer.Character.Humanoid.HipHeight * 2,
											0
										)
									or LocalPlayer.Character.HumanoidRootPart.CFrame.Position
								)
								if start.Position.Y - oldlanded.Y >= 10 then
									local flyenabled = GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled
									if GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled then
										GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.ToggleButton(false)
									end
									LocalPlayer.Character.HumanoidRootPart.CFrame = pos
									task.wait(0.1)
									LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
										oldlanded,
										oldlanded + LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
									)
									LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
									LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
									LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
									task.wait(0.1)
									LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
									if
										flyenabled
										and not GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.Enabled
									then
										GuiLibrary.ObjectsThatCanBeSaved.FlyOptionsButton.Api.ToggleButton(false)
									end
								else
									LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
									LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
								end
								task.wait(0.3)
							end
						until not NoFall.Enabled
					end)
				end
			else
				if LocalPlayer.Character then
					LocalPlayer.Character.Humanoid:SetStateEnabled(7, true)
				end
				if nofallconnection then
					nofallconnection:Disconnect()
				end
			end
		end,
	})
end)

GuiLibrary.RemoveObject("AntiVoidOptionsButton")
runcode(function()
	local antivoidpart
	local antivoidmethod = { Value = "Dynamic" }
	local antivoidnew = { Enabled = false }
	local antivoidnewdelay = { Value = 10 }
	local antitransparent = { Enabled = false }
	local AntiVoid = { Enabled = false }
	local lastvalidpos
	AntiVoid = GuiLibrary.ObjectsThatCanBeSaved.WorldWindow.Api.CreateOptionsButton({
		Name = "AntiVoid",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat
						task.wait(0.2)
						if AntiVoid.Enabled and isAlive() then
							local raycastparameters = RaycastParams.new()
							raycastparameters.FilterDescendantsInstances = { workspace.BlockContainer, antivoidpart }
							raycastparameters.FilterType = Enum.RaycastFilterType.Whitelist
							local newray = workspace:Raycast(
								LocalPlayer.Character.HumanoidRootPart.Position,
								Vector3.new(0, -1000, 0),
								raycastparameters
							)
							if newray and newray.Instance == antivoidpart then
							else
								lastvalidpos = CFrame.new(
									newray
											and newray.Position
											and (newray.Position + Vector3.new(
												0,
												LocalPlayer.Character.Humanoid.HipHeight * 2,
												0
											))
										or LocalPlayer.Character.HumanoidRootPart.CFrame.Position
								)
							end
						end
					until not AntiVoid.Enabled
				end)
				task.spawn(function()
					antivoidpart = Instance.new("Part", workspace)
					antivoidpart.CanCollide = false
					antivoidpart.Size = Vector3.new(10000, 1, 10000)
					antivoidpart.Anchored = true
					antivoidpart.Transparency = (antitransparent.Enabled and 1 or 0.5)
					antivoidpart.Position = Vector3.new(0, 0, 0)
					connectionstodisconnect[#connectionstodisconnect + 1] = antivoidpart.Touched:Connect(
						function(touchedpart)
							if touchedpart.Parent == LocalPlayer.Character and isAlive() then
								if antivoidnew.Enabled then
									LocalPlayer.Character.HumanoidRootPart.CFrame = lastvalidpos
										+ Vector3.new(0, 500, 0)
									LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
									task.wait(0.1)
									LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
									task.wait(0.1)
									LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
									task.wait(0.1)
									LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
									LocalPlayer.Character.HumanoidRootPart.CFrame = lastvalidpos
								else
									LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(
										0,
										(
											antivoidmethod.Value == "Dynamic"
												and math.clamp(
													(math.abs(LocalPlayer.Character.HumanoidRootPart.Velocity.Y) + 2),
													1,
													100
												)
											or 100
										),
										0
									)
								end
							end
						end
					)
				end)
			else
				if antivoidpart then
					antivoidpart:Destroy()
				end
			end
		end,
		HoverText = "Gives you a chance to get on land",
	})
	antivoidmethod = AntiVoid.CreateDropdown({
		Name = "Mode",
		List = { "Dynamic", "Set" },
		Function = function() end,
	})
	antivoidnew = AntiVoid.CreateToggle({
		Name = "Lagback Mode",
		Function = function(callback)
			if antivoidnewdelay.Object then
				antivoidnewdelay.Object.Visible = callback
			end
		end,
		Default = true,
	})
	antivoidnewdelay = AntiVoid.CreateSlider({
		Name = "Freeze Delay",
		Min = 6,
		Max = 30,
		Default = 10,
		Function = function() end,
	})
	antivoidnewdelay.Object.Visible = antivoidnew.Enabled
	antitransparent = AntiVoid.CreateToggle({
		Name = "Invisible",
		Function = function(callback)
			if antivoidpart then
				antivoidpart.Transparency = (callback and 1 or 0.5)
			end
		end,
		Default = true,
	})
end)

runcode(function()
	local BetterFP = { Enabled = false }
	local currentfp
	local currentfptool
	local modificationcframe = { CFrame = CFrame.new(0, 0, 0), Remove = function() end }
	local oldswinganim
	local currentlyswinging = false
	BetterFP = GuiLibrary.ObjectsThatCanBeSaved.RenderWindow.Api.CreateOptionsButton({
		Name = "BetterFP",
		Function = function(callback)
			if callback then
				modificationcframe = Instance.new("Part") --cool part so we can use tweenservice for animations
				modificationcframe.CFrame = CFrame.new(0, 0, 0)
				modificationcframe.Anchored = true
				oldswinganim = skywars.MeleeController.playAnimation
				skywars.MeleeController.playAnimation = function(Self, ...) -- attack anim hook for first person
					if not currentlyswinging then
						task.spawn(function()
							currentlyswinging = true
							TweenService:Create(
								modificationcframe,
								TweenInfo.new(0.1, Enum.EasingStyle.Linear),
								{ CFrame = CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(-40), 0, math.rad(-60)) }
							):Play()
							task.wait(0.1)
							TweenService:Create(
								modificationcframe,
								TweenInfo.new(0.1, Enum.EasingStyle.Linear),
								{ CFrame = CFrame.Angles(0, 0, 0) }
							):Play()
							task.wait(0.1)
							currentlyswinging = false
						end)
					end
					return oldswinganim(Self, ...)
				end
				BindToRenderStep("BetterFP", 1, function() --renderstep moment
					if LocalPlayer.Character then
						local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
						if tool and tool:FindFirstChild("Handle") then
							tool.Handle.LocalTransparencyModifier = (
								(camera.CFrame.Position - camera.Focus.Position).Magnitude <= 0.6 and 1 or 0
							) --are they in first person, hide ugly tool models :puke:
							for i, v in pairs(tool.Handle:GetChildren()) do
								if v:IsA("Texture") then
									v.Transparency = 1
								end
							end
							if (camera.CFrame.Position - camera.Focus.Position).Magnitude <= 0.6 then
								if currentfp ~= tool.Name then
									if currentfptool then
										currentfptool:Destroy()
										currentfptool = nil
									end
									local clone = tool.Handle:Clone()
									clone.Parent = camera
									clone.LocalTransparencyModifier = 0
									clone.Anchored = true
									for i, v in pairs(clone:GetChildren()) do
										if v:IsA("Texture") then
											v.Transparency = 0
										end
									end
									currentfptool = clone
									currentfp = tool.Name
								end
							else
								currentfp = nil
								if currentfptool then
									currentfptool:Destroy()
									currentfptool = nil
								end
							end
						else
							currentfp = nil
							if currentfptool then
								currentfptool:Destroy()
								currentfptool = nil
							end
						end
						if currentfptool then
							currentfptool.LocalTransparencyModifier = 0
							currentfptool.CFrame = (
								camera.CFrame
								* (
									CFrame.new(3, -0.8, -3)
									* CFrame.Angles(0, math.rad(90), 0)
									* modificationcframe.CFrame
								)
							) --clone located at camera
						end
					end
				end)
			else
				UnbindFromRenderStep("BetterFP") -- renderstep moment
				currentfp = nil
				if currentfptool then
					currentfptool:Destroy()
				end
				if modificationcframe then
					modificationcframe:Destroy()
				end
				skywars.MeleeController.playAnimation = oldswinganim
				oldswinganim = nil
				local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
				if tool then
					tool.Handle.LocalTransparencyModifier = 0 -- reset transparency
					for i, v in pairs(tool.Handle:GetChildren()) do
						if v:IsA("Texture") then
							v.Transparency = 0
						end
					end
				end
			end
		end,
		HoverText = "Makes first person better (better viewmodel)",
	})
end)
