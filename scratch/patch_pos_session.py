import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# PosSession class update
old_pos = """  String selectedDocumentType = 'BON';
  String selectedPaymentMethod = 'CASH'; // 'CASH', 'CHECK', 'LETTER'"""
new_pos = """  String selectedDocumentType = 'BON';
  String selectedPaymentMethod = 'CASH'; // 'CASH', 'CHECK', 'LETTER'
  String selectedCompanyBranch = 'MARKO_GROUP'; // 'MARKO_GROUP' or 'MARKO_PEINT'"""
content = content.replace(old_pos, new_pos)

# UI Dropdown (under Document Type / Payment Method)
old_ui = """                      DropdownButtonFormField<String>(
                        value: _activeSession.selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.modeDeReglement,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: [
                          DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cash)),
                          DropdownMenuItem(value: 'CHECK', child: Text(AppLocalizations.of(context)!.check)),
                          DropdownMenuItem(value: 'LETTER', child: Text(AppLocalizations.of(context)!.letter)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _activeSession.selectedPaymentMethod = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),"""
new_ui = """                      DropdownButtonFormField<String>(
                        value: _activeSession.selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.modeDeReglement,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: [
                          DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cash)),
                          DropdownMenuItem(value: 'CHECK', child: Text(AppLocalizations.of(context)!.check)),
                          DropdownMenuItem(value: 'LETTER', child: Text(AppLocalizations.of(context)!.letter)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _activeSession.selectedPaymentMethod = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _activeSession.selectedCompanyBranch,
                        decoration: InputDecoration(
                          labelText: 'Company Branch', // Hardcoded as it's specific
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
                    ],
                  ),
                ),"""
content = content.replace(old_ui, new_ui)

# Update _confirmSale to pass companyBranch
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

print("pos_screen patched")
