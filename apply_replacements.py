import os
import re

files_to_process = [
    'lib/src/presentation/layout/main_layout.dart',
    'lib/src/presentation/settings/settings_screen.dart',
    'lib/src/presentation/settings/company_profile_screen.dart',
    'lib/src/presentation/sales/pos_screen.dart',
    'lib/src/presentation/products/add_product_screen.dart',
    'lib/src/presentation/clients/add_client_screen.dart',
    'lib/src/presentation/suppliers/add_supplier_screen.dart',
    'lib/src/presentation/hr/add_employee_screen.dart',
    'lib/src/presentation/widgets/human_profile_dialog.dart',
    'lib/src/presentation/widgets/payment_ledger_dialog.dart',
    'lib/src/presentation/stock/transfer_screen.dart',
    'lib/src/presentation/products/products_screen.dart',
    'lib/src/presentation/purchases/purchases_screen.dart',
    'lib/src/presentation/clients/clients_screen.dart',
    'lib/src/presentation/suppliers/suppliers_screen.dart',
    'lib/src/presentation/documents/documents_screen.dart',
    'lib/src/presentation/dashboard/dashboard_screen.dart',
    'lib/src/presentation/stock/stock_screen.dart',
    'lib/src/presentation/hr/employees_screen.dart'
]

import_stmt = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"

