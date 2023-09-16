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
local vapeConnections = {}
local entityLibrary = shared.vapeentity
local bindableEventFolder = Instance.new("Folder")
---@type BindableEvent[]
local vapeEvents = setmetatable({}, {
	__index = function(self, key)
		local event = Instance.new("BindableEvent", bindableEventFolder)
		self[key] = event

		return event
	end,
})

local Session = {
	Items = {},
	str = "",
	events = {
		add = Instance.new("BindableEvent"),
		updateString = Instance.new("BindableEvent"),
		remove = Instance.new("BindableEvent"),
	},
}
function Session:AddItem<T>(name: string, start: T)
	if self.Items[name] then
		error('Session info item "' .. name .. '" was created before this call.')
	end
	self.Items[name] = start
	self.str ..= ("%s: %s\n"):format(name, tostring(start))
	self.events.add:Fire(name, start)
	self.events.updateString:Fire()
end

function Session:GetItem(name: string)
	if not self.Items[name] then
		error('Session info item "' .. name .. '" ' .. "Doesn't exist")
	end
	return self.Items[name]
end

function Session:ChangeItem<T>(name: string, value: T)
	if value == self.Items[name] then
		return
	end
	print(value, self.Items[name])
	self.str =
		self.str:gsub(("%s: %s\n"):format(name, tostring(self.Items[name])), ("%s: %s\n"):format(name, tostring(value)))
	self.events.updateString:Fire()
	self.Items[name] = value
end
function Session:RemoveItem<T>(name: string)
	if not self.Items[name] then
		error('Session info item "' .. name .. '" ' .. "doesn't exist")
	end
	self.str = self.str:gsub(("%s: %s\n"):format(name, tostring(self.Items[name])), "")
	self.Items[name] = nil
	self.events.remove:Fire(name)
	self.events.updateString:Fire()
end

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

local function runFn(f, ...)
	return task.spawn(f, ...)
end

-- local function retoggleMod(mod)
-- 	for i = 1, 2 do
-- 		mod.ToggleButton(true)
-- 	end
-- end

type store = {
	getState: (self: store) -> { any },
	changed: {
		connect: (self: any, f: (newState: { any }, oldState: { any }) -> ()) -> (),
	},
	dispatch: (action: any) -> (),
	destruct: (self: store) -> (),
	flush: () -> (),
}

type blockController = {
	hitBlock: (self: blockController, pos: Vector3, p2: any) -> any,
	placeBlock: (self: blockController, pos: Vector3, info: any, n: number, p5: any) -> any,
	stopBreakingAnimation: (self: blockController, s2: string, n3: number) -> (),
	startBreakingAnimation: (self: blockController) -> Animation,
	constructor: (self: blockController, p2: any, p3: any, p4: any) -> any,
	onStart: (self: blockController) -> any,
	new: (...any) -> blockController,
}

type healthController = {
	getHealth: (self: healthController, player: Player) -> number,
	getShield: (self: healthController, player: Player) -> number,
	animateDamage: (
		self: healthController,
		character: Model,
		damageAmount: number,
		isMobile: boolean,
		playDamageHighlight: boolean,
		createDamageIndicator: boolean
	) -> (),
}

type team = {
	CanRespawn: boolean,
	AliveCount: number,
	Id: string,
	Name: string,
	Color: Color3,
}

type teamController = {
	-- please don't put your british accent in code, it looks awful.
	getPlayerTeamColour: (self: teamController, player: Player) -> Color3,
	getPlayerTeam: (self: teamController, player: Player) -> team,
	getPlayerTeamId: (self: teamController, player: Player) -> string,
	getTeamColour: (self: teamController, teamId: string) -> Color3,
}

type hotbarItem = {
	Type: string,
	Quantity: number,
	Slot: number,
}
type itemInfo = {
	ItemMaterial: string,
	ItemGroup: string,
	Skins: { [string]: any },
	Rewrite: { Type: string }?,
	Name: string,
	DisplayName: string,
	ToolRef: Instance,
	ViewportOptions: { Zoom: number? }?,
}

type hotbarController = {
	getHeldItemInfo: (self: hotbarController) -> itemInfo,
	getSword: (self: hotbarController) -> hotbarItem?,
	getHotbarItems: (self: hotbarController) -> { hotbarItem },
	setupHotbar: (self: hotbarController, inputMaid: any) -> (),
	setActiveSlot: (self: hotbarController, slot: number) -> (),
	updateActiveItem: (self: hotbarController, b: boolean?) -> (),
	getSlotFromKey: (self: hotbarController, key: Enum.KeyCode) -> number,
}

type inventoryItem = { Type: string, Quantity: number, Slot: number }

