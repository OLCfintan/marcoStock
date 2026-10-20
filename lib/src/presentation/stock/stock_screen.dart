import '../../utils/arabic_transliterator.dart';
import '../../domain/constants/locations.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../widgets/universal_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/logo_loader.dart';
import '../../application/auth/auth_service.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import '../../application/stock/stock_providers.dart';

import '../../infrastructure/repositories/stock_repository.dart';
import '../widgets/product_image.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SingleTickerProviderStateMixin {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
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
        title: Text(AppLocalizations.of(context)!.warehouseStock),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.baseStock),
            Tab(text: AppLocalizations.of(context)!.magazinStock),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: AppLocalizations.of(context)!.scanBarcode,
            onPressed: () async {
              final code = await UniversalScanner.scan(context);
              if (code != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.scannedStr} $code')));
              }
            },
          ),
          if (ref.watch(currentUserProvider)?.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: AppLocalizations.of(context)!.clearSelectedStockAdmin,
              onPressed: () async {
                if (_selectedIds.isEmpty) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm'),
                    content: Text('Are you sure you want to clear the selected stock?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                
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
          final filteredItems = items.where((i) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            final aQuery = ArabicTransliterator.transliterate(_searchQuery);
            return i.productName.toLowerCase().contains(query) || (i.productName.contains(aQuery)) || i.productReference.toLowerCase().contains(query);
          }).toList();
          final baseItems = filteredItems.where((i) => i.locationId == AppLocations.baseWarehouse).toList();
          final magazinItems = filteredItems.where((i) => i.locationId == AppLocations.magazin).toList();
          
          Widget buildList(List<StockItem> listItems) {
            if (listItems.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noStockInSection));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: listItems.isNotEmpty && listItems.every((i) => _selectedIds.contains('${i.productId}|${i.locationId}')),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.addAll(listItems.map((i) => '${i.productId}|${i.locationId}'));
                            } else {
                              _selectedIds.removeAll(listItems.map((i) => '${i.productId}|${i.locationId}'));
                            }
                          });
                        },
                      ),
                      Text(AppLocalizations.of(context)!.selectAll),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      final item = listItems[index];
                      final uniqueId = '${item.productId}|${item.locationId}';
                      final isSelected = _selectedIds.contains(uniqueId);
                      
                      final isShortage = item.isShortage;
                      final unitDisplay = () {
                        final u = item.unit.toLowerCase();
                        if (['ml', 'cl', 'dl', 'l'].contains(u)) return 'L';
                        if (['mg', 'g', 'kg', 't'].contains(u)) return 'KG';
                        if (u == 'm3') return 'M3';
                        return AppLocalizations.of(context)!.units;
                      }();

                      return Material(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : (isShortage ? const Color(0xFFFFF8E1) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isShortage ? const Color(0xFFFFB74D) : Colors.grey.shade200,
                              width: isShortage ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
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
                                Stack(
                                  children: [
                                    ProductAvatarImage(
                                      imagePath: item.imagePath,
                                      radius: 20,
                                    ),
                                    if (isShortage)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade900,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} ${AppLocalizations.of(context)!.baseFamily}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (isShortage)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red.shade300),
                                    ),
                                    child: Text(
                                      'Shortage: -${item.shortageQuantity.toStringAsFixed(1)} $unitDisplay',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${AppLocalizations.of(context)!.refStr}: ${item.productReference} | ${AppLocalizations.of(context)!.locStr}: ${item.locationName}'),
                                if (isShortage && item.shortageFinancialImpact > Decimal.zero)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Financial Risk: ~${item.shortageFinancialImpact.toStringAsFixed(2)} Dhs',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.orange.shade900),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.quantity.toStringAsFixed(2)} $unitDisplay',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isShortage ? Colors.red.shade700 : Colors.black87,
                                  ),
                                ),
                                if (item.minimumStock > Decimal.zero)
                                  Text(
                                    'Min: ${item.minimumStock.toStringAsFixed(1)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.searchStock,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildList(baseItems),
                    buildList(magazinItems),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LogoLoader()),
        error: (e, s) => Center(child: Text('${AppLocalizations.of(context)?.errorStr}$e')),
      ),
    );
  }
}
