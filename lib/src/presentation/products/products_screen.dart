

import 'package:decimal/decimal.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_service.dart';
import 'package:uuid/uuid.dart';

import '../../application/products/product_providers.dart';
import '../../domain/products/product.dart';
import '../../infrastructure/repositories/product_repository.dart';

import 'add_product_screen.dart';
import '../widgets/item_navigator.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final Set<String> _selectedProductIds = {};


  void _showConsumableDialog(BuildContext context, Product product) {
    bool createBox = false;
    bool createBottle = false;
    bool createTicket = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Consumables for ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Box'),
                value: createBox,
                onChanged: (v) => setDialogState(() => createBox = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Bottle'),
                value: createBottle,
                onChanged: (v) => setDialogState(() => createBottle = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Ticket'),
                value: createTicket,
                onChanged: (v) => setDialogState(() => createTicket = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final db = ref.read(databaseProvider);
                final uuid = const Uuid();
                
                Future<void> createAndLink(String type) async {
                  final targetRef = '${product.reference}_$type';
                  final existing = await (db.select(db.products)..where((t) => t.reference.equals(targetRef))).getSingleOrNull();
                  
                  String cid;
                  if (existing != null) {
                    cid = existing.id;
                    // Optionally update the name if the parent's name changed
                    await (db.update(db.products)..where((t) => t.id.equals(cid))).write(
                      ProductsCompanion(
                        name: drift.Value('[$type] ${product.name} - ${product.unitSize}${product.unit}'),
                        isActive: const drift.Value(true),
                      )
                    );
                  } else {
                    cid = uuid.v4();
                    await db.into(db.products).insert(ProductsCompanion.insert(
                      id: cid,
                      name: '[$type] ${product.name} - ${product.unitSize}${product.unit}',
                      reference: targetRef,
                      unit: 'Unit',
                      unitSize: drift.Value(Decimal.parse('1')),
                      purchasePrice: Decimal.zero,
                      sellingPrice: Decimal.zero,
                      minimumStock: drift.Value(Decimal.zero),
                      packagingType: drift.Value(type),
                      isActive: const drift.Value(true)
                    ));
                  }
                  
                  await db.into(db.productConsumables).insert(ProductConsumablesCompanion.insert(
                    productId: product.id,
                    consumableId: cid,
                    quantityRequired: Decimal.parse('1'),
                  ), mode: drift.InsertMode.replace);
                }
                
                if (createBox) await createAndLink('Box');
                if (createBottle) await createAndLink('Bottle');
                if (createTicket) await createAndLink('Ticket');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consumables created and linked!')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Scanner')),
              );
            },
          ),
          if (_selectedProductIds.isNotEmpty && ref.watch(currentUserProvider)?.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: () async {
                final repo = ref.read(productRepositoryProvider);
                for (final id in _selectedProductIds) {
                  await repo.deleteProduct(id);
                }
                setState(() {
                  _selectedProductIds.clear();
                });
              },
            ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }
          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: PaginatedDataTable(
                header: const Text('Products Inventory'),
                rowsPerPage: (products.length > 20) ? 20 : (products.length < 5 ? 5 : products.length),
                showCheckboxColumn: true,
                columns: const [
                  DataColumn(label: Text('Actions')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Reference')),
                  DataColumn(label: Text('Packaging')),
                  DataColumn(label: Text('Purchase Price')),
                  DataColumn(label: Text('Selling Price')),
                  DataColumn(label: Text('Tier 2 Price')),
                  DataColumn(label: Text('Tier 3 Price')),
                  DataColumn(label: Text('Base Min')),
                  DataColumn(label: Text('Magazin Min')),
                ],
                source: _ProductDataSource(
                  products: products,
                  selectedIds: _selectedProductIds,
                  onSelectChanged: (id, selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedProductIds.add(id);
                      } else {
                        _selectedProductIds.remove(id);
                      }
                    });
                  },
                  onConsumable: (p) => _showConsumableDialog(context, p),
                  onEdit: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(productToEdit: p))),
                  onAddFamilyMember: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(templateProduct: p))),
                  onDelete: (p) async {
                    final db = ref.read(databaseProvider);
                    await (db.update(db.products)..where((t) => t.id.equals(p.id))).write(const ProductsCompanion(isActive: drift.Value(false)));
                  },
                  onDoubleTap: (p) => ItemNavigator.openProduct(context, p),
                  isAdmin: ref.watch(currentUserProvider)?.role == 'ADMIN',
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${(AppLocalizations.of(context)?.errorStr ?? 'Error: ')}$err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class _ProductDataSource extends DataTableSource {
  final List<Product> products;
  final Set<String> selectedIds;
  final Function(String, bool?) onSelectChanged;
  final Function(Product) onConsumable;
  final Function(Product) onEdit;
  final Function(Product) onAddFamilyMember;
  final Function(Product) onDelete;
  final Function(Product) onDoubleTap;
  final bool isAdmin;

  _ProductDataSource({
    required this.products,
    required this.selectedIds,
    required this.onSelectChanged,
    required this.onConsumable,
    required this.onEdit,
    required this.onAddFamilyMember,
    required this.onDelete,
    required this.onDoubleTap,
    required this.isAdmin,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= products.length) return null;
    final p = products[index];
    
    DataCell buildCell(Widget child) {
      return DataCell(child, onDoubleTap: () => onDoubleTap(p));
    }
    
    return DataRow(
      selected: selectedIds.contains(p.id),
      onSelectChanged: (selected) => onSelectChanged(p.id, selected),
      cells: [
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'consumables') onConsumable(p);
              if (value == 'edit') onEdit(p);
              if (value == 'delete') onDelete(p);
              if (value == 'family') onAddFamilyMember(p);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'consumables', child: Text('Create Consumables')),
              const PopupMenuItem(value: 'family', child: Text('Add Family Member')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (isAdmin)
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
        buildCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        buildCell(Text(p.reference)),
        buildCell(Text('${p.packagingType} (${p.unitSize} ${p.unit})')),
        buildCell(Text('${p.purchasePrice.toStringAsFixed(2)} Dhs')),
        buildCell(Text('${p.sellingPrice.toStringAsFixed(2)} Dhs')),
        buildCell(Text('${p.tier2Price?.toStringAsFixed(2) ?? '-'} Dhs')),
        buildCell(Text('${p.tier3Price?.toStringAsFixed(2) ?? '-'} Dhs')),
        buildCell(Text(p.baseMinimumStock.toString())),
        buildCell(Text(p.magazinMinimumStock.toString())),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => products.length;

  @override
  int get selectedRowCount => selectedIds.length;
}
