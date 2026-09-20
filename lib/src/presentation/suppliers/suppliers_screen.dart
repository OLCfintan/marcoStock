import '../../utils/arabic_transliterator.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/logo_loader.dart';

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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers Management'),
        actions: [
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
        data: (allSuppliers) {
          final suppliers = allSuppliers.where((s) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final aq = ArabicTransliterator.transliterate(_searchQuery);
            return s.name.toLowerCase().contains(q) || (s.name.contains(aq)) ||
                   (s.phone != null && s.phone!.toLowerCase().contains(q)) ||
                   (s.email != null && s.email!.toLowerCase().contains(q));
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Suppliers',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: suppliers.isNotEmpty && suppliers.every((s) => _selectedIds.contains(s.id)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.addAll(suppliers.map((s) => s.id));
                          } else {
                            _selectedIds.removeAll(suppliers.map((s) => s.id));
                          }
                        });
                      },
                    ),
                    const Text('Select All'),
                  ],
                ),
              ),
              if (suppliers.isEmpty)
                const Expanded(child: Center(child: Text('No suppliers found.')))
              else
                Expanded(
                  child: ListView.builder(
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
                            ClipOval(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Container(
                                width: 40, height: 40,
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: supplier.imagePath != null && supplier.imagePath!.isNotEmpty
                                    ? Image.file(File(supplier.imagePath!), fit: BoxFit.cover, filterQuality: FilterQuality.high)
                                    : const Icon(Icons.business),
                              ),
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
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'ledger') {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PaymentLedgerDialog(
                                        supplierId: supplier.id,
                                        initialBalance: supplier.balance,
                                        entityName: supplier.name,
                                      ),
                                    );
                                  } else if (value == 'edit') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddSupplierScreen(supplierToEdit: supplier)));
                                  } else if (value == 'delete') {
                                    if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                                      ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to delete.')));
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'ledger', child: Text(AppLocalizations.of(context)!.ledgerPayments)),
                                  PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                                  PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))),
                                ],
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
                        );
                      },
                  ),
                ),
            ],
          );
        },
          loading: () => const Center(child: const LogoLoader()),
          error: (e, st) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')),
        ),
      );
    }
}
