with open('lib/src/presentation/sales/pos_screen.dart', 'r') as f:
    content = f.read()

# Fix line 392
content = content.replace('      ),\n      ),\n    );\n  }\n\n  void _generateAutoInvoice', '      ),\n    );\n  }\n\n  void _generateAutoInvoice')

# Fix line 1251
content = content.replace('      ),\n      ),\n      ),\n    );\n  }\n}', '      ),\n      ),\n    );\n  }\n}')

with open('lib/src/presentation/sales/pos_screen.dart', 'w') as f:
    f.write(content)
print("pos screen fixed")
