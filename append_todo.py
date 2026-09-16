with open('/home/limbo/.gemini/antigravity-cli/brain/d1f836f6-db5e-4e8f-a372-35b8555104f1/implementation_checklist.md', 'r') as f:
    content = f.read()

new_checklist = """
## 14. PDF Tax Removal
- [x] **Request:** Remove the tax row entirely from generated PDF invoices and bills.
- [x] **Implementation:** Extracted and purged the tax generation logic completely from `pdf_generator.dart`.

## 15. PDF Document Balance Renaming
- [x] **Request:** Rename the bottom remaining balance of the document to "Remaining in this invoice" or "Remaining in this delivery note".
- [x] **Implementation:** Bound the text dynamically using ternary logic (`invoice.documentType == 'BON' ? l10n.pdfRemainingInBon : l10n.pdfRemainingInInvoice`).

## 16. PDF Global Debt Renaming
- [x] **Request:** Rename the top overall supplier/client balance to "Total debt" (Crédit total / مجموع الديون).
- [x] **Implementation:** Created the `pdfTotalDebt` ARB keys across all 4 languages and injected them into the header of `pdf_generator.dart`.

## 17. Client Passager Tier 3 Enforcement
- [x] **Request:** Always make "Client passager" default to Tier 3 prices.
- [x] **Implementation:** Set `tier: const Value('Tier 3')` on database creation and added an autonomous mathematical SQL `UPDATE` in the `beforeOpen` hook to forcefully upgrade existing databases.

## 18. Product Unit Display Geometry
- [x] **Request:** When having 1L, 1KG, or 1M3, do not hide the "1". It must print "1L".
- [x] **Implementation:** Audited 5 system files and removed the conditional logic that hid `1.0`. The system now algebraically displays exactly what exists.

## 19. Total System Data Wipe
- [x] **Request:** Add "clear all" in settings to reset all database tables for any risk of dead data.
- [x] **Implementation:** Created `clearAllData()` executing a mathematically safe transactional wipe, disabling constraints (`PRAGMA foreign_keys = OFF`), clearing tables, and regenerating the foundational Magazin/Warehouse/Passager entities.

## 20. Optical Catalog Pricing Synthesis
- [x] **Request:** Cross-reference 4 product catalog images with a master text list, generating an exact `.txt` import format with sizes mathematically altered (5L -> 4.5L, 1L -> 900ml).
- [x] **Implementation:** Deployed multimodal transcription and regex filtering to seamlessly generate `import_products.txt`.

## 21. Algorithmic Pricing Interpolation
- [x] **Request:** Fix the missing prices for items that weren't present in the catalog images (e.g. 200ml).
- [x] **Implementation:** Built a Python algorithm that calculated the average geometric price ratio across all families (e.g., 200ml vs 900ml) and dynamically computed exact prices rounded to the nearest 0.5 Dhs for 55 undocumented products.

## 22. Deep UI Localization Sweeps
- [x] **Request:** All three-dot menus, Dashboard texts, Stock screen, and Product Edit labels must be translated dynamically.
- [x] **Implementation:** Replaced over 40 hardcoded strings with `AppLocalizations.of(context)!.key` bindings across the entire application interface.

## 23. Checks History Interaction
- [x] **Request:** Fix the inability to click and view Check History images inside the client/supplier profiles.
- [x] **Implementation:** Wired up an interactive full-screen `AlertDialog` image viewer tied specifically to `payment.method == 'CHECK'` via an `onTap` listener on the UI layer.

## 24. Import Upsert Integrity Constraint Fix
- [x] **Request:** Fix the `SqliteException(2067)` UNIQUE constraint crash caused by importing existing items.
- [x] **Implementation:** Re-engineered `import_service.dart`. Instead of blindly inserting, it algorithmically queries `reference` uniqueness and applies a true SQL "Upsert" (updating existing rows without regenerating IDs, saving foreign key stability).

"""

# Insert before the verification conclusion
content = content.replace("---", new_checklist + "\n---", 1)

with open('/home/limbo/.gemini/antigravity-cli/brain/d1f836f6-db5e-4e8f-a372-35b8555104f1/implementation_checklist.md', 'w') as f:
    f.write(content)
