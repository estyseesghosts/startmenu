![screenshot](https://files.catbox.moe/jqk0eo.jpg)
## a simple app launcher for macos, inspired by the windows start menu 

The launcher opens with F18: Carbon virtual key code kVK_F18 and USB HID usage 0x70000006D.

i personally have it mapped to f4 as a faster spotlight replacement but you could do whatever you want really 

To map Caps Lock to F18 on macOS, run: hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'

The hidutil mapping is temporary and can be cleared with: hidutil property --set '{"UserKeyMapping":[]}'

this project is released with the gnu general public license v3 (gpl v3). 
