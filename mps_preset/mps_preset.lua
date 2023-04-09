


--[=====[

Fanatec Formula 2.2 Pulse mode:
Left: 37 -> 48
Right 49 -> 60

--]=====]

local presetsIni = ac.INIConfig.load(ac.findFile('./presets.ini'),ac.INIFormat.Default)
local presets = {}
local presetSetupItems = {
	FRONT_BIAS = 0,
	BRAKE_ENGINE = 0,
	MGUK_RECOVERY = 0,
	MGUK_DELIVERY = 0,
	MGUH_MODE = 0,
}
local presetNames = {
}
local selectedPreset = ""

-- Change car setup according to json presets
local function loadPreset(modeName, mode)
	ac.log("[Joy:"..mode.JOY.." Button:"..mode.BUTTON.."] button press detected, loading preset "..modeName)
	if mode.FRONT_BIAS then
		ac.setBrakeBias(mode.FRONT_BIAS/100)
		ac.log("FRONT_BIAS="..mode.FRONT_BIAS/100)
	end
	if mode.BRAKE_ENGINE then
		ac.setEngineBrakeSetting(mode.BRAKE_ENGINE)
		ac.log("BRAKE_ENGINE="..mode.BRAKE_ENGINE)
	end
	if mode.MGUK_RECOVERY then
		ac.setMGUKRecovery(mode.MGUK_RECOVERY/10)
		ac.log("MGUK_RECOVERY="..mode.MGUK_RECOVERY/10)
	end
	if mode.MGUK_DELIVERY then
		ac.setMGUKDelivery(mode.MGUK_DELIVERY)
		ac.log("MGUK_DELIVERY="..ac.getMGUKDeliveryName(0,mode.MGUK_DELIVERY))
	end
	if mode.MGUH_MODE then
		ac.setMGUHCharging(mode.MGUH_MODE == 1 and true or false)
		ac.log("MGUH_MODE="..(mode.MGUH_MODE == 1 and "BATTERY" or "ENGINE"))
	end
	ac.log("Preset:" .. modeName .. " loaded")
end

-- Check buttons pressed for each button configured in json
local function presetKeyListener()
	for modeName in pairs(presets[selectedPreset]) do
		local mode = presets[selectedPreset][modeName]

		if ac.isJoystickButtonPressed(mode.JOY, mode.BUTTON - 1) then
			loadPreset(modeName, mode)
		end
	end
end

local function drawPresetsTitle()
	ui.pushDWriteFont("Consolas")
	ui.setCursorX(0)
	ui.setCursorY(11)
	ui.dwriteTextAligned("MPS PRESETS",17,ui.Alignment.Center,ui.Alignment.Center,vec2(ui.windowWidth(), 11),false,rgbm(1, 1, 1, 0.9))
	ui.setCursorY(60)
	ui.popDWriteFont()
end

local function drawPresetsCombo(margins)
	ui.setCursorX(margins)
	ui.setNextItemWidth(ui.windowWidth() - margins*2)
	local changed = false
	ui.combo('##presets', selectedPreset, ui.ComboFlags.None, function ()
		for i = 1, #presetNames do
			if ui.selectable(presetNames[i]) then selectedPreset, changed = presetNames[i], true end
		end
	end)

	ui.setCursorY(120)
end

local function drawSetupSliders(mode,margins)
	local spinners = ac.getSetupSpinners()
	for i=1, #spinners do
		local setupItem = spinners[i]
		for presetSetupItem,_ in pairs(presetSetupItems) do
			if setupItem.name == presetSetupItem then
				-- LUA DEBUG | Delete later
				-- ac.debug(setupItem.name..".value",setupItem.value)
				-- ac.debug(setupItem.name..".step",setupItem.step)
				-- ac.debug(setupItem.name..".min",setupItem.min)
				-- ac.debug(setupItem.name..".max",setupItem.max)
				-- ac.debug(setupItem.name..".items",stringify(setupItem.items))
				-- ac.debug(setupItem.name..".defaultValue",setupItem.defaultValue)

				ui.setCursorX(margins)
				local checkboxToggled = presets[selectedPreset][mode][presetSetupItem]~=-1
				ac.debug(presetSetupItem,checkboxToggled)
				if ui.checkbox("##checkbox_"..setupItem.name, checkboxToggled) then
					presetsIni:setAndSave(presets[selectedPreset][mode]["section"],presetSetupItem,checkboxToggled and -1 or 1)
					presets[selectedPreset][mode][presetSetupItem] = checkboxToggled and -1 or 1
				end
				ui.sameLine()
				ui.setNextItemWidth(ui.windowWidth() - margins*2 - 30)
				local presetSetupItemValue = math.round(math.clamp(presetSetupItems[setupItem.name], setupItem.min,setupItem.max))
				local labelValue = setupItem.items and setupItem.items[presetSetupItemValue + 1] or "%.0f%%"
				if not checkboxToggled then labelValue = "Current" end
				if string.find(labelValue,"%%") then labelValue = labelValue.."%" end
				local value,updated = ui.slider("##slider_"..setupItem.name,presetSetupItemValue,setupItem.min,setupItem.max,setupItem.label .. ": " .. labelValue)
				if updated then presetSetupItems[setupItem.name] = math.round(value)
					presetsIni:setAndSave(presets[selectedPreset][mode]["section"],presetSetupItem,math.round(value))
					presets[selectedPreset][mode][presetSetupItem] = math.round(value)
				end
				-- ac.log(setupItem.name.." "..(setupItem.items and "true" or "false")..": "..presetSetupItems[setupItem.name])
				ui.offsetCursorY(5)
			end
		end
	end
