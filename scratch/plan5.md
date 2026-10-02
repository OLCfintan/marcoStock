1. Settings: Add `sleepDelay` (int) to `SettingsService` (0 = never, else minutes). Default 5.
   - Add dropdown to `SettingsScreen`.
2. Global Screensaver:
   - Create `AppIdleWrapper` in `main.dart` using a `Timer` that resets on user interaction (`Listener` for pointer events, `HardwareKeyboard` for keys).
   - If timer fires, push a `PageRouteBuilder` to `ScreensaverScreen` (opaque: false, full screen).
3. Aquarium Screensaver UI (`ScreensaverScreen`):
   - Flutter `CustomPainter` for fish (boids algorithm).
   - Glassy water background (linear gradient + blur).
   - Custom cursor (logo image).
   - Bottom unlock button -> shows dialog asking for password.
4. Loading Screen (`LogoLoader`):
   - Generate a high-quality background image using `generate_image`.
   - Update `lib/src/presentation/widgets/logo_loader.dart` to use the image and diagonal moving stickers.
