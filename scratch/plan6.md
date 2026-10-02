1. Fix Screensaver:
   - Change `_ScreensaverScreenState` to handle password input inline. Add `bool _showPasswordInput = false;`.
   - When "Unlock" is clicked, set `_showPasswordInput = true`.
   - The UI shows a centered glassy card with a TextField.
   - Submitting it checks `widget.correctPassword`.
   - If wrong, show a localized Text error on the card.
   - If right, call `widget.onUnlock()`.
2. Fix LogoLoader:
   - Remove the `if (widget.size < 60)` fallback.
   - The puzzle background with diagonal elements should ALWAYS render, regardless of size.
   - Adjust icon sizes inside `LogoLoader` proportionally to `widget.size` so they fit inside small loaders too.
3. Fix Sidebar Icons Rotating:
   - In `_HoverNavItemState` (main_layout.dart), add an `AnimationController` for spinning.
   - If `isSelected` is true, the controller repeats. If false, it resets/stops.
   - Wrap the `Icon` in a `RotationTransition`.
