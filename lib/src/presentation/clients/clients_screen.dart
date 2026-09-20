import '../../utils/arabic_transliterator.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/logo_loader.dart';

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
  String _searchQuery = '';

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
        data: (allClients) {
          final clients = allClients.where((c) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final aq = ArabicTransliterator.transliterate(_searchQuery);
            return c.name.toLowerCase().contains(q) || (c.name.contains(aq)) ||
                   (c.phone != null && c.phone!.toLowerCase().contains(q)) ||
                   (c.email != null && c.email!.toLowerCase().contains(q));
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Clients',
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
                      value: clients.isNotEmpty && clients.every((c) => _selectedIds.contains(c.id)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.addAll(clients.map((c) => c.id));
                          } else {
                            _selectedIds.removeAll(clients.map((c) => c.id));
                          }
                        });
                      },
                    ),
                    const Text('Select All'),
                  ],
                ),
              ),
              if (clients.isEmpty)
                const Expanded(child: Center(child: Text('No clients found.')))
              else
                Expanded(
                  child: ListView.builder(
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
                            ClipOval(
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Container(
                                width: 40, height: 40,
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: client.imagePath != null && client.imagePath!.isNotEmpty
                                    ? Image.file(File(client.imagePath!), fit: BoxFit.cover, filterQuality: FilterQuality.high)
                                    : const Icon(Icons.person),
                              ),
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
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'ledger') {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PaymentLedgerDialog(
                                        clientId: client.id,
                                        initialBalance: client.balance,
                                        entityName: client.name,
                                      ),
                                    );
                                  } else if (value == 'edit') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddClientScreen(clientToEdit: client)));
                                  } else if (value == 'delete') {
                                    if (ref.read(currentUserProvider)?.role == 'ADMIN') {
                                      ref.read(clientRepositoryProvider).deleteClient(client.id);
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
