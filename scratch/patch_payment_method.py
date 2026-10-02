import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

helper = """  String _localizedPaymentMethod(String? method, AppLocalizations l10n) {
    if (method == 'CASH') return l10n.cash;
    if (method == 'CHECK') return l10n.check;
    if (method == 'LETTER') return l10n.letter;
    return method ?? l10n.cash;
  }

"""

content = content.replace("  String _localizedProductName(ProductEntity? product, String locale) {", helper + "  String _localizedProductName(ProductEntity? product, String locale) {")

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Added _localizedPaymentMethod")
