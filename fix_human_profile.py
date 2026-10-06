import re

with open("lib/src/presentation/widgets/human_profile_dialog.dart", "r") as f:
    content = f.read()

old_search1 = """          if (_searchQuery.isNotEmpty) {
            items = items.where((inv) =>
              inv.invoiceNumber.toLowerCase().contains(_searchQuery) ||
              (inv.clientNameOverride?.toLowerCase().contains(_searchQuery) ?? false) ||
              inv.documentType.toLowerCase().contains(_searchQuery)
            ).toList();
          }"""
          
new_search1 = """          if (_searchQuery.isNotEmpty) {
            final q = ArabicTransliterator.transliterate(_searchQuery.toLowerCase());
            items = items.where((inv) {
              final num = ArabicTransliterator.transliterate(inv.invoiceNumber.toLowerCase());
              final cName = ArabicTransliterator.transliterate(inv.clientNameOverride?.toLowerCase() ?? '');
              final dType = ArabicTransliterator.transliterate(inv.documentType.toLowerCase());
              final dDate = '${inv.date.day.toString().padLeft(2,'0')}/${inv.date.month.toString().padLeft(2,'0')}/${inv.date.year}';
              return num.contains(q) || cName.contains(q) || dType.contains(q) || dDate.contains(q);
            }).toList();
          }"""

content = content.replace(old_search1, new_search1)

old_search2 = """          if (_searchQuery.isNotEmpty) {
            items = items.where((pur) =>
              pur.purchaseNumber.toLowerCase().contains(_searchQuery)
            ).toList();
          }"""
          
new_search2 = """          if (_searchQuery.isNotEmpty) {
            final q = ArabicTransliterator.transliterate(_searchQuery.toLowerCase());
            items = items.where((pur) {
              final num = ArabicTransliterator.transliterate(pur.purchaseNumber.toLowerCase());
              final dDate = '${pur.date.day.toString().padLeft(2,'0')}/${pur.date.month.toString().padLeft(2,'0')}/${pur.date.year}';
              return num.contains(q) || dDate.contains(q);
            }).toList();
          }"""

content = content.replace(old_search2, new_search2)

# Ensure import exists
if 'arabic_transliterator.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../utils/arabic_transliterator.dart';")

with open("lib/src/presentation/widgets/human_profile_dialog.dart", "w") as f:
    f.write(content)
print("Fixed human profile dialog")