type storeInventory = {
	Contents: { inventoryItem },
	Size: number,
}

type updatePlayerInventoryRet = {
	updated: boolean,
	slotId: number,
	inventory: storeInventory,
}

type inventoryUtil = {
	updatePlayerInventory: (
		inventory: storeInventory,
		itemType: string,
		itemQuantity: number
	) -> updatePlayerInventoryRet,
	updateInventory: (inventory: storeInventory, itemType: string, itemQuantity: number) -> updatePlayerInventoryRet,
	findItem: (inventory: storeInventory, itemType: string) -> inventoryItem?,
	findEmptySlot: (inventory: storeInventory, min: number?, max: number?) -> number,
	cloneInventory: (inventory: storeInventory) -> storeInventory,
}

type MeleeController = {
	strike: (self: MeleeController, input: InputObject?) -> (),
	strikeDesktop: (self: MeleeController, mouseLocation: Vector2) -> (),
	onStart: (self: MeleeController) -> (),
	manageShimBlocks: (self: MeleeController, b2: boolean) -> (),
	constructor: (self: MeleeController) -> (),
	-- TODO: find out what strikeMobile returns
	strikeMobile: (self: MeleeController) -> (),
	playAnimation: (self: MeleeController, itemInfo: itemInfo) -> (),
	attemptStrikeDesktop: (self: MeleeController, hit: BasePart) -> boolean,
	new: (...any) -> MeleeController,
}

type inventoryController = {
	registerItemPrediction: (self: inventoryController, p2: any, p3: any) -> string,
	clearInventory: (self: inventoryController) -> (),
	bindControls: (self: inventoryController) -> (),
	toggleInventory: (self: inventoryController) -> (),
	onStart: (self: inventoryController) -> any,
	isInventoryOpen: (self: inventoryController) -> boolean,
	-- TODO?: add screen controller typings
	constructor: (self: inventoryController, screenController: any) -> (),
	updateInventory: (self: inventoryController, p2: any, p3: any, p4: any, p5: any) -> (),
	moveItemToSlot: (self: inventoryController, item: inventoryItem, slot: number) -> (),
	moveItem: (self: inventoryController, itemType: string) -> (),
	hasItem: (self: inventoryController, itemType: string, quantity: number) -> boolean,
	new: (...any) -> inventoryController,
}

type skywars = {
	AfkController: any,
	Store: store,
	StoreChanged: (k: string, handler: (newState: { any }, oldState: { any }) -> ()) -> (),
	TeamController: teamController,
	BlockController: blockController,
	EventHandler: any,
	Events: { any },
	HealthController: healthController,
	HotbarController: hotbarController,
	ItemTable: any,
	MeleeController: MeleeController,
	ScreenController: any,
	SprintingController: any,
	VelocityController: any,
	InventoryController: inventoryController,
	InventoryUtil: inventoryUtil,
}

local skywars: skywars = {}
local getfunctions
runFn(function()
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
			AfkController = require(PlayerScripts.TS.controllers["afk-controller"]).AfkController,
			TeamController = require(PlayerScripts.TS.controllers["team-controller"]).TeamController,
			BlockController = require(PlayerScripts.TS.controllers["block-controller"]).BlockController,
			SprintingController = require(PlayerScripts.TS.controllers["sprinting-controller"]).SprintingController,
			-- BlockFunctionHandler = require(PlayerScripts.TS.events).Functions,
			HotbarController = controllers.HotbarController,
			-- BlockUtil = require(ReplicatedStorage.TS.util["block-util"]).BlockUtil,
			VelocityController = require(PlayerScripts.TS.controllers["player-velocity-controller"]).PlayerVelocityController,
			-- ScreenController = controllers.ScreenController,
			MeleeController = Flamework.resolveDependency(controllerids.MeleeController),
			ItemTable = require(ReplicatedStorage.TS.item.item).Items,
			HealthController = Flamework.resolveDependency(controllerids.HealthController),
			GameCurrencies = require(ReplicatedStorage.TS.game["game-currency"]).Currencies,
			Shops = require(ReplicatedStorage.TS.game.shop["game-shop"]).Shops,
		}
	end
end)
local skywarsStore

-- (probably) garbage but it works 😑
runFn(function()
	local globalStoreMod = require(PlayerScripts.TS.ui.rodux["global-store"])
	local globalStore = globalStoreMod.GlobalStore
	local store = require(ReplicatedStorage.rbxts_include.node_modules["@rbxts"].rodux.src.Store)
	local storeWrapper = globalStore
	for k, v in store do
		if not storeWrapper[k] and type(v) == "function" then
			storeWrapper[k] = v
		end
	end
	skywars.Store = storeWrapper
	skywars.StoreChanged = globalStoreMod.GlobalStoreChanged
	skywarsStore = setmetatable({}, {
		__index = function(_, key)
			return storeWrapper:getState()[key]
		end,
	})
end)

