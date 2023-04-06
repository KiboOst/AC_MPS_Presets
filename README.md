# AC_MPS_Presets
Assetto Corsa Multi Position Switches Presets

## Lua App for Multi Position Switches support in Assetto Corsa.

#### Usage

Many steering wheels have rotary encoders, that can't be used in AC. This lua app provide support for them.

You can actually store different settings to each encoder position, and load these settings in-game. Here are the settings stored:

- Brake bias  
- Engine brake  
- MGU-H Charging (Battery / Motor)  
- MGU-K Delivery  
- MGU-K Recovery

### Requirement

You will need Content Manager and Custom Shader Patch installed.

Your MPS Encoder must be set to **Pulse mode** so that changing position send a unique button id. In AC settings/control, you should see a button lighting up when rotating the encoder, just like when pressing a standard button.

<img src="/assets/doc2.jpg" width="400">

### Disclaimer

This is an early version and doesn't have UI inside AC. I haven't enough knowledge and time to developp UI, maybe someone can help there. Having Presets setting per track in setup page would rocks for sure.

> If any mod/app developper want to help, either with UI or optimization, you are welcome!

> Tested with Fanatec Formula v2.5 wheel, CSP v0.175, RSS FH 2022 v3.

### Installation

Just copy app folder into your `steamapps\common\assettocorsa\apps\lua` folder.

### How to use

Edit **presets.json** file to edit your presets, so they can be loaded when rotating MPS encoder. You can also use standard button.

The json file is reloaded each time you exit pit. So you can edit it when adjusting setup.

json description:

controllers: The ID of your steering wheel. Should support several ones, like buttons box, but can't test.

button number: For each buttons / MPS position, set settings you want.

<img src="/assets/doc1.jpg" width="400">

> For each setting in a preset, an empty string won't change/load this setting.

preset:

*btnName* and *name* are just references for you, and will be displayed in AC when loading the preset, just like when you change a setting with a button.


```json
{
	"controllers": {
		"1": {
			"37": {
				"btnName": "Left MPS Pos 1",
				"name": "OutLap",
				"brakeBias": 0.525,
				"engineBrake": 10,
				"mguRecovery": 10,
				"mguDelivery": 1,
				"mguCharging": true
			},
			"38": {
				"btnName": "Left MPS Pos 2",
				"name": "HotLap",
				"brakeBias": 0.525,
				"engineBrake": 5,
				"mguRecovery": 0,
				"mguDelivery": 0,
				"mguCharging": false
			},
			"39": {
				"btnName": "Left MPS Pos 3",
				"name": "Race",
				"brakeBias": 0.530,
				"engineBrake": 5,
				"mguRecovery": 5,
				"mguDelivery": 2,
				"mguCharging": false
			},
		}
	}
}
```

Settings possible values:

- brakeBias/

0-> 46%

0.5 -> 50%

0.535 -> 53.5%

1 -> 64%


- engineBrake/

0 -> 1/11

1 -> 2/11

2 -> 3/11

...

10 -> 11/11


- mguRecovery/

0 -> 0%

1 -> 10%

2 -> 20%

...

10 -> 100%


- mguDelivery/

0 -> No Deploy

1 -> Build

2 -> Low

3 -> Balanced

4 -> High

5 -> Attack


- mguCharging/

true -> Battery

false -> Motor

