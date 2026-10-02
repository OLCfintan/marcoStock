import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/logo_loader.dart';

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
  final _invoiceAddressCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _invoiceCounterPrefixCtrl = TextEditingController();
  final _iceCtrl = TextEditingController();
  final _rcCtrl = TextEditingController();
  final _ribCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

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
    _invoiceAddressCtrl.text = settings['companyInvoiceAddress'] ?? '';
    _tpCtrl.text = settings['companyTp'] ?? '';
    _phoneCtrl.text = settings['companyPhone'] ?? '';
    _taxIdCtrl.text = settings['companyTaxId'] ?? '';
    _taxRateCtrl.text = settings['companyTaxRate'] ?? '0.0';
    _logoCtrl.text = settings['companyLogoPath'] ?? '';
    _invoiceCounterPrefixCtrl.text = settings['invoiceCounterPrefix'] ?? 'MG';
    _iceCtrl.text = settings['companyIce'] ?? '';
    _rcCtrl.text = settings['companyRc'] ?? '';
    _ribCtrl.text = settings['companyRib'] ?? '';
    _emailCtrl.text = settings['companyEmail'] ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    final service = ref.read(settingsServiceProvider);
    await service.setSetting('companyName', _nameCtrl.text);
    await service.setSetting('companyAddress', _addressCtrl.text);
    await service.setSetting('companyInvoiceAddress', _invoiceAddressCtrl.text);
    await service.setSetting('companyTp', _tpCtrl.text);
    await service.setSetting('companyPhone', _phoneCtrl.text);
    await service.setSetting('companyTaxId', _taxIdCtrl.text);
    await service.setSetting('companyTaxRate', _taxRateCtrl.text);
    await service.setSetting('companyLogoPath', _logoCtrl.text);
    await service.setSetting('invoiceCounterPrefix', _invoiceCounterPrefixCtrl.text);
    await service.setSetting('companyIce', _iceCtrl.text);
    await service.setSetting('companyRc', _rcCtrl.text);
    await service.setSetting('companyRib', _ribCtrl.text);
    await service.setSetting('companyEmail', _emailCtrl.text);
    
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
        ? const Center(child: LogoLoader())
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
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Company Email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxIdCtrl,
                  decoration: const InputDecoration(labelText: 'IF (Tax ID)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _iceCtrl,
                  decoration: const InputDecoration(labelText: 'ICE'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rcCtrl,
                  decoration: const InputDecoration(labelText: 'RC'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ribCtrl,
                  decoration: const InputDecoration(labelText: 'RIB'),
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
                  controller: _invoiceCounterPrefixCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.invoiceCounterPrefix),
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
    _invoiceCounterPrefixCtrl.dispose();
    _iceCtrl.dispose();
    _rcCtrl.dispose();
    _ribCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}
