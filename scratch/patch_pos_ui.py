import re

with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# 1. Update PosSession
old_session = """  String selectedDocumentType = 'BON';
  List<SaleLineRequest> cart = [];"""
new_session = """  String selectedDocumentType = 'BON';
  String selectedPaymentMethod = 'CASH'; // 'CASH', 'CHECK', 'LETTER'
  List<SaleLineRequest> cart = [];"""
content = content.replace(old_session, new_session)

# 2. Add Dropdown to UI (Under Document Type dropdown)
# Wait, I need to find where DocumentType dropdown is rendered.
old_doc_dropdown = r"""                              DropdownButton<String>\(
                                value: _activeSession\.selectedDocumentType,
                                isExpanded: true,
                                items: \[
                                  DropdownMenuItem\(value: 'BON', child: Text\(l10n\.bonDeLivraison\)\),
                                  DropdownMenuItem\(value: 'COMMANDE', child: Text\(l10n\.bonDeCommande\)\),
                                  DropdownMenuItem\(value: 'FACTURE', child: Text\(l10n\.facture\)\),
                                \],
                                onChanged: \(val\) \{
                                  if \(val != null\) setState\(\(\) => _activeSession\.selectedDocumentType = val\);
                                \},
                              \)"""

new_doc_dropdown = """                              DropdownButton<String>(
                                value: _activeSession.selectedDocumentType,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'BON', child: Text(l10n.bonDeLivraison)),
                                  DropdownMenuItem(value: 'COMMANDE', child: Text(l10n.bonDeCommande)),
                                  DropdownMenuItem(value: 'FACTURE', child: Text(l10n.facture)),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _activeSession.selectedDocumentType = val);
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(l10n.modeDeReglement, style: Theme.of(context).textTheme.titleSmall),
                              DropdownButton<String>(
                                value: _activeSession.selectedPaymentMethod,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'CASH', child: Text(l10n.cash)),
                                  DropdownMenuItem(value: 'CHECK', child: Text(l10n.check)),
                                  DropdownMenuItem(value: 'LETTER', child: Text(l10n.letter)),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _activeSession.selectedPaymentMethod = val);
                                },
                              )"""
                              
content = re.sub(old_doc_dropdown, new_doc_dropdown, content)

# 3. Update confirm sale to pass the payment method
old_confirm = """      final invoiceId = await ref.read(salesServiceProvider).createInvoice(
        clientId: _activeSession.selectedClientId,
        documentType: _activeSession.selectedDocumentType,
        lines: _activeSession.cart,
        payments: validPayments,
        userId: 'admin', // Hardcoded until Auth is implemented
        isTempClient: isTemp,
      );"""

new_confirm = """      final invoiceId = await ref.read(salesServiceProvider).createInvoice(
        clientId: _activeSession.selectedClientId,
        documentType: _activeSession.selectedDocumentType,
        lines: _activeSession.cart,
        payments: validPayments,
        userId: 'admin', // Hardcoded until Auth is implemented
        isTempClient: isTemp,
        paymentMethod: _activeSession.selectedPaymentMethod,
      );"""
content = content.replace(old_confirm, new_confirm)


with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("pos_screen.dart patched")
