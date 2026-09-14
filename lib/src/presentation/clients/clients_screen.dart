import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/clients/client_providers.dart';
import '../../application/auth/auth_service.dart';
import '../../infrastructure/repositories/client_repository.dart';
import 'add_client_screen.dart';
import '../widgets/payment_ledger_dialog.dart';
import '../widgets/human_profile_dialog.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              if (_selectedIds.isNotEmpty) {
                final repo = ref.read(clientRepositoryProvider);
                for (final id in _selectedIds) {
                  await repo.deleteClient(id);
                }
                setState(() {
                  _selectedIds.clear();
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddClientScreen())),
          ),
        ],
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) return const Center(child: Text('No clients found.'));
          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selectedIds.contains(client.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(client.id);
                          } else {
                            _selectedIds.remove(client.id);
                          }
                        });
                      },
                    ),
                    CircleAvatar(
                      backgroundImage: client.imagePath != null && client.imagePath!.isNotEmpty
                          ? FileImage(File(client.imagePath!))
                          : null,
                      child: client.imagePath == null || client.imagePath!.isEmpty ? const Icon(Icons.person) : null,
                    ),
                  ],
                ),
                title: Text(client.name),
                subtitle: Text(client.phone ?? client.email ?? client.contactDetails ?? 'No contact info'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${client.balance.toStringAsFixed(2)} Dhs', style: TextStyle(
                        color: client.balance > Decimal.zero ? Colors.red : Colors.green, fontWeight: FontWeight.bold
                      )),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddClientScreen(clientToEdit: client)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                            ref.read(clientRepositoryProvider).deleteClient(client.id);
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
                          type: HumanType.client,
                          id: client.id,
                          name: client.name,
                          roleOrType: 'Client',
                          phone: client.phone,
                          email: client.email,
                          imagePath: client.imagePath,
                          balance: client.balance,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showActionMenu(context, ref, client),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$e')),
        ),
      );
    }

    void _showActionMenu(BuildContext context, WidgetRef ref, Client client) {
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
                        clientId: client.id,
                        initialBalance: client.balance,
                        entityName: client.name,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddClientScreen(clientToEdit: client)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                      ref.read(clientRepositoryProvider).deleteClient(client.id);
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