-- events
runFn(function()
	skywars.StoreChanged("GameState", function(new)
		vapeEvents.GameStateChanged:Fire(new)
	end)
	skywars.StoreChanged("GameCurrency", function(new)
		vapeEvents.GameCurrencyChanged:Fire(new)
	end)
	skywars.StoreChanged("GameStats", function(new)
		vapeEvents.GameStatsChanged:Fire(new)
	end)
end)

shared.vapeteamcheck = function(plr)
	return (
		GuiLibrary.ObjectsThatCanBeSaved["Teams by colorToggle"].Api.Enabled
			and (skywars.TeamController:getPlayerTeam(plr) ~= skywars.TeamController:getPlayerTeam(LocalPlayer))
		or not GuiLibrary.ObjectsThatCanBeSaved["Teams by colorToggle"].Api.Enabled
	)
end

getfunctions()

local function targetCheck(plr, check)
	if type(plr) == "table" then
		plr = plr.Player
	end
	return (
		check and skywars.HealthController:getHealth(plr) > 0 and plr.Character:FindFirstChild("ForceField") == nil
		or not check
	)
end

local function isAlive(plr)
	if plr then
		return plr
			and plr.Character
			and plr.Character.Parent ~= nil
			and plr.Character:FindFirstChild("HumanoidRootPart")
			and plr.Character:FindFirstChild("Head")
			and plr.Character:FindFirstChild("Humanoid")
	end
	return LocalPlayer
		and LocalPlayer.Character
		and LocalPlayer.Character.Parent ~= nil
		and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		and LocalPlayer.Character:FindFirstChild("Head")
		and LocalPlayer.Character:FindFirstChild("Humanoid")
end

local function isPlayerTargetable(plr, target, friend)
	if type(plr) == "table" then
		plr = plr.Player
	end
	return plr ~= LocalPlayer
		and plr
		and (friend and friendCheck(plr) == nil or not friend)
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
	local players = {}
	local currentamount = 0
	if isAlive() then
		for _, plr in pairs(Players:GetPlayers()) do
			if isPlayerTargetable((player and plr or nil), true, true) and isAlive(plr) and currentamount < amount then
				local mag = (LocalPlayer.Character:GetPivot().Position - plr.Character:GetPivot().Position).Magnitude
				if mag <= distance then
					table.insert(players, plr)
					currentamount = currentamount + 1
				end
			end
		end
	end
	return players
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
		for _, ent in pairs(entityLibrary.entityList) do -- loop through playersService
			if not ent.Targetable then
				continue
			end
			if isPlayerTargetable(ent, true, true) then -- checks
				local playerPosition = ent.RootPart.Position
				local mag = (entityLibrary.character.HumanoidRootPart.Position - playerPosition).magnitude
				if checktab.Prediction and mag > distance then
					mag = (entityLibrary.LocalPosition - playerPosition).magnitude
				end
				if mag <= distance then -- mag check
					table.insert(sortedentities, { entity = ent, Magnitude = ent.Target and -1 or mag })
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
	for _, conn in pairs(vapeConnections) do
		if conn.Disconnect then
			conn:Disconnect()
		end
	end
end)

local function getSword()
	for i, v in ipairs(skywars.HotbarController:getHotbarItems()) do
		local item = skywars.ItemTable[v.Type]
		if item.Melee then
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

runFn(function()
	local CPS = {
		GetRandomValue = function()
			return 1
		end,
	}
	local autoclicker = { Enabled = false }
	local noCap = { Enabled = false }
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
						and (not noCap.Enabled and autoclickertick <= tick() or true)
						and not GuiLibrary.MainGui.ScaledGui.ClickGui.Visible
					then
						autoclickertick = tick() + (1 / CPS.GetRandomValue())
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
	CPS = autoclicker.CreateTwoSlider({
		Name = "CPS",
		Min = 1,
		Max = 20,
		Function = function() end,
		Default = 8,
		Default2 = 12,
	})
	noCap = autoclicker.CreateToggle({
		Name = "No CPS cap",
		Default = false,
		HoverText = "Doesn't limit autoclicker's CPS to the limit you've set.",
		Function = function(state)
			CPS.Object.Visible = not state
		end,
	})
end)

