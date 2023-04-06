


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
	["FRONT_BIAS"] = 0,
	["BRAKE_ENGINE"] = 0,
	["MGUK_RECOVERY"] = 0,
	["MGUK_DELIVERY"] = 0,
	["MGUH_MODE"] = 0,
}

function script.windowSetup()
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

	local spinners = ac.getSetupSpinners()
	for i=1, #spinners do
		local setupItem = spinners[i]
		for presetSetupItem,_ in pairs(presetSetupItems) do
			if setupItem.name == presetSetupItem then
				ac.debug(setupItem.name..".value",setupItem.value)
				ac.debug(setupItem.name..".step",setupItem.step)
				ac.debug(setupItem.name..".min",setupItem.min)
				ac.debug(setupItem.name..".max",setupItem.max)
				ac.debug(setupItem.name..".items",setupItem.items)
				ac.debug(setupItem.name..".defaultValue",setupItem.defaultValue)

				local margin = 50
				ui.setCursorX(margin)
				ui.setNextItemWidth(ui.windowWidth() - margin*2)
				local presetSetupItemValue = math.clamp(presetSetupItems[setupItem.name], setupItem.min,setupItem.max)
				local value = ui.slider("##"..setupItem.name,presetSetupItemValue,setupItem.min,setupItem.max,setupItem.label.. ": %.0f")
				presetSetupItems[setupItem.name] = value
				ac.log(setupItem.name..": "..presetSetupItems[setupItem.name])
			end
		end
	end
end

