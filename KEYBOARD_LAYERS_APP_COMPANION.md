# Keyboard Layers App Companion Support

This firmware has been configured to work with the [Keyboard Layers App Companion](https://github.com/maatthc/qmk_layers_app_companion), which displays the currently active keyboard layer on your screen.

## How It Works

The firmware sends layer state changes via USB HID raw reports when you switch between layers. The Keyboard Layers App Companion listens for these reports and displays the corresponding layer layout.

## Requirements

1. **USB Connection**: The keyboard must be connected via USB (not Bluetooth) for the layer reporting to work.
2. **Keyboard Layers App Companion**: Install and run the companion app on your computer.

## Configuration

The firmware includes:
- A custom module (`zmk-layer-status-hid`) that hooks into layer state changes
- USB HID configuration with usage page `0xFF60` and usage `0x61` (matching QMK's raw HID)
- Layer state reporting that sends the highest active layer number

## Setup Instructions

1. **Build the firmware** with the layer status HID module:
   ```bash
   ./build-local.sh all
   ```

2. **Flash the firmware** to your keyboard (both halves if split).

3. **Connect via USB** - The layer reporting only works over USB, not Bluetooth.

4. **Install Keyboard Layers App Companion**:
   - Download from: https://github.com/maatthc/qmk_layers_app_companion/releases
   - Or install from source following their instructions

5. **Configure the app**:
   - Edit `config.ini` in the app directory
   - Set `usage_page = 0xFF60` and `usage = 0x61` (already configured)
   - Add your layer images (see below)

6. **Run the app**:
   ```bash
   # Desktop app
   pipenv run python main.py
   
   # Or web version
   pipenv run python main.py --web
   ```

## Creating Layer Images

You can create layer images using:
- [Keyboard Layout Editor (KLE)](http://www.keyboard-layout-editor.com)
- [KLE NG](https://editor.keyboard-tools.xyz/) (recommended)

Export your layouts as PNG images and add them to the app's `assets` folder, then update `config.ini`:

```ini
[LAYER_IMAGES]
layer_0 = base.png
layer_1 = nav.png
layer_2 = mouse.png
layer_3 = media.png
layer_4 = num.png
layer_5 = sym.png
layer_6 = fun.png
```

## Troubleshooting

### Layer changes not detected
- Ensure the keyboard is connected via **USB** (not Bluetooth)
- Check that USB HID is enabled in the firmware
- Verify the app is running and listening for HID reports

### USB device not found
- Make sure you're using the right side (central) half when connected via USB
- Try unplugging and reconnecting the USB cable
- Check device permissions (Linux/macOS may need udev rules)

### Module not compiling
- Ensure the module is properly added to `west.yml`
- Check that all dependencies are available
- Verify ZMK version compatibility (v0.3.0)

## Technical Details

The implementation:
- Uses ZMK's event system to listen for `zmk_layer_state_changed` events
- Sends 32-byte HID reports with payload marker `0x90` at byte 24
- Reports the highest active layer number (0-6)
- Only works over USB (not BLE)

## Limitations

- **USB only**: Layer reporting requires USB connection. Bluetooth connections won't send layer updates.
- **Single device**: The app connects to one USB HID device at a time.
- **Split keyboards**: Only the central (right) half needs to be connected via USB for layer reporting.

## References

- [Keyboard Layers App Companion](https://github.com/maatthc/qmk_layers_app_companion)
- [ZMK Documentation](https://zmk.dev)
- [Keyboard Layout Editor](http://www.keyboard-layout-editor.com)
