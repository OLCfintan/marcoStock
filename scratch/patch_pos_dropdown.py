import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Add company branch dropdown
old_dropdown = """                    onChanged: (val) {
                      if (val != null) setState(() => _activeSession.selectedPaymentMethod = val);
                    },
                  ),
                ),
                if (_activeSession.selectedDocumentType == 'FACTURE') ...["""

new_dropdown = """                    onChanged: (val) {
                      if (val != null) setState(() => _activeSession.selectedPaymentMethod = val);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _activeSession.selectedCompanyBranch,
                    decoration: InputDecoration(
                      labelText: 'Company Branch',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MARKO_GROUP', child: Text('Marko Group')),
                      DropdownMenuItem(value: 'MARKO_PEINT', child: Text('Marko Peint')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _activeSession.selectedCompanyBranch = val);
                    },
                  ),
                ),
                if (_activeSession.selectedDocumentType == 'FACTURE') ...["""

content = content.replace(old_dropdown, new_dropdown)

# Update _confirmSale
old_confirm = """        isTempClient: isTemp,
        paymentMethod: _activeSession.selectedPaymentMethod,
      );"""

new_confirm = """        isTempClient: isTemp,
        paymentMethod: _activeSession.selectedPaymentMethod,
        companyBranch: _activeSession.selectedCompanyBranch,
      );"""

content = content.replace(old_confirm, new_confirm)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("Dropdown patched")
