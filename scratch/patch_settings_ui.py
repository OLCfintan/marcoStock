import re

with open('lib/src/presentation/settings/company_profile_screen.dart', 'r') as f:
    content = f.read()

old_address = """                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Company Address'),
                ),"""
new_address = """                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Bons Address'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _invoiceAddressCtrl,
                  decoration: const InputDecoration(labelText: 'Invoice Address'),
                ),"""
content = content.replace(old_address, new_address)

old_tax = """                TextFormField(
                  controller: _taxIdCtrl,
                  decoration: const InputDecoration(labelText: 'IF (Tax ID)'),
                ),"""
new_tax = """                TextFormField(
                  controller: _taxIdCtrl,
                  decoration: const InputDecoration(labelText: 'IF (Tax ID)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tpCtrl,
                  decoration: const InputDecoration(labelText: 'TP'),
                ),"""
content = content.replace(old_tax, new_tax)

with open('lib/src/presentation/settings/company_profile_screen.dart', 'w') as f:
    f.write(content)
print("Settings UI patched")
