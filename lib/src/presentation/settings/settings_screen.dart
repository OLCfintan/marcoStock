import '../../application/import/import_service.dart';
import 'package:go_router/go_router.dart';
import '../../application/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../application/settings/settings_service.dart';
import '../../application/system/sync_service.dart';
import '../../application/system/update_service.dart';

import 'company_profile_screen.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import 'package:drift/drift.dart' as drift;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCheckingUpdate = false;

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final newPinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change My PIN'),
        content: TextFormField(
          controller: newPinController,
          decoration: const InputDecoration(labelText: 'New PIN Code'),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newPin = newPinController.text.trim();
              if (newPin.isNotEmpty) {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  final db = ref.read(databaseProvider);
                  await (db.update(db.employees)..where((t) => t.id.equals(user.id))).write(EmployeesCompanion(
                    pinCode: drift.Value(newPin),
                    updatedAt: drift.Value(DateTime.now()),
                  ));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully')));
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
     

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsSystem)),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(AppLocalizations.of(context)!.company, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: Text(AppLocalizations.of(context)!.companyProfile),
            subtitle: Text(AppLocalizations.of(context)!.manageCompanyDetails),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyProfileScreen()));
            },
          ),
          const Divider(),
          if (ref.watch(currentUserProvider)?.role == 'ADMIN') ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Admin Security', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Admin PIN'),
              subtitle: const Text('Update your personal login PIN code'),
              onTap: () {
                _showChangePinDialog(context, ref);
              },
            ),
          ],
          const Divider(),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(AppLocalizations.of(context)!.preferences, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(AppLocalizations.of(context)!.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (mode) {
                if (mode != null) ref.read(themeModeProvider.notifier).setMode(mode);
              },
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(AppLocalizations.of(context)!.system)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(AppLocalizations.of(context)!.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(AppLocalizations.of(context)!.dark)),
              ],
            ),
          ),
          if (ref.watch(currentUserProvider)?.role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Recycle Bin', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/garbage'),
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.language),
            trailing: DropdownButton<Locale>(
              value: locale,
              onChanged: (newLocale) {
                if (newLocale != null) ref.read(localeProvider.notifier).setLocale(newLocale);
              },
              items: AppLocalizations.supportedLocales.map((loc) {
                String name = loc.languageCode;
                switch (loc.languageCode) {
                  case 'en': name = 'English'; break;
                  case 'fr': name = 'Français'; break;
                  case 'es': name = 'Español'; break;
                  case 'ar': name = 'العربية'; break;
                }
                return DropdownMenuItem(value: loc, child: Text(name));
              }).toList(),
            ),
          ),
          
          const Divider(),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(AppLocalizations.of(context)!.systemMaintenance, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(AppLocalizations.of(context)!.forceSync),
            subtitle: Text(AppLocalizations.of(context)!.pushPendingChanges),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.syncing)));
              await ref.read(syncServiceProvider).processOutbox();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.syncComplete)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(AppLocalizations.of(context)!.checkForUpdates),
            subtitle: Text(AppLocalizations.of(context)!.connectsToGithub),
            trailing: _isCheckingUpdate ? const CircularProgressIndicator() : null,
            onTap: () async {
              setState(() => _isCheckingUpdate = true);
              final hasUpdate = await ref.read(updateServiceProvider).checkForUpdates();
              setState(() => _isCheckingUpdate = false);
              
              if (context.mounted) {
                if (hasUpdate) {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.updateAvailable),
                    content: Text(AppLocalizations.of(context)!.newVersionAvailable),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(AppLocalizations.of(context)!.later)),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(updateServiceProvider).downloadUpdate();
                          Navigator.of(context, rootNavigator: true).pop();
                        }, 
                        child: Text(AppLocalizations.of(context)!.download)
                      ),
                    ],
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.appUpToDate)));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: Text(AppLocalizations.of(context)!.backupDatabase),
            subtitle: Text(AppLocalizations.of(context)!.selectBackupLocation),
            onTap: () async {
              try {
                final path = await ref.read(syncServiceProvider).backupDatabase();
                if (context.mounted) {
                  if (path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.backupSavedTo}$path')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.backupCancelled)));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')));
                }
              }
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Colors.blue),
            title: const Text('Import Master Data (TXT/CSV/PDF)'),
            subtitle: const Text('Import strict format Clients, Suppliers, or Products data'),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
              tooltip: 'View Import Format Instructions',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Import Format Prototype'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data should be plain text blocks separated by "---". Field names are case-insensitive. Spaces and underscores are ignored in keys.', style: TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 16),
                          const Text('Product Template:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey.shade200,
                            child: const SelectableText(
                                'TYPE: PRODUCT\n'
                                'NAME: Your Product Name\n'
                                'REFERENCE: REF123 (Optional)\n'
                                'NAME_AR: (Optional Arabic Tag)\n'
                                'NAME_FR: (Optional French Tag)\n'
                                'NAME_ES: (Optional Spanish Tag)\n'
                                'UNIT: Unit, Box, etc.\n'
                                'UNIT_SIZE: 1\n'
                                'UNITS_PER_BOX: 1 (Optional)\n'
                                'PURCHASE_PRICE: 100\n'
                                'SELLING_PRICE: 150\n'
                                'TIER2_PRICE: 140 (Optional)\n'
                                'TIER3_PRICE: 130 (Optional)\n'
                                'MIN_STOCK: 10\n'
                                'BASE_MIN_STOCK: 5 (Optional)\n'
                                'MAGAZIN_MIN_STOCK: 5 (Optional)\n'
                                'PACKAGING: Unit\n'
                                '---'),
                          ),
                          const SizedBox(height: 16),
                          const Text('Client Template:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey.shade200,
                            child: const SelectableText('TYPE: CLIENT\nNAME: John Doe\nPHONE: 123456789\nADDRESS: 123 Street\n---'),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
                    ],
                  ),
                );
              },
            ),
            onTap: () async {
              final result = await ref.read(importServiceProvider).importData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
              }
            },
          ),
        ],
      ),
    );
  }
}