end

local function refreshPresetSetupItems(presetMode)
	presetSetupItems = {
		FRONT_BIAS = presetMode.FRONT_BIAS,
		BRAKE_ENGINE = presetMode.BRAKE_ENGINE,
		MGUK_RECOVERY = presetMode.MGUK_RECOVERY,
		MGUK_DELIVERY = presetMode.MGUK_DELIVERY,
		MGUH_MODE = presetMode.MGUH_MODE,
	}
end

local function reorderModes()
	local unorderedModes = {}

	local index = 1
	for mode in pairs(presets[selectedPreset]) do
		unorderedModes[index] = mode
		index = index + 1
	end
	table.sort(unorderedModes,function(a, b) return a:lower() < b:lower() end)

	return unorderedModes
end

local function joystickInputListener()
	for joystick=0, ac.getJoystickCount() do
		for button=0, ac.getJoystickButtonsCount(joystick) do
			if ac.isJoystickButtonPressed(joystick,button) then
				return joystick, button+1
			end
		end
	end
end

local listening = false
local function saveNewKeyBind(mode,joystick,button)
	presets[selectedPreset][mode]["JOY"] = joystick
	presets[selectedPreset][mode]["BUTTON"] = button
	presetsIni:setAndSave(presets[selectedPreset][mode]["section"],"JOY",joystick)
	presetsIni:setAndSave(presets[selectedPreset][mode]["section"],"BUTTON",button)
	listening = false
end

local function drawKeybindButton(mode,presetMode,margins)
	local presetKeyLabel = "Preset key: "
	ui.text(presetKeyLabel)
	ui.offsetCursorY(-20)
	ui.offsetCursorX(ui.measureText(presetKeyLabel).x + 30)
	local buttonFlags = listening and ui.ButtonFlags.Active or ui.ButtonFlags.None
	if ui.modernButton("##joystickinput",vec2(ui.windowWidth() - ui.measureText(presetKeyLabel).x - margins*2,20),buttonFlags) then
		listening = true
	end
	ui.offsetCursorY(-22)
	ui.offsetCursorX(ui.measureText(presetKeyLabel).x + 120)
	ui.textAligned("JOY:"..presetMode.JOY .. " BUTTON:".. presetMode.BUTTON,vec2(0,0))

	if listening then
		local joystick, button = joystickInputListener()
		if joystick and button then
			saveNewKeyBind(mode,joystick,button)
		end
	end
	ui.offsetCursorY(20)
end

local function deleteMode()

end

local function deleteModeButton(mode,margins)
	ui.setCursorY(ui.windowHeight() - 60)
	ui.setCursorX(ui.windowWidth() - 138)
	if ui.button("Delete Mode",vec2(88,20),ui.ButtonFlags.None) then
		deleteMode()
	end
end

local lastMode = ''
local function drawModesTabs(margins)
	ui.offsetCursorY(20)
	ui.setCursorX(margins)
	local orderedModes = reorderModes()

	for i = 1, #orderedModes do
		local mode = orderedModes[i]
		local presetMode = presets[selectedPreset][mode]
		ui.tabItem(mode, function ()
			if lastMode ~= mode then
				refreshPresetSetupItems(presetMode)
			end
			lastMode = mode

			drawKeybindButton(mode,presetMode,margins)
			drawSetupSliders(mode,margins)
			deleteModeButton(margins)
		end)
	end
end

