
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/database/providers.dart';
import '../../application/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/repositories/employee_repository.dart';
import '../widgets/image_picker_field.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  final Employee? employeeToEdit;
  const AddEmployeeScreen({super.key, this.employeeToEdit});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinCodeController = TextEditingController();
  String _selectedRole = 'CASHIER';
  final _emailController = TextEditingController();
  final _baseSalaryController = TextEditingController(text: '0');
  
  String? _imagePath;
  String? _idScanPath;

  @override
  void initState() {
    super.initState();
    if (widget.employeeToEdit != null) {
      _nameController.text = widget.employeeToEdit!.name;
      _positionController.text = widget.employeeToEdit!.position;
      _phoneController.text = widget.employeeToEdit!.phone ?? '';
      _emailController.text = widget.employeeToEdit!.email ?? '';
      _baseSalaryController.text = widget.employeeToEdit!.baseSalary.toStringAsFixed(2);
      _imagePath = widget.employeeToEdit!.imagePath;
      if (['ADMIN', 'GERANT', 'CAISSIER', 'MAGAZINIER'].contains(widget.employeeToEdit!.role)) {
         _selectedRole = widget.employeeToEdit!.role;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _pinCodeController.dispose();
    _emailController.dispose();
    _baseSalaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameToCheck = _nameController.text.trim();
    final db = ref.read(databaseProvider);
    final exists = await (db.select(db.employees)..where((t) => t.name.equals(nameToCheck))).getSingleOrNull();
    if (exists != null && exists.id != widget.employeeToEdit?.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.employeeExists)));
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fillRequiredFields)));
      return;
    }
    try {

    final repo = ref.read(employeeRepositoryProvider);

    await repo.createEmployee(
      _nameController.text.trim(),
      _positionController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      imagePath: _imagePath,
      idScanPath: _idScanPath,
      baseSalary: _baseSalaryController.text.trim(),
      role: _selectedRole,
      pinCode: _selectedRole == 'MAGAZINIER' ? null : (_pinCodeController.text.trim().isEmpty ? null : _pinCodeController.text.trim()),
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
        title: Text(AppLocalizations.of(context)!.addNewEmployee),
        
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
              
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      decoration: _inputDecoration('Employee Name'),
                      
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _positionController,
                      decoration: _inputDecoration('Position / Role'),
                      
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
            const SizedBox(height: 24),
            _buildSectionHeader('Salary & Documents', Icons.attach_money),
            Card(
              
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: (ref.watch(currentUserProvider)?.role == 'ADMIN' 
                          ? ['ADMIN', 'GERANT', 'CASHIER'] 
                          : ['GERANT', 'CASHIER'])
                          .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                      decoration: _inputDecoration('Role'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pinCodeController,
                      decoration: _inputDecoration('Login PIN Code (Required)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _baseSalaryController,
                      decoration: _inputDecoration('Base Salary'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    ImagePickerField(
                      label: 'ID Scan / Document',
                      onChanged: (val) => setState(() => _idScanPath = val),
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