local Killaura = { Enabled = false }
local Scaffold = { Enabled = false }
GuiLibrary.RemoveObject("KillauraOptionsButton")
GuiLibrary.RemoveObject("HitBoxesOptionsButton")
runFn(function()
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
	local killauradelay = tick()
	Killaura = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "Killaura",
		Function = function(callback)
			if callback then
				BindToStepped("Killaura", 1, function()
					local plrs = GetAllNearestHumanoidToPosition(
						killauratargetframe.Players.Enabled,
						killaurarange.Value + 0.5,
						killauratargets.Value
					)
					local handcheck = (
						killaurahandcheck.Enabled
							and skywars.HotbarController:getHeldItemInfo()
							and skywars.HotbarController:getHeldItemInfo().Melee
						or not killaurahandcheck.Enabled
					)
					targetInfo.Targets.Killaura = nil
					for _, plr in plrs do
						if handcheck then
							targetInfo.Targets.Killaura = {
								Player = plr,
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
						killauradelay <= tick()
						and (killauramouse.Enabled and UserInputService:IsMouseButtonPressed(0) or not killauramouse.Enabled)
						and handcheck
					then
						local sword = getSword()
						if (not killauraswing.Enabled) and #plrs > 0 and handcheck then
							skywars.MeleeController:playAnimation(sword)
						end
						local info, olditemname = getHeldItem()
						for _, plr in plrs do
							if not info or not (info and info.Meele) then
								equipItem(sword.Name)
							end
							skywars.EventHandler[skywars.Events.MeleeController.strikeDesktop[1]]:fire(plr)
							if not info or not (info and info.Meele) then
								equipItem(olditemname)
							end
						end
						killauradelay = tick() + 0.1
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
		Function = function() end,
		Default = 13,
	})
	killauratargets = Killaura.CreateSlider({
		Name = "Max targets",
		Min = 1,
		Max = 10,
		Function = function() end,
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

runFn(function()
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
						ScaffoldHandCheck.Enabled and helditem and helditem.Block
						or not ScaffoldHandCheck.Enabled
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
												* (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and ScaffoldDownwards.Enabled and 5 or 3)
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
								skywars.BlockController:placeBlock(newpos, block)
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
		Function = function() end,
		Default = 1,
		HoverText = "Build range",
	})
	ScaffoldDiagonal = Scaffold.CreateToggle({
		Name = "Diagonal",
		Function = function() end,
		Default = true,
	})
	ScaffoldTower = Scaffold.CreateToggle({
		Name = "Tower",
		Function = function(callback)
			if ScaffoldStopMotion.Object then
				ScaffoldTower.Object.ToggleArrow.Visible = callback
				ScaffoldStopMotion.Object.Visible = callback
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

runFn(function()
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
	local Filter = { Enabled = false }
	local FilterToggles = {}
	local FilterType = { Value = "Whitelist" }
	local oldCFrame = CFrame.new()
	local oldPosition = oldCFrame.Position
	local isStealing = false
	local function canSteal(dropType)
		return if Filter.Enabled and FilterType.Value == "Whitelist"
			then FilterToggles[dropType].Enabled
			elseif FilterType.Value == "Blacklist" and Filter.Enabled then not FilterToggles[dropType].Enabled
			else true
	end
	local function handleDrop(drop)
		if not DropStealer.Enabled then
			return
		end
		local dropType = drop.Name:split("Coin")[1]
		if not canSteal(dropType) then
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
	Filter = DropStealer.CreateToggle({
		Name = "Filter",
		Function = function(state)
			FilterType.Object.Visible = state
			for _, toggle in FilterToggles do
				toggle.Object.Visible = state
			end
		end,
		Default = false,
	})
	FilterType = DropStealer.CreateDropdown({
		Name = "Filter Type",
		List = { "Blacklist", "Whitelist" },
		Function = function() end,
		Default = "Whitelist",
	})
	FilterType.Object.Visible = false
	for _, tier in skywars.GameCurrencies do
		local name = tier.ItemType:gsub("Coin", "")
		local toggle = DropStealer.CreateToggle({
			Name = name,
			Function = function() end,
		})
		toggle.Object.Visible = Filter.Enabled
		FilterToggles[name] = toggle
	end
	DropStealInfinite = DropStealer.CreateToggle({
		Name = "Infinite Range",
		Function = function(state)
			DropStealRange.Object.Visible = not state
		end,
		Default = false,
	})
end)

runFn(function()
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

runFn(function()
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
				controlModule.moveFunction = function(Self, vec, facecam, ...)
					if entityLibrary.isAlive then
						local plr = EntityNearPosition(Range.Value, {
							WallCheck = false,
							AimPart = "RootPart",
						})

						if plr and (TeamCheck.Enabled and not isPlayerTargetable(plr, true, true) or true) then
							facecam = false
							-- code stolen from roblox since the way I tried to make it apparently sucks
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
						end
					end
					return oldMove(Self, vec, facecam, ...)
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

runFn(function()
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

GuiLibrary.RemoveObject("NameTagsOptionsButton")
runFn(function()
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
		Function = function() end,
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

runFn(function()
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
					TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("gg")
				end
				if AutoToxicWin.Enabled then
					TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(
						#AutoToxicPhrases.ObjectList > 0
								and AutoToxicPhrases.ObjectList[math.random(1, #AutoToxicPhrases.ObjectList)]
							or "EZ L TRASH KIDS"
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
	vapeConnections[#vapeConnections + 1] = skywars.EventHandler[skywars.Events.GameController.onStart[1]]:connect(
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

runFn(function()
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
				if Horizontal.Value == 0 and Vertical.Value == 0 then
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

runFn(function()
	local NoFall = { Enabled = false }
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
								local ray
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
											LocalPlayer.Character.Humanoid.HipHeight * 3,
											0
										)
									or LocalPlayer.Character.HumanoidRootPart.CFrame.Position
								)
								if start.Position.Y - oldlanded.Y >= 10 then
									-- I know it is deprecated but it works
									LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
									LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
								end
								task.wait(0.3)
							end
						until not NoFall.Enabled
					end)
				end
			else
				if not LocalPlayer.Character then
					return
				end
				if not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
					return
				end
				if LocalPlayer.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.StrafingNoPhysics then
					return
				end
				LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
			end
		end,
	})
end)

GuiLibrary.RemoveObject("AntiVoidOptionsButton")
runFn(function()
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
					vapeConnections[#vapeConnections + 1] = antivoidpart.Touched:Connect(function(touchedpart)
						if touchedpart.Parent == LocalPlayer.Character and isAlive() then
							if antivoidnew.Enabled then
								LocalPlayer.Character.HumanoidRootPart.CFrame = lastvalidpos + Vector3.new(0, 500, 0)
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
					end)
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

runFn(function()
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

runFn(function()
	local FastBreak = { Enabled = false }
	local RecallAmount = { Value = 20 }
	local oldHitBlock

	FastBreak = GuiLibrary.ObjectsThatCanBeSaved.BlatantWindow.Api.CreateOptionsButton({
		Name = "FastBreak",
		Function = function(state)
			if not state then
				skywars.BlockController.hitBlock = oldHitBlock
			end
			oldHitBlock = skywars.BlockController.hitBlock
			skywars.BlockController.hitBlock = function(...)
				for i = 1, (RecallAmount + 1) do
					oldHitBlock(...)
				end
				return oldHitBlock(...)
			end
		end,
		HoverText = "Break blocks faster\nby spam calling BlockController:hitBlock()",
	})

	RecallAmount = FastBreak.CreateSlider({
		Name = "Recall amount",
		Min = 2,
		Function = function() end,
		Max = 10,
		Default = 10,
	})
end)

runFn(function()
	---@param a Instance
	---@param b Instance
	---@return number
	local function getDistance(a, b)
		---@type Vector3
		local pos1
		---@type Vector3
		local pos2
		if a:IsA("Model") then
			pos1 = a:GetPivot().Position
		elseif a:IsA("Player") then
			if not a.Character then
				error(`No character found for player "{a.Name}"`)
			end
			pos1 = a.Character:GetPivot().Position
		elseif a:IsA("BasePart") then
			pos1 = a.Position
		else
			error("Unsupported instance type for #1: " .. a.ClassName)
		end
		if b:IsA("Model") then
			pos2 = b:GetPivot().Position
		elseif b:IsA("Player") then
			pos2 = b.Character:GetPivot().Position
		elseif b:IsA("BasePart") then
			pos2 = b.Position
		else
			error("Unsupported instance type #2: " .. b.ClassName)
		end
		return (pos1 - pos2).Magnitude
	end
	local Nuker = { Enabled = false, Connections = {} }
	local Range = { Value = 40 }
	local Toggles = { Eggs = nil }
	local ToggleConnections = { Eggs = {} }
	local Objects = { Eggs = {} }
	local NukeFunctionChecks = {
		Eggs = function(egg)
			if egg:GetAttribute("Team") == skywars.TeamController:getPlayerTeam(LocalPlayer) then
				return false
			end
			if egg:GetAttribute("Health") <= 0 then
				return false
			end
			return true
		end,
	}
	local NukeFunctions = {
		Eggs = function(egg)
			skywars.EventHandler[skywars.Events.MeleeController.strikeMobile[2]](egg)
		end,
	}
	Nuker = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "Nuker",
		Function = function()
			task.spawn(function()
				while Nuker.Enabled do
					for cName, container in Objects do
						if not LocalPlayer.Character then
							LocalPlayer.CharacterAdded:Wait()
						end
						if not Toggles[cName].Enabled then
							continue
						end
						table.sort(container, function(a, b)
							return getDistance(LocalPlayer, a) < getDistance(LocalPlayer, b)
						end)
						for _, obj in container do
							if not LocalPlayer.Character then
								LocalPlayer.CharacterAdded:Wait()
							end
							if getDistance(LocalPlayer, obj) > Range.Value then
								continue
							end
							if not NukeFunctionChecks[cName](obj) then
								continue
							end
							NukeFunctions[cName](obj)
						end
					end
					task.wait()
				end
			end)
		end,
	})
	Toggles.Eggs = Nuker.CreateToggle({
		Name = "Nuke Eggs",
		Function = function(state)
			if not state then
				Objects.Eggs = {}
				if #ToggleConnections.Eggs > 1 then
					for _, conn in ToggleConnections.Eggs do
						conn:Disconnect()
					end
				elseif #ToggleConnections.Eggs == 1 then
					ToggleConnections.Eggs[1]:Disconnect()
				end
				return
			end
			Objects.Eggs = CollectionService:GetTagged("egg")
			table.insert(
				ToggleConnections,
				CollectionService:GetInstanceAddedSignal("egg"):Connect(function(egg)
					if not table.find(Objects.Eggs, egg) then
						table.insert(Objects.Eggs, egg)
					end
				end)
			)
		end,
		Default = true,
	})
	Range = Nuker.CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 40,
		Default = 20,
		Function = function() end,
	})
end)

runFn(function()
	local AutoWin = { Enabled = false }
	local FloatVelo = Instance.new("LinearVelocity")
	FloatVelo.MaxForce = math.huge
	FloatVelo.Name = "Float"
	-- local BreakEggs = { Enabled = true }
	-- local KillPlayers = { Enabled = true }
	---@type Player[]
	local otherPlayers = {}
	---@type Model[]
	local otherEggs = {}
	local eggsDead = false
	local conn
	---@param player Player
	local function isOverVoid(player)
		-- create a new ray starting at the position of the character and going down
		local ray = Ray.new(player.Character:GetPivot().Position, Vector3.new(0, -1000, 0)) -- 1000 studs down
		-- create RaycastParams
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		-- ignore the character
		raycastParams.FilterDescendantsInstances = { player.Character }
		raycastParams.RespectCanCollide = true

		-- perform the raycast
		local result = workspace:Raycast(ray.Origin, ray.Direction, raycastParams)
		-- check if the raycast hit anything
		return result == nil
	end
	task.spawn(function()
		for _, player in Players:GetPlayers() do
			if skywars.HealthController:getHealth(player) <= 0 then
				continue
			end
			if
				skywars.TeamController:getPlayerTeamId(player) ~= skywars.TeamController:getPlayerTeamId(LocalPlayer)
			then
				table.insert(otherPlayers, player)
			end
		end
		for _, egg in CollectionService:GetTagged("egg") do
			if egg:GetAttribute("TeamId") == skywars.TeamController:getPlayerTeamId(LocalPlayer) then
				continue
			end
			if egg:GetAttribute("Health") <= 0 then
				continue
			end
			table.insert(otherEggs, egg)
		end
	end)

	AutoWin = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoWin",
		Function = function()
			task.spawn(function(state)
				if not state and conn ~= nil then
					conn:Disconnect()
					if FloatVelo.Attachment0 then
						FloatVelo.Attachment0 = nil
					end
				end
				if skywarsStore.GameState == "Cooldown" then
					repeat
						task.wait()
					until skywarsStore.GameState == "Cooldown"
				end
				conn = RunService.Heartbeat:Connect(function()
					if not AutoWin.Enabled then
						return
					end
					if not LocalPlayer.Character then
						return
					end
					if not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
						return
					end
					LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
					---@param egg Model
					if #otherEggs >= 1 and not eggsDead then
						local i = math.random(1, #otherEggs)
						local egg = otherEggs[i]
						if egg:GetAttribute("Health") <= 0 then
							table.remove(otherEggs, i)
							task.wait()
							return
						end
						if egg:GetAttribute("TeamId") == skywars.TeamController:getPlayerTeamId(LocalPlayer) then
							table.remove(otherEggs, i)
							return
						end
						FloatVelo.Attachment0 = LocalPlayer.Character.PrimaryPart:FindFirstChildOfClass("Attachment")
						LocalPlayer.Character:PivotTo(egg:GetPivot() - Vector3.new(0, 10))
						if not skywars.HotbarController:getHeldItemInfo().Melee then
							equipItem(getSword().Name)
						end
						skywars.EventHandler[skywars.Events.MeleeController.strikeMobile[2]](egg)
					else
						eggsDead = true
					end
					if not eggsDead then
						return
					end
					local player = otherPlayers[math.random(1, #otherPlayers)]
					if not player.Character then
						return
					end
					if not LocalPlayer.Character then
						return
					end
					LocalPlayer.Character:PivotTo(player.Character:GetPivot() - Vector3.new(0, 8))
					if isOverVoid(player) then
						return
					end
					LocalPlayer.Character:PivotTo(player.Character:GetPivot() - Vector3.new(0, 8))
					skywars.EventHandler[skywars.Events.MeleeController.strikeDesktop[1]](player)
				end)
			end)
		end,
	})
end)

type Item = {
	Price: number,
	Quantity: number,
	ItemType: string,
	CurrencyType: string,
}

type ItemUpgrade = {
	Items: { Item },
	ItemIndex: number,
	Id: string,
}
type TeamUpgrade = {
	Name: string,
	Tiers: {
		{
			Description: string,
			Price: number,
			CurrencyType: string,
		}
	},
	ItemIndex: number,
	Icon: string,
}

type ItemUpgrades = { ItemUpgrade }

type TeamUpgrades = { TeamUpgrade }

runFn(function()
	local AutoBuy = { Enabled = false }
	---@type RBXScriptConnection
	local Connection
	local ItemUpgradesToggle = { Enabled = false }
	local ItemUpgradeToggles = {}
	local TeamUpgradesToggle = { Enabled = false }
	local TeamUpgradeToggles = {}
	local Blacksmith = skywars.Shops.Blacksmith
	local Merchant = skywars.Shops.Merchant
	local TeamUpgrades: TeamUpgrades = Merchant.TeamUpgrades
	local ItemUpgrades: ItemUpgrades = Blacksmith.ItemUpgrades
	---british moment
	---@param word string
	---@return string
	local function britishToAmerican(word)
		return word:gsub("our", "or")
	end
	local function getCurrentItemUpgradeIndex(upgrade: ItemUpgrade)
		for i, item in upgrade.Items do
			for _, hotbarItem in skywars.HotbarController:getHotbarItems() do
				if hotbarItem.Type == (item.ItemType or item.ArmourTypes) then
					return i
				end
			end
		end
		return -1
	end

	AutoBuy = GuiLibrary.ObjectsThatCanBeSaved.UtilityWindow.Api.CreateOptionsButton({
		Name = "AutoBuy",
		Function = function(state)
			if not state then
				Connection:Disconnect()
			end
			Connection = vapeEvents.GameCurrencyChanged.Event:Connect(function(new)
				if ItemUpgradesToggle.Enabled then
					for _, itemUpgrade in ItemUpgrades do
						if not AutoBuy.Enabled then
							break
						end
						local current = getCurrentItemUpgradeIndex(itemUpgrade)
						if current == -1 then
							-- warn("Skipping item upgrade:", itemUpgrade.Id)
							continue
						end
						local nextUpgrade = itemUpgrade.Items[current + 1]
						if not nextUpgrade then
							continue
						end
						if nextUpgrade.Price <= new.Quantities[nextUpgrade.CurrencyType] then
							skywars.EventHandler[skywars.Events.GameShopController.purchaseItemUpgrade[1]](
								"Blacksmith",
								itemUpgrade.ItemIndex
							)
							-- print("bought "..itemUpgrade.Id)
						end
					end
				end
				if TeamUpgradesToggle.Enabled then
					for _, teamUpgrade in TeamUpgrades do
						if not AutoBuy.Enabled then
							break
						end
						local upgrade = (skywarsStore.TeamUpgrades or {})[teamUpgrade.Name]
						local nextTier = teamUpgrade.Tiers[(upgrade or 1) + 1]
						if nextTier and nextTier.Price <= new.Quantities[nextTier.CurrencyType] then
							skywars.EventHandler[skywars.Events.GameShopController.purchaseTeamUpgrade[1]](
								"Merchant",
								teamUpgrade.ItemIndex
							)
						end
					end
				end
			end)
		end,
	})
	ItemUpgradesToggle = AutoBuy.CreateToggle({
		Name = "Buy Item Upgrades",
		Function = function(state)
			for _, toggle in ItemUpgradeToggles do
				toggle.Object.Visible = state
			end
		end,
		Default = true,
	})
	for _, ItemUpgrade in ItemUpgrades do
		local toggle = AutoBuy.CreateToggle({
			Name = "Buy " .. britishToAmerican(ItemUpgrade.Id),
			Function = function() end,
			Default = false,
		})
		toggle.Object.Visible = ItemUpgradesToggle.Enabled
		table.insert(ItemUpgradeToggles, toggle)
	end
	TeamUpgradesToggle = AutoBuy.CreateToggle({
		Name = "Buy Team Upgrades",
		Function = function(state)
			for _, toggle in TeamUpgradeToggles do
				toggle.Object.Visible = state
			end
		end,
		Default = true,
	})
	for _, TeamUpgrade in TeamUpgrades do
		local toggle = AutoBuy.CreateToggle({
			Name = "Buy " .. britishToAmerican(TeamUpgrade.Name),
			Function = function() end,
			Default = false,
		})
		toggle.Object.Visible = TeamUpgradesToggle.Enabled
		table.insert(TeamUpgradeToggles, toggle)
	end
end)

runFn(function()
	local Overlay = GuiLibrary.CreateCustomWindow({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		IconSize = 16,
	})
	local overlayFrame = Instance.new("Frame", Overlay.GetCustomChildren())
	overlayFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayFrame.Size = UDim2.new(0, 200, 0, 120)
	overlayFrame.Position = UDim2.new(0, 0, 0, 5)
	local overlayFrame2 = Instance.new("Frame", overlayFrame)
	overlayFrame2.Size = UDim2.new(1, 0, 0, 10)
	overlayFrame2.Position = UDim2.new(0, 0, 0, -5)
	local overlayFrame3 = Instance.new("Frame", overlayFrame2)
	overlayFrame3.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	overlayFrame3.Size = UDim2.new(1, 0, 0, 6)
	overlayFrame3.Position = UDim2.new(0, 0, 0, 6)
	overlayFrame3.BorderSizePixel = 0
	local oldGUIUpdate = GuiLibrary.UpdateUI
	GuiLibrary.UpdateUI = function(h, s, v, ...)
		overlayFrame2.BackgroundColor3 = Color3.fromHSV(h, s, v)
		return oldGUIUpdate(h, s, v, ...)
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = overlayFrame
	corner:Clone().Parent = overlayFrame2
	local label = Instance.new("TextLabel", overlayFrame)
	label.Size = UDim2.new(1, -7, 1, -5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = Enum.Font.Arial
	label.LineHeight = 1.2
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextSize = 16
	label.Text = ""
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Position = UDim2.new(0, 7, 0, 5)
	local OverlayFonts = { "Arial" }
	for _, v in pairs(Enum.Font:GetEnumItems()) do
		if v.Name ~= "Arial" then
			table.insert(OverlayFonts, v.Name)
		end
	end
	local OverlayFont = Overlay.CreateDropdown({
		Name = "Font",
		List = OverlayFonts,
		Function = function(val)
			label.Font = Enum.Font[val]
		end,
	})
	OverlayFont.Bypass = true
	Overlay.Bypass = true
	---@type RBXScriptConnection[]
	local connections = {}
	GuiLibrary.ObjectsThatCanBeSaved.GUIWindow.Api.CreateCustomToggle({
		Name = "Overlay",
		Icon = "vape/assets/TargetIcon1.png",
		Function = function(callback)
			if connections and not callback then
				for _, conn in connections do
					conn:Disconnect()
				end
			end
			Overlay.SetVisible(callback)
			label.Text = "Session Info\n" .. Session.str
			table.insert(
				connections,
				Session.events.updateString.Event:Connect(function()
					label.Text = "Session Info\n" .. Session.str
				end)
			)
			Session:AddItem("Map", skywarsStore.GameSettings.MapName)
			Session:AddItem("Kills", skywarsStore.GameStats.Kills)
			Session:AddItem("Wins", 0)
			table.insert(
				connections,
				vapeEvents.GameStatsChanged.Event:Connect(function(new)
					Session:ChangeItem("Kills", new.Kills)
				end)
			)
      -- Broken
			-- skywars.EventHandler[skywars.Events.GameController.onStart[2]]:connect(function(winstuff)
			-- 	local v14 = winstuff and winstuff.placements and #winstuff.placements > 0 and winstuff.placements[1]
			-- 		or nil
			-- 	if v14 == LocalPlayer then
			-- 		Session:ChangeItem("Wins", Session:GetItem("Wins") + 1)
			-- 	end
			-- end)
			local textSize = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(9e9, 9e9))
			overlayFrame.Size = UDim2.new(0, math.max(textSize.X + 19, 200), 0, (textSize.Y * 1.2) + 6)
		end,
		Priority = 2,
	})
end)
