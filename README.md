# AC_MPS_Presets
Assetto Corsa Multi Position Switches Presets

Lua App for Multi Position Switches support in Assetto Corsa.

#### Usage

Many steering wheels have rotary encoders, that can't be used in AC. This lua app provide support for them.

You can actually store different settings to each encoder position, and load these settings in-game. Here are the settings stored:

- Brake bias  
- Engine brake  
- MGU-H Charging (Battery / Motor)  
- MGU-K Delivery  
- MGU-K Recovery

#### Requirement

You will need Content Manager and Custom Shader Patch installed.
Your MPS Encoder must be set to Pulse mode. In AC settings/control, you should see a button lighting up when rotating the encoder, just like when pressing a standard button.

#### Disclaimer

This is an early version and doesn't have UI inside AC. I haven't enough knowledge and time to developp UI, maybe someone can help there. Having Presets setting per track in setup page would rocks for sure

Tested with Fanatec Formula v2.5 wheel, CSP v0.175, RSS FH 2022 v3.

#### Installation

Just copy app folder into your Assetto Corsa /app/lua folder.

#### How to use

Edit json file to edit your presets, so they can be loaded when rotating MPS encoder. You can also use standard button.

> For each setting in a presset, an empty string won't whange/load this setting.

json description:

controllers

buttons

presets

