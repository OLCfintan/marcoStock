1. Auto Invoice Dialog:
   - Create two TextEditingControllers: HT and TTC.
   - Use an `onChanged` listener on the HT field to update the TTC field (`val * 1.20`).
   - Use an `onChanged` listener on the TTC field to update the HT field (`val / 1.20`).
   - Remove the old radio buttons.
2. Auto Invoice Algorithm:
   - Track `totalLooseUnits` across the entire generation.
   - Default to buying `uSize` (a full box).
   - If a full box exceeds the remaining target, drop down to buying `1` unit.
   - If buying `1` unit, check if `totalLooseUnits < 5`. If `>= 5`, skip!
   - This ensures the cart has at most 5 single pieces total.
