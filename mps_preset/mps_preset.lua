


--[=====[
https://github.com/ac-custom-shaders-patch/acc-lua-sdk/blob/main/.definitions/ac_apps.txt
ac.setBrakeBias(balance: number)
ac.setEngineBrakeSetting(settingIndex: integer)
ac.setMGUHCharging(charging: boolean)
ac.setMGUKDelivery(level: integer)
ac.setMGUKRecovery(level: integer)


ac.setBrakeBias(0)
0-> 46%
0.5 -> 50%
0.535 -> 53.5%
1 -> 64%

ac.setEngineBrakeSetting(2)
0 -> 1/11
1 -> 2/11
2 -> 3/11
...
10 -> 11/11

ac.setMGUHCharging(false)
true -> Battery
false -> Motor

ac.setMGUKRecovery(1)
0 -> 0%
1 -> 10%
2 -> 20%
...
10 -> 100%

ac.setMGUKDelivery(3)
0 -> No Deploy
1 -> Build
2 -> Low
3 -> Balanced
4 -> High
5 -> Attack

Fanatec Formula 2.2 Pulse mode:
Left: 37 -> 48
Right 49 -> 60

--]=====]


local json = require "./json"

local appSettingsPath = './presets.json'
local appSettings

--Load settings from json file
local function loadSettings(path)
	local relPath = ac.findFile(path)
	local file = io.open(relPath, "rb")
	if not file then return nil end
	local content = file:read "*a"
	file:close()

    return json.decode(content)
end

-- Change car setup according to json presets
local function loadPreset(btnName, name, brakeBias, engineBrake, mguRecovery, mguDelivery, mguCharging)
	print('load preset! ' .. btnName)
	if brakeBias ~= '' then
		ac.setBrakeBias(brakeBias)
	end
	if engineBrake ~= '' then
		ac.setEngineBrakeSetting(engineBrake)
	end
	if mguRecovery ~= '' then
		ac.setMGUKRecovery(mguRecovery)
	end
	if mguDelivery ~= '' then
		ac.setMGUKDelivery(mguDelivery)
	end
	if mguCharging ~= '' then
		ac.setMGUHCharging(mguCharging)
	end
	ac.setMessage('Preset: ' .. btnName, name)
end

-- Check buttons pressed for each button configured in json
local function checkKeyForPreset(settings)
	for ctrlIndex, keys in pairs(settings["controllers"]) do
		for keyIndex, preset in pairs(keys) do
			if ac.isJoystickButtonPressed(ctrlIndex, keyIndex-1) then
				loadPreset(preset['btnName'], preset['name'], preset['brakeBias'], preset['engineBrake'], preset['mguRecovery'], preset['mguDelivery'], preset['mguCharging'])
			end
		end
	end
end


local reloadSettings = true
local doCheck = 0
local sim = ac.getSim()

function script.update(dt)
	if sim.isInMainMenu then
		reloadSettings = true
		return
	end

	if reloadSettings == true then
		appSettings = loadSettings(appSettingsPath)
		reloadSettings = false
	end

	doCheck = doCheck + 1
	if doCheck > 1 then
		checkKeyForPreset(appSettings)
		doCheck = 0
	end

end


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

local function drawTitle()
	ui.pushDWriteFont("Consolas")
	ui.setCursorX(0)
	ui.setCursorY(11)
	ui.dwriteTextAligned(
		"MPS PRESET",
		17,
		ui.Alignment.Center,
		ui.Alignment.Center,
		vec2(ui.windowWidth(), 11),
		false,
		rgbm(1, 1, 1, 0.9)
	)
	ui.setCursorY(60)
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

local function drawSetupSliders(margins)
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
				ui.setNextItemWidth(ui.windowWidth() - margins*2)
				local presetSetupItemValue = math.round(math.clamp(presetSetupItems[setupItem.name], setupItem.min,setupItem.max))
				local labelValue = setupItem.items and setupItem.items[presetSetupItemValue + 1] or "%.0f%%"
				if string.find(labelValue,"%%") then labelValue = labelValue.."%" end

				local value,updated = ui.slider("##"..setupItem.name,presetSetupItemValue,setupItem.min,setupItem.max,setupItem.label .. ": " .. labelValue)
				if updated then presetSetupItems[setupItem.name] = math.round(value) end
				-- ac.log(setupItem.name.." "..(setupItem.items and "true" or "false")..": "..presetSetupItems[setupItem.name])
			end
		end
	end
end

local presets = {}
local lastMode = ''

local function drawPreset(margins)
	ui.tabBar('tabbar', function ()
		ui.offsetCursorY(20)
		ui.setCursorX(margins)

		local orderedModes = {}
		local index = 1
		for mode in pairs(presets[selectedPreset]) do
			orderedModes[index] = mode
			index = index + 1
		end
		table.sort(orderedModes,function(a, b) return a:lower() < b:lower() end)

		for i = 1, #orderedModes do
			local mode = orderedModes[i]
			local presetMode = presets[selectedPreset][mode]
			ui.tabItem(mode, function ()
				if lastMode ~= mode then
					presetSetupItems = {
						FRONT_BIAS = presetMode.FRONT_BIAS,
						BRAKE_ENGINE = presetMode.BRAKE_ENGINE,
						MGUK_RECOVERY = presetMode.MGUK_RECOVERY,
						MGUK_DELIVERY = presetMode.MGUK_DELIVERY,
						MGUH_MODE = presetMode.FMGUH_MODERONT_BIAS,
					}
				end
				lastMode = mode

				ui.text("Assigned key: ")
				ui.sameLine(ui.measureText("Assigned key: ").x + margins)
				ui.setNextItemWidth(ui.windowWidth() - ui.measureText("Assigned key: ").x - margins*2)
				ui.inputText("##keyassignment", "JOY:"..presetMode.JOY .. " BUTTON:".. presetMode.BUTTON, ui.InputTextFlags.None)
				ui.offsetCursorY(20)

				drawSetupSliders(margins)
			end)
		end
	end)
end

local loaded = false

local function load()
	local presetsIni = ac.INIConfig.load(ac.findFile('./presets.ini'),ac.INIFormat.Default)

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
		if not table.contains(presetNames,name) then
			presetNames[index] = name
			index = index + 1
		end
	end

	selectedPreset = presetNames[1]
end

function script.windowSetup()
	local margins = 50

	if not loaded then
		load()
		loaded=true
	end

	drawTitle()
	drawPresetsCombo(margins)
	drawPreset(margins)
end