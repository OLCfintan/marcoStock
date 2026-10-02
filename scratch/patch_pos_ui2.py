import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

old_doc_field = """                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: _activeSession.selectedDocumentType,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.documentType,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.colorScheme.primaryContainer.withAlpha(128),
                    ),
                    items: [
                      DropdownMenuItem(value: 'BON', child: Text(AppLocalizations.of(context)!.deliveryNote)),
                      DropdownMenuItem(value: 'TICKET', child: Text(AppLocalizations.of(context)!.ticket)),
                      DropdownMenuItem(value: 'COMMANDE', child: Text(AppLocalizations.of(context)!.purchaseOrder)),
                      DropdownMenuItem(value: 'FACTURE', child: Text(AppLocalizations.of(context)!.invoice)),
                    ],
                    onChanged: (val) => _onDocumentTypeChanged(val!),
                  ),
                ),"""

new_doc_field = """                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _activeSession.selectedDocumentType,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.documentType,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.primaryContainer.withAlpha(128),
                        ),
                        items: [
                          DropdownMenuItem(value: 'BON', child: Text(AppLocalizations.of(context)!.deliveryNote)),
                          DropdownMenuItem(value: 'TICKET', child: Text(AppLocalizations.of(context)!.ticket)),
                          DropdownMenuItem(value: 'COMMANDE', child: Text(AppLocalizations.of(context)!.purchaseOrder)),
                          DropdownMenuItem(value: 'FACTURE', child: Text(AppLocalizations.of(context)!.invoice)),
                        ],
                        onChanged: (val) => _onDocumentTypeChanged(val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
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

content = content.replace(old_doc_field, new_doc_field)

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("pos_screen.dart patched UI")
