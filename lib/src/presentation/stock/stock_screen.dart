import '../../domain/constants/locations.dart';
import 'package:flutter/material.dart';
import "package:decimal/decimal.dart";
import '../widgets/universal_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_service.dart';
import '../../application/stock/stock_providers.dart';

import '../../infrastructure/repositories/stock_repository.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SingleTickerProviderStateMixin {
  final Set<String> _selectedIds = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockBalancesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Stock'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Base Stock'),
            Tab(text: 'Magazin Stock (Special Client)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () async {
              final code = await UniversalScanner.scan(context);
              if (code != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: $code')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print stock report coming soon')),
              );
            },
          ),
          if (ref.watch(currentUserProvider)?.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Clear Selected Stock (Admin)',
              onPressed: () async {
                if (_selectedIds.isEmpty) return;
                for (final id in _selectedIds) {
                  final parts = id.split('|');
                  if (parts.length == 2) {
                    await ref.read(stockRepositoryProvider).deleteStock(parts[0], parts[1]);
                  }
                }
                setState(() {
                  _selectedIds.clear();
                });
              },
            ),
        ],
      ),
      body: stockAsync.when(
        data: (items) {
          final baseItems = items.where((i) => i.locationId == AppLocations.baseWarehouse).toList();
          final magazinItems = items.where((i) => i.locationId == AppLocations.magazin).toList();
          
          Widget buildList(List<StockItem> listItems) {
            if (listItems.isEmpty) return const Center(child: Text('No stock in this section.'));
            return ListView.builder(
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final item = listItems[index];
                final uniqueId = '${item.productId}|${item.locationId}';
                final isSelected = _selectedIds.contains(uniqueId);
                
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(uniqueId);
                            } else {
                              _selectedIds.remove(uniqueId);
                            }
                          });
                        },
                      ),
                      const CircleAvatar(child: Icon(Icons.inventory_2)),
                    ],
                  ),
                  title: Text(item.unitSize == Decimal.one ? '${item.productName} ${item.unit}' : '${item.productName} ${item.unitSize}${item.unit}'),
                  subtitle: Text('Ref: ${item.productReference ?? ''} | Loc: ${item.locationName}'),
                  trailing: Text(
                    '${item.quantity.toStringAsFixed(2)} Units',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              buildList(baseItems),
              buildList(magazinItems),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
