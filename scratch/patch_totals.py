import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# 1. Provide paymentMethod translation helper
helper = """String _localizedPaymentMethod(String? method, AppLocalizations l10n) {
  if (method == 'CASH') return l10n.cash;
  if (method == 'CHECK') return l10n.check;
  if (method == 'LETTER') return l10n.letter;
  return method ?? l10n.cash;
}
"""

content = content.replace("String _localizedProductName(dynamic product, String locale) {", helper + "\nString _localizedProductName(dynamic product, String locale) {")

# 2. _buildOldTotals
old_old_totals = """pw.Widget _buildOldTotals(InvoiceEntity invoice, AppLocalizations l10n) {
    final balance = invoice.total - invoice.paidAmount;
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: ["""

new_old_totals = """pw.Widget _buildOldTotals(InvoiceEntity invoice, AppLocalizations l10n) {
    final balance = invoice.total - invoice.paidAmount;
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (invoice.paymentMethod != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: _bidiText('${l10n.modeDeReglement}: ${_localizedPaymentMethod(invoice.paymentMethod, l10n)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
        pw.Container(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: ["""

content = content.replace(old_old_totals, new_old_totals)

# Fix the closing brackets for the new Row in _buildOldTotals
old_old_totals_end = """            _buildOldTotalRow('${l10n.pdfBalance}:', balance.toStringAsFixed(2), isBold: true, color: PdfColors.red700),
          ],
        ),
      ),
    );
  }"""

new_old_totals_end = """            _buildOldTotalRow('${l10n.pdfBalance}:', balance.toStringAsFixed(2), isBold: true, color: PdfColors.red700),
            ],
          ),
        ),
      ],
    );
  }"""

content = content.replace(old_old_totals_end, new_old_totals_end)

# 3. _buildFactureTotals
old_facture_totals = """    pw.Widget _buildFactureTotals(InvoiceEntity invoice, AppLocalizations l10n, String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    // Facture Math logic
    final mtHt = invoice.total.toDouble();
    final mtTva = mtHt * 0.20;
    final totalTtc = mtHt + mtTva;
    
    final amountWords = decimalToWordsTranslated(totalTtc, l10n.localeName);
    
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,"""

new_facture_totals = """    pw.Widget _buildFactureTotals(InvoiceEntity invoice, AppLocalizations l10n, String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    // Facture Math logic
    final mtHt = invoice.total.toDouble();
    final mtTva = mtHt * 0.20;
    final totalTtc = mtHt + mtTva;
    
    final amountWords = decimalToWordsTranslated(totalTtc, l10n.localeName);
    
    return pw.Column(
      children: [
        if (invoice.paymentMethod != null)
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: _bidiText('${l10n.modeDeReglement}: ${_localizedPaymentMethod(invoice.paymentMethod, l10n)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,"""
content = content.replace(old_facture_totals, new_facture_totals)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("pdf_generator patched")
