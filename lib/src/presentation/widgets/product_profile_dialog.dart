import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../widgets/logo_loader.dart';

import '../../domain/products/product.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

class ProductProfileDialog extends ConsumerStatefulWidget {
  final Product product;

  const ProductProfileDialog({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductProfileDialog> createState() => _ProductProfileDialogState();
}

class _ProductProfileDialogState extends ConsumerState<ProductProfileDialog> with SingleTickerProviderStateMixin {
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
    final db = ref.watch(databaseProvider);
    final p = widget.product;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${p.name} Profile'),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                ClipOval(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: Container(
                    width: 80, height: 80,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: p.imagePath != null && p.imagePath!.isNotEmpty
                        ? Image.file(File(p.imagePath!), fit: BoxFit.cover, filterQuality: FilterQuality.high)
                        : const Icon(Icons.inventory_2_outlined, size: 40),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Reference: ${p.reference}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16),
                          const SizedBox(width: 8),
                          Text('Category: ${p.category ?? "N/A"}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 16),
                          const SizedBox(width: 8),
                          Text('Packaging: ${p.packagingType ?? "N/A"} (${p.unitSize} ${p.unit}, ${p.unitsPerBox} per box)'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Purchase Price', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${p.purchasePrice.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    const Text('Selling Price', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${p.sellingPrice.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    if (p.tier2Price != null) ...[
                      const SizedBox(height: 4),
                      Text('Tier 2: ${p.tier2Price!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.blue)),
                    ],
                    if (p.tier3Price != null) ...[
                      const SizedBox(height: 4),
                      Text('Tier 3: ${p.tier3Price!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.blue)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Current Stock'),
              Tab(text: 'BOM / Consumables'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStockBalancesList(db, p.id),
                _buildConsumablesList(db, p.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBalancesList(AppDatabase db, String productId) {
    final query = db.select(db.stockBalances).join([
      drift.innerJoin(db.stockLocations, db.stockLocations.id.equalsExp(db.stockBalances.locationId))
    ])..where(db.stockBalances.productId.equals(productId));
    
    return StreamBuilder<List<drift.TypedResult>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: const LogoLoader());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No stock recorded for this product.'));
        }
        
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final row = results[index];
            final balance = row.readTable(db.stockBalances);
            final location = row.readTable(db.stockLocations);
            
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.warehouse, color: const Color(0xff64748b)),
              ),
              title: Text(location.name),
              subtitle: Text('Location Type: ${location.type}'),
              trailing: Text(
                '${balance.quantity.toStringAsFixed(2)} Dhs',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConsumablesList(AppDatabase db, String productId) {
    final query = db.select(db.productConsumables).join([
      drift.innerJoin(db.products, db.products.id.equalsExp(db.productConsumables.consumableId))
    ])..where(db.productConsumables.productId.equals(productId));

    return StreamBuilder<List<drift.TypedResult>>(
      stream: query.watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: const LogoLoader());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No consumables/BOM associated.'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final row = results[index];
            final consumable = row.readTable(db.productConsumables);
            final product = row.readTable(db.products);

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.build, color: const Color(0xff64748b)),
              ),
              title: Text(product.name),
              subtitle: Text('Reference: ${product.reference}'),
              trailing: Text(
                'Qty: ${consumable.quantityRequired.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
