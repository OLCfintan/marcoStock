import re

filepath = "lib/src/presentation/settings/company_profile_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Add phone controller
content = content.replace("final _addressCtrl = TextEditingController();", "final _addressCtrl = TextEditingController();\n  final _phoneCtrl = TextEditingController();")

# Load phone
content = content.replace("_addressCtrl.text = settings['companyAddress'] ?? '';", "_addressCtrl.text = settings['companyAddress'] ?? '';\n    _phoneCtrl.text = settings['companyPhone'] ?? '';")

# Save phone
content = content.replace("await service.setSetting('companyAddress', _addressCtrl.text);", "await service.setSetting('companyAddress', _addressCtrl.text);\n    await service.setSetting('companyPhone', _phoneCtrl.text);")

# Add phone field to UI
phone_field = """                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Company Phone'),
                ),"""
content = content.replace("const InputDecoration(labelText: 'Company Address'),\n                ),", "const InputDecoration(labelText: 'Company Address'),\n                ),\n" + phone_field)

# Dispose phone
content = content.replace("_addressCtrl.dispose();", "_addressCtrl.dispose();\n    _phoneCtrl.dispose();")

with open(filepath, 'w') as f:
    f.write(content)
print("Added company phone to profile")
