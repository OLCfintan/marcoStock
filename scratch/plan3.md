1. Fix Auto Invoice Algorithm:
   - Change price adjustment max to 7% (`0.07`).
   - Limit "unit" accumulation to max 5 pieces per product.
2. Fix Sidebar Hover:
   - Create a `HoverSidebarItem` Stateful widget in `main_layout.dart`.
   - Use `MouseRegion` to detect hover.
   - When hovered, apply a container decoration with a glowing shadow (purple/green) and background mix.
