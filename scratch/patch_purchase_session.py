import re

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

old_session = """class PurchaseSession {
  final String id;
  String title;
  String? selectedSupplierId;"""

new_session = """class PurchaseSession {
  final String id;
  String title;
  String? selectedSupplierId;
  String? selectedSupplierName;"""

content = content.replace(old_session, new_session)

old_autocomplete = """                  AutocompleteSearchField<Supplier>(
                    labelText: AppLocalizations.of(context)?.selectSupplier ?? 'Select Supplier',
                    prefixIcon: const Icon(Icons.business),
                    displayStringForOption: (supplier) => supplier.name,
                    getSuggestions: (query) async {
                      return ref.read(supplierRepositoryProvider).searchSuppliers(query);
                    },
                    onSelected: (supplier) {
                      setState(() {
                        _activeSession.selectedSupplierId = supplier.id;
                      });
                    },
                  ),"""

new_autocomplete = """                  AutocompleteSearchField<Supplier>(
                    key: ValueKey(_activeSession.id),
                    labelText: AppLocalizations.of(context)?.selectSupplier ?? 'Select Supplier',
                    prefixIcon: const Icon(Icons.business),
                    initialText: _activeSession.selectedSupplierName,
                    displayStringForOption: (supplier) => supplier.name,
                    getSuggestions: (query) async {
                      return ref.read(supplierRepositoryProvider).searchSuppliers(query);
                    },
                    onSelected: (supplier) {
                      setState(() {
                        _activeSession.selectedSupplierId = supplier.id;
                        _activeSession.selectedSupplierName = supplier.name;
                      });
                    },
                  ),"""

content = content.replace(old_autocomplete, new_autocomplete)

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