local function loadPresets()
	local index = 1
	for section in pairs(presetsIni.sections) do
		local name = presetsIni:get(section,"NAME",'')
		local mode = presetsIni:get(section,"MODE",'')
		-- LUA DEBUG | Delete later
		-- ac.debug(section .. " " .. mode .. " NAME",presetsIni:get(section,"NAME",''))
		-- ac.debug(section .. " " .. mode .. " JOY",presetsIni:get(section,"JOY",''))
		-- ac.debug(section .. " " .. mode .. " BUTTON",presetsIni:get(section,"BUTTON",''))
		-- ac.debug(section .. " " .. mode .. " BUTTON_NAME",presetsIni:get(section,"BUTTON_NAME",''))
		-- ac.debug(section .. " " .. mode .. " MODE",presetsIni:get(section,"MODE",''))
		-- ac.debug(section .. " " .. mode .. " FRONT_BIAS",presetsIni:get(section,"FRONT_BIAS",''))
		-- ac.debug(section .. " " .. mode .. " BRAKE_ENGINE",presetsIni:get(section,"BRAKE_ENGINE",''))
		-- ac.debug(section .. " " .. mode .. " MGUK_RECOVERY",presetsIni:get(section,"MGUK_RECOVERY",''))
		-- ac.debug(section .. " " .. mode .. " MGUK_DELIVERY",presetsIni:get(section,"MGUK_DELIVERY",''))
		-- ac.debug(section .. " " .. mode .. " MGUH_MODE",presetsIni:get(section,"MGUH_MODE",''))

		local presetMode = {
			MODE=presetsIni:get(section,"MODE",''),
			JOY=presetsIni:get(section,"JOY",''),
			BUTTON=presetsIni:get(section,"BUTTON",''),
			BUTTON_NAME=presetsIni:get(section,"BUTTON_NAME",''),
			FRONT_BIAS=presetsIni:get(section,"FRONT_BIAS",-1),
			BRAKE_ENGINE=presetsIni:get(section,"BRAKE_ENGINE",-1),
			MGUK_RECOVERY=presetsIni:get(section,"MGUK_RECOVERY",-1),
			MGUK_DELIVERY=presetsIni:get(section,"MGUK_DELIVERY",-1),
			MGUH_MODE=presetsIni:get(section,"MGUH_MODE",-1),
		}

		presets[name] = presets[name] == nil and {} or presets[name]
		presets[name][mode] = presetMode
		presets[name][mode]["section"] = section
		if not table.contains(presetNames,name) then
			presetNames[index] = name
			index = index + 1
		end
	end

	selectedPreset = presetNames[1]
end

local function createNewMode(name)
	for mode in pairs(presets[selectedPreset]) do
		local newSection = string.split(presets[selectedPreset][mode]["section"],"_")
		local newSectionString = newSection[#newSection]
		presetsIni:setAndSave(newSectionString,"NAME",selectedPreset)
		presetsIni:setAndSave(newSectionString,"JOY",0)
		presetsIni:setAndSave(newSectionString,"BUTTON",1)
		presetsIni:setAndSave(newSectionString,"MODE",name)
		presetsIni:setAndSave(newSectionString,"FRONT_BIAS",56)
		presetsIni:setAndSave(newSectionString,"BRAKE_ENGINE",3)
		presetsIni:setAndSave(newSectionString,"MGUK_RECOVERY",50)
		presetsIni:setAndSave(newSectionString,"MGUK_DELIVERY",3)
		presetsIni:setAndSave(newSectionString,"MGUH_MODE",1)
		loadPresets()
		return
	end
end

local function drawNewModeTab(margins)
	ui.tabItem("+",function ()
		local newModeNameLabel = "New mode name: "
		ui.text(newModeNameLabel)
		ui.sameLine(ui.measureText(newModeNameLabel).x + margins)
		ui.setNextItemWidth(ui.windowWidth() - ui.measureText(newModeNameLabel).x - margins*2)
		local newModeNameText, updated, entered = ui.inputText("##newmodename", "",ui.InputTextFlags.AutoSelectAll)
		if entered then
			ac.log(lastMode)
			createNewMode(newModeNameText)
		end
	end)
end

local function drawPresetsTabBar(margins)
	ui.tabBar('tabbar', function ()
		drawModesTabs(margins)
		-- drawNewModeTab(margins)
	end)
end

local function drawFootnote()
	ui.setCursorY(ui.windowHeight()-30)
	ui.text("This is a footnote")
end


local reloadSettings = true
local doCheck = 0
local sim = ac.getSim()

function script.update(dt)
	if not ac.isWindowOpen("main") then
		return
	end

	if sim.isInMainMenu then
		reloadSettings = true
		return
	end

	if reloadSettings == true then
		loadPresets()
		reloadSettings = false
	end

	doCheck = doCheck + 1
	if doCheck > 1 then
		presetKeyListener()
		doCheck = 0
	end
end

function script.windowSetup()
	local margins = 50

	if not ac.isWindowOpen("main") then
		return
	end

	-- drawPresetsTitle()
	drawPresetsCombo(margins)
	drawPresetsTabBar(margins)
	drawFootnote()
end