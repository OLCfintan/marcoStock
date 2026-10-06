import '../../utils/arabic_transliterator.dart';


import 'package:decimal/decimal.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_service.dart';
import 'package:uuid/uuid.dart';
import '../widgets/logo_loader.dart';

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
  String _searchQuery = '';

  void _showConsumableDialog(BuildContext context, Product product) {
    bool createBox = false;
    bool createBottle = false;
    bool createTicket = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${AppLocalizations.of(context)!.createConsumablesFor} ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.box),
                value: createBox,
                onChanged: (v) => setDialogState(() => createBox = v ?? false),
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.bottle),
                value: createBottle,
                onChanged: (v) => setDialogState(() => createBottle = v ?? false),
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.ticket),
                value: createTicket,
                onChanged: (v) => setDialogState(() => createTicket = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancelStr)),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.consumablesCreatedLinked)));
                }
              },
              child: Text(AppLocalizations.of(context)!.create),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGlobalUpdatePriceDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Global Update Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount in DH to add to selected products (use negative number to subtract):'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Amount (DH)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelStr)),
          ElevatedButton(
            onPressed: () async {
              final amount = Decimal.tryParse(ctrl.text);
              if (amount != null && amount != Decimal.zero) {
                Navigator.pop(ctx);
                final repo = ref.read(productRepositoryProvider);
                final allProducts = ref.read(productsStreamProvider).valueOrNull ?? [];
                
                for (final id in _selectedProductIds) {
                  final p = allProducts.firstWhere((prod) => prod.id == id);
                  
                  final newSellingPrice = p.sellingPrice + amount;
                  final newTier2 = (p.tier2Price != null) ? (p.tier2Price! + amount) : null;
                  final newTier3 = (p.tier3Price != null) ? (p.tier3Price! + amount) : null;
                  
                  final updatedProduct = Product(
                    id: p.id,
                    name: p.name,
                    nameAr: p.nameAr,
                    nameFr: p.nameFr,
                    nameEs: p.nameEs,
                    reference: p.reference,
                    category: p.category,
                    unit: p.unit,
                    unitSize: p.unitSize,
                    unitsPerBox: p.unitsPerBox,
                    purchasePrice: p.purchasePrice,
                    sellingPrice: newSellingPrice > Decimal.zero ? newSellingPrice : Decimal.zero,
                    tier2Price: (newTier2 != null && newTier2 > Decimal.zero) ? newTier2 : ((p.tier2Price != null) ? Decimal.zero : null),
                    tier3Price: (newTier3 != null && newTier3 > Decimal.zero) ? newTier3 : ((p.tier3Price != null) ? Decimal.zero : null),
                    minimumStock: p.minimumStock,
                    baseMinimumStock: p.baseMinimumStock,
                    magazinMinimumStock: p.magazinMinimumStock,
                    description: p.description,
                    imagePath: p.imagePath,
                    packagingType: p.packagingType,
                    isActive: p.isActive,
                    displayOrder: p.displayOrder,
                    createdAt: p.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  
                  await repo.updateProduct(updatedProduct);
                }
                
                setState(() {
                  _selectedProductIds.clear();
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prices updated globally!')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.productsCatalog),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: AppLocalizations.of(context)!.scanBarcode,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.openingScanner)),
              );
            },
          ),
          if (_selectedProductIds.isNotEmpty && ref.watch(currentUserProvider)?.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.price_change),
              tooltip: 'Global Update Price',
              onPressed: () {
                _showGlobalUpdatePriceDialog();
              },
            ),
          if (_selectedProductIds.isNotEmpty && ref.watch(currentUserProvider)?.role == 'ADMIN')
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: AppLocalizations.of(context)!.deleteStr,
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
        data: (allProducts) {
          final products = allProducts.where((p) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final aq = ArabicTransliterator.transliterate(_searchQuery);
            return p.name.toLowerCase().contains(q) || (p.name.contains(aq)) || p.reference.toLowerCase().contains(q);
          }).toList();
          
          if (products.isEmpty && _searchQuery.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noProductsAvailable));
          }
          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: PaginatedDataTable(
                header: TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.searchProducts,
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                onSelectAll: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedProductIds.addAll(products.map((p) => p.id));
                    } else {
                      _selectedProductIds.clear();
                    }
                  });
                },
                rowsPerPage: (products.length > 20) ? 20 : (products.length < 5 ? 5 : products.length),
                showCheckboxColumn: true,
                columns: [
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableActions)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableName)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableReference)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tablePackaging)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tablePurchasePrice)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableSellingPrice)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableTier2)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableTier3)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableBaseMin)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.tableMagazinMin)),
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
                  context: context,
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: const LogoLoader()),
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
        tooltip: AppLocalizations.of(context)!.addNewProduct,
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
  final BuildContext context;

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
    required this.context,
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
              PopupMenuItem(value: 'consumables', child: Text(AppLocalizations.of(context)!.createConsumables)),
              PopupMenuItem(value: 'family', child: Text(AppLocalizations.of(context)!.addFamilyMember)),
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
              if (isAdmin)
                PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))),
            ],
          ),
        ),
        buildCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        buildCell(Text(p.reference)),
        buildCell(Text('${p.packagingType} (${p.unitSize} ${p.unit})')),
        buildCell(Text('${p.purchasePrice.toStringAsFixed(2)} ${AppLocalizations.of(context)!.dhsStr}')),
        buildCell(Text('${p.sellingPrice.toStringAsFixed(2)} ${AppLocalizations.of(context)!.dhsStr}')),
        buildCell(Text('${p.tier2Price?.toStringAsFixed(2) ?? '-'} ${AppLocalizations.of(context)!.dhsStr}')),
        buildCell(Text('${p.tier3Price?.toStringAsFixed(2) ?? '-'} ${AppLocalizations.of(context)!.dhsStr}')),
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
