# ZMK Layer Status HID Module

This module enables layer state reporting via USB HID raw reports, compatible with the [Keyboard Layers App Companion](https://github.com/maatthc/qmk_layers_app_companion).

## Features

- Hooks into ZMK's layer state change events
- Sends USB HID raw reports when layers change
- Compatible with QMK's raw HID format (usage page 0xFF60, usage 0x61)
- Reports the highest active layer number

## Configuration

The module is automatically enabled when the shield is built. To disable it, set `CONFIG_ZMK_LAYER_STATUS_HID=n` in your config file.

## Requirements

- USB connection (does not work over Bluetooth)
- ZMK v0.3.0 or later
- USB HID device support enabled

## Technical Details

The module:
- Listens for `zmk_layer_state_changed` events
- Sends 32-byte HID reports with payload marker `0x90` at byte 24
- Reports layer numbers 0-6 (matching your keymap layers)

## Usage

1. Build your firmware with this module included
2. Connect keyboard via USB
3. Run the Keyboard Layers App Companion
4. Layer changes will be automatically reported
