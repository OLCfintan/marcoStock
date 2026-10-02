import re

with open('lib/src/presentation/settings/company_profile_screen.dart', 'r') as f:
    content = f.read()

# Controllers
content = content.replace("final _addressCtrl = TextEditingController();", "final _addressCtrl = TextEditingController();\n  final _invoiceAddressCtrl = TextEditingController();\n  final _tpCtrl = TextEditingController();")

# _loadSettings
load_old = """    _addressCtrl.text = settings['companyAddress'] ?? '';
    _phoneCtrl.text = settings['companyPhone'] ?? '';"""
load_new = """    _addressCtrl.text = settings['companyAddress'] ?? '';
    _invoiceAddressCtrl.text = settings['companyInvoiceAddress'] ?? '';
    _tpCtrl.text = settings['companyTp'] ?? '';
    _phoneCtrl.text = settings['companyPhone'] ?? '';"""
content = content.replace(load_old, load_new)

# _saveSettings
save_old = """    await service.setSetting('companyAddress', _addressCtrl.text);
    await service.setSetting('companyPhone', _phoneCtrl.text);"""
save_new = """    await service.setSetting('companyAddress', _addressCtrl.text);
    await service.setSetting('companyInvoiceAddress', _invoiceAddressCtrl.text);
    await service.setSetting('companyTp', _tpCtrl.text);
    await service.setSetting('companyPhone', _phoneCtrl.text);"""
content = content.replace(save_old, save_new)

# UI Form Fields
ui_old = """                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.address,
                    icon: Icon(Icons.location_on),
                  ),
                ),"""
ui_new = """                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.address + ' (Bons)',
                    icon: Icon(Icons.location_on),
                  ),
                ),
                TextFormField(
                  controller: _invoiceAddressCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.invoiceAddress,
                    icon: Icon(Icons.location_city),
                  ),
                ),"""
content = content.replace(ui_old, ui_new)

ui_old2 = """                TextFormField(
                  controller: _ribCtrl,
                  decoration: const InputDecoration(
                    labelText: 'RIB',
                    icon: Icon(Icons.account_balance),
                  ),
                ),"""
ui_new2 = """                TextFormField(
                  controller: _ribCtrl,
                  decoration: const InputDecoration(
                    labelText: 'RIB',
                    icon: Icon(Icons.account_balance),
                  ),
                ),
                TextFormField(
                  controller: _tpCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.companyTp,
                    icon: Icon(Icons.receipt_long),
                  ),
                ),"""
content = content.replace(ui_old2, ui_new2)

with open('lib/src/presentation/settings/company_profile_screen.dart', 'w') as f:
    f.write(content)

print("company_profile_screen patched")
