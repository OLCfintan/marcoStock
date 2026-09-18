import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings/settings_service.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(settingsServiceProvider);
    final settings = await service.getAllCompanySettings();
    _nameCtrl.text = settings['companyName'] ?? '';
    _addressCtrl.text = settings['companyAddress'] ?? '';
    _phoneCtrl.text = settings['companyPhone'] ?? '';
    _taxIdCtrl.text = settings['companyTaxId'] ?? '';
    _taxRateCtrl.text = settings['companyTaxRate'] ?? '0.0';
    _logoCtrl.text = settings['companyLogoPath'] ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    final service = ref.read(settingsServiceProvider);
    await service.setSetting('companyName', _nameCtrl.text);
    await service.setSetting('companyAddress', _addressCtrl.text);
    await service.setSetting('companyPhone', _phoneCtrl.text);
    await service.setSetting('companyTaxId', _taxIdCtrl.text);
    await service.setSetting('companyTaxRate', _taxRateCtrl.text);
    await service.setSetting('companyLogoPath', _logoCtrl.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.savedSuccessfully)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.companyProfile)),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (val) => val == null || val.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Company Address'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Company Phone'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxIdCtrl,
                  decoration: const InputDecoration(labelText: 'Tax ID'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxRateCtrl,
                  decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredField;
                    if (double.tryParse(val) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _logoCtrl,
                  decoration: const InputDecoration(labelText: 'Logo Path / URL'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: Text(AppLocalizations.of(context)!.saveProfile),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _taxIdCtrl.dispose();
    _taxRateCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }
}
