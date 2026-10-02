1. Fix Cart Quantity Badge color (Pistachio Green bg, Black text) in `pos_screen.dart` and `purchases_screen.dart`.
2. Enhance Auto Invoice:
   - Add a dropdown/radio for "Target Type: HT vs TTC". If TTC, target = input / 1.20.
   - Adjust the algorithm: When Remaining Target >= 500, increment quantities by `product.unitSize` (or a larger block). When < 500, increment by 1.
3. Update Hover Colors in Navigation Menu:
   - Check `main_layout.dart` for Navigation Rail or Sidebar, set the hover/focus color to a Purple-Green mix.
4. Update Multi-Select Icons in POS:
   - Change the multi-select FAB icon colors to Green/Orange.
