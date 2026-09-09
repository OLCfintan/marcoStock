import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/suppliers/supplier_providers.dart';
import '../../application/auth/auth_service.dart';
import '../../infrastructure/repositories/supplier_repository.dart';
import 'add_supplier_screen.dart';
import '../widgets/payment_ledger_dialog.dart';
import '../widgets/human_profile_dialog.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              if (_selectedIds.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Printing selected items')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              if (_selectedIds.isNotEmpty) {
                final repo = ref.read(supplierRepositoryProvider);
                for (final id in _selectedIds) {
                  await repo.deleteSupplier(id);
                }
                setState(() {
                  _selectedIds.clear();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddSupplierScreen())),
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          if (suppliers.isEmpty) return const Center(child: Text('No suppliers found.'));
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selectedIds.contains(supplier.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(supplier.id);
                          } else {
                            _selectedIds.remove(supplier.id);
                          }
                        });
                      },
                    ),
                    CircleAvatar(
                      backgroundImage: supplier.imagePath != null && supplier.imagePath!.isNotEmpty
                          ? FileImage(File(supplier.imagePath!))
                          : null,
                      child: supplier.imagePath == null || supplier.imagePath!.isEmpty ? const Icon(Icons.business) : null,
                    ),
                  ],
                ),
                title: Text(supplier.name),
                subtitle: Text(supplier.phone ?? supplier.email ?? supplier.contactDetails ?? 'No contact info'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${supplier.balance.toStringAsFixed(2)} Dhs', style: TextStyle(
                        color: supplier.balance > Decimal.zero ? Colors.red : Colors.green, fontWeight: FontWeight.bold
                      )),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddSupplierScreen(supplierToEdit: supplier)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                            ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to delete.')));
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HumanProfileDialog(
                          type: HumanType.supplier,
                          id: supplier.id,
                          name: supplier.name,
                          roleOrType: 'Supplier',
                          phone: supplier.phone,
                          email: supplier.email,
                          imagePath: supplier.imagePath,
                          balance: supplier.balance,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showActionMenu(context, ref, supplier),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')),
        ),
      );
    }

    void _showActionMenu(BuildContext context, WidgetRef ref, Supplier supplier) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.green),
                  title: const Text('Ledger / Payments'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => PaymentLedgerDialog(
                        supplierId: supplier.id,
                        initialBalance: supplier.balance,
                        entityName: supplier.name,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddSupplierScreen(supplierToEdit: supplier)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                      ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to delete.')));
                    }
                  },
                ),
              ],
            ),
          );
        }
      );
    }
}
