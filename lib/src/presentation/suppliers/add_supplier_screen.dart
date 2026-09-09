import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/database/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/repositories/supplier_repository.dart';
import '../widgets/image_picker_field.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  final Supplier? supplierToEdit;
  const AddSupplierScreen({super.key, this.supplierToEdit});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.supplierToEdit != null) {
      _nameController.text = widget.supplierToEdit!.name;
      _phoneController.text = widget.supplierToEdit!.phone ?? '';
      _emailController.text = widget.supplierToEdit!.email ?? '';
      _imagePath = widget.supplierToEdit!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameToCheck = _nameController.text.trim();
    final db = ref.read(databaseProvider);
    final exists = await (db.select(db.suppliers)..where((t) => t.name.equals(nameToCheck))).getSingleOrNull();
    if (exists != null && exists.id != widget.supplierToEdit?.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.supplierExists)));
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fillRequiredFields)));
      return;
    }
    try {

    final repo = ref.read(supplierRepositoryProvider);

    await repo.createSupplier(
      _nameController.text.trim(),
      'STANDARD', // type
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      imagePath: _imagePath,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorSaving}$e')));
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplierToEdit != null ? 'Edit Supplier' : AppLocalizations.of(context)!.addNewSupplier),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader('Basic Information', Icons.info_outline),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      decoration: _inputDecoration('Supplier Name'),
                      
                    ),
                    const SizedBox(height: 16),
                    ImagePickerField(
                      label: 'Profile Image',
                      onChanged: (val) => setState(() => _imagePath = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Contact Details', Icons.contact_phone),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration('Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email Address'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