replacements = {
    # main_layout.dart
    "'Stock Transfers'": "l10n?.stockTransfers ?? 'Stock Transfers'",
    "'Returns'": "l10n?.returns ?? 'Returns'",
    "'Archive & Docs'": "l10n?.archiveDocs ?? 'Archive & Docs'",
    "'ADMINISTRATION'": "l10n?.administration ?? 'ADMINISTRATION'",
    "'Settings'": "l10n?.settings ?? 'Settings'",
    "'Logout'": "l10n?.logout ?? 'Logout'",

    # settings_screen.dart & company_profile_screen.dart
    "Text('Company Profile')": "Text(AppLocalizations.of(context)!.companyProfile)",
    "Text('Save Profile')": "Text(AppLocalizations.of(context)!.saveProfile)",
    "Text('Saved Successfully')": "Text(AppLocalizations.of(context)!.savedSuccessfully)",
    "Text('Settings & System')": "Text(AppLocalizations.of(context)!.settingsSystem)",
    "Text('Company',": "Text(AppLocalizations.of(context)!.company,",
    "Text('Manage company details, tax ID, and logo')": "Text(AppLocalizations.of(context)!.manageCompanyDetails)",
    "Text('Preferences',": "Text(AppLocalizations.of(context)!.preferences,",
    "Text('Theme')": "Text(AppLocalizations.of(context)!.theme)",
    "Text('System',": "Text(AppLocalizations.of(context)!.system,",
    "Text('Light')": "Text(AppLocalizations.of(context)!.light)",
    "Text('Dark')": "Text(AppLocalizations.of(context)!.dark)",
    "Text('Language')": "Text(AppLocalizations.of(context)!.language)",
    "Text('System Maintenance',": "Text(AppLocalizations.of(context)!.systemMaintenance,",
    "Text('Force Sync')": "Text(AppLocalizations.of(context)!.forceSync)",
    "Text('Push pending changes to cloud')": "Text(AppLocalizations.of(context)!.pushPendingChanges)",
    "Text('Syncing...')": "Text(AppLocalizations.of(context)!.syncing)",
    "Text('Sync Complete')": "Text(AppLocalizations.of(context)!.syncComplete)",
    "Text('Check for Updates')": "Text(AppLocalizations.of(context)!.checkForUpdates)",
    "Text('Connects to GitHub Releases')": "Text(AppLocalizations.of(context)!.connectsToGithub)",
    "Text('Update Available')": "Text(AppLocalizations.of(context)!.updateAvailable)",
    "Text('A new version is available on GitHub.')": "Text(AppLocalizations.of(context)!.newVersionAvailable)",
    "Text('Later')": "Text(AppLocalizations.of(context)!.later)",
    "Text('Download')": "Text(AppLocalizations.of(context)!.download)",
    "Text('App is up to date.')": "Text(AppLocalizations.of(context)!.appUpToDate)",
    "Text('Backup Database')": "Text(AppLocalizations.of(context)!.backupDatabase)",
    "Text('Select a location to save a copy of the database')": "Text(AppLocalizations.of(context)!.selectBackupLocation)",
    "Text('Backup cancelled')": "Text(AppLocalizations.of(context)!.backupCancelled)",
    "Text('Backup saved to: $path')": "Text('${AppLocalizations.of(context)!.backupSavedTo}$path')",

    # Add Screens and Error messages
    "Text('Error saving: $e')": "Text('${AppLocalizations.of(context)!.errorSaving}$e')",
    "Text('Error loading products: $e')": "Text('${AppLocalizations.of(context)!.errorLoadingProducts}$e')",
    "Text('Error: $e')": "Text('${AppLocalizations.of(context)!.errorStr}$e')",
    "Text('Error: $err')": "Text('${AppLocalizations.of(context)!.errorStr}$err')",
    "Text('Error: $error')": "Text('${AppLocalizations.of(context)!.errorStr}$error')",
    "Text('Error: ${snapshot.error}')": "Text('${AppLocalizations.of(context)!.errorStr}${snapshot.error}')",
    "Text('Error saving payments: $e')": "Text('${AppLocalizations.of(context)!.errorSavingPayments}$e')",
    "'Error'": "AppLocalizations.of(context)!.errorStr.trim()",

    # Required
    "return 'Required';": "return AppLocalizations.of(context)!.requiredField;",
    "'Required' : null": "AppLocalizations.of(context)!.requiredField : null",

    # Units
    "'Units per Box'": "AppLocalizations.of(context)!.unitsPerBox",
    "_inputDecoration('Unit (e.g. L)')": "_inputDecoration(AppLocalizations.of(context)!.unit)",

    # POS / Payment Methods
    "Text('CASH')": "Text(AppLocalizations.of(context)!.cash.toUpperCase())",
    "Text('CHECK')": "Text(AppLocalizations.of(context)!.check.toUpperCase())",
    "Text('CREDIT')": "Text(AppLocalizations.of(context)!.credit.toUpperCase())",
    "'Check Image'": "AppLocalizations.of(context)!.checkImage",

    # Profile dialogs
    "Text('Credit Monthly Salary')": "Text(AppLocalizations.of(context)!.creditMonthlySalary)",
    "Text('Credit Bonus')": "Text(AppLocalizations.of(context)!.creditBonus)",
    "Text('Transaction History')": "Text(AppLocalizations.of(context)!.transactionHistory)",
    "Text('Checks')": "Text(AppLocalizations.of(context)!.checks)",
    "Text('Check Image Available', style": "Text(AppLocalizations.of(context)!.checkImageAvailable, style",
}

for file_path in files_to_process:
    full_path = os.path.join('/home/limbo/Desktop/marcoStock', file_path)
    if not os.path.exists(full_path):
        continue
    
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content

    for old, new in replacements.items():
        content = content.replace(old, new)
        
    # Also replace Text(type) -> Text(type == 'Unit' ? AppLocalizations.of(context)!.unit : (type == 'Box' ? AppLocalizations.of(context)!.box : type))
    # only in add_product_screen.dart inside the dropdown
    if 'add_product_screen.dart' in file_path:
        content = content.replace("child: Text(type)", "child: Text(type == 'Unit' ? AppLocalizations.of(context)!.unit : (type == 'Box' ? AppLocalizations.of(context)!.box : type))")
    
    if content != original_content:
        # Add import if missing
        if 'package:flutter_gen/gen_l10n/app_localizations.dart' not in content:
            # find first import
            first_import = content.find("import '")
            if first_import != -1:
                content = content[:first_import] + import_stmt + "\n" + content[first_import:]
            else:
                content = import_stmt + "\n" + content
                
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)

print("Replacements done.")
