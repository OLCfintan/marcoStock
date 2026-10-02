# Execution Plan

## Phase 1: Document Editing (No Dead Data)
- Modify `sales_service.dart` and `purchase_service.dart` to add `updateSale` and `updatePurchase` methods. These methods will deeply reverse the old transaction (stock, balances) without soft-deleting the document, then overwrite the document with the new lines and totals, and re-apply the new stock/balances.
- Modify `pos_screen.dart` and `purchases_screen.dart` to accept an `initialDocument` parameter (or handle it via session). 
- Modify `documents_screen.dart` and `archive_screen.dart` to add the 'Edit' button, which pushes the respective screen with the document loaded.

## Phase 2: Auto Invoice (Knapsack Algorithm)
- Add a button in `pos_screen.dart` for "Auto Invoice".
- Create `AutoInvoiceDialog` requesting Target Amount, HT/TTC, and Categories Count.
- Implement a fast greedy/subset-sum algorithm that picks random products from N categories, assigns random quantities, and fine-tunes the unit prices (±5%) to perfectly hit the target amount.
- Populate the POS cart with the generated list.

## Phase 3: Large Number Printing
- Fix `decimalToWordsTranslated` or wherever large numbers fail.
