import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../infrastructure/database/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

import '../widgets/image_picker_field.dart';
import '../../application/products/product_providers.dart';
import '../../domain/products/product.dart';
import '../../infrastructure/repositories/product_repository.dart';
import '../../application/system/unit_conversion_service.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;
  final Product? templateProduct;
  const AddProductScreen({super.key, this.productToEdit, this.templateProduct});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _nameFrController = TextEditingController();
  final _nameEsController = TextEditingController();
  final _referenceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

      final _tier2PriceController = TextEditingController();
  final _tier3PriceController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _baseMinimumStockController = TextEditingController();
  final _magazinMinimumStockController = TextEditingController();
  final _unitSizeController = TextEditingController(text: "1");
  final _unitsPerBoxController = TextEditingController(text: "1");

  String _unit = 'Unit';

  String _packagingType = 'Unit';
  String? _imagePath;
  final List<String> _packagingOptions = ['Unit', 'Box', 'Ticket', 'Bottle'];

  final List<Map<String, dynamic>> _linkedProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null || widget.templateProduct != null) {
      final source = widget.productToEdit ?? widget.templateProduct!;
      _nameController.text = source.name;
      _nameArController.text = source.nameAr ?? '';
      _nameFrController.text = source.nameFr ?? '';
      _nameEsController.text = source.nameEs ?? '';
      if (widget.productToEdit != null) _loadConsumables();
      _referenceController.text = source.reference;
      _sellingPriceController.text = source.sellingPrice.toStringAsFixed(2);
      _tier2PriceController.text = source.tier2Price?.toStringAsFixed(2) ?? '';
      _tier3PriceController.text = source.tier3Price?.toStringAsFixed(2) ?? '';
      _minimumStockController.text = source.minimumStock.toString();
      _baseMinimumStockController.text = source.baseMinimumStock.toString();
      _magazinMinimumStockController.text = source.magazinMinimumStock.toString();
      _imagePath = source.imagePath;
      _unitSizeController.text = source.unitSize.toString();
      _unitsPerBoxController.text = source.unitsPerBox.toString();
      final u = source.unit;
      _unit = UnitConversionService.allUnits.contains(u) ? u : 
               (UnitConversionService.allUnits.contains(u.toLowerCase()) ? u.toLowerCase() : 
               (UnitConversionService.allUnits.contains(u.toUpperCase()) ? u.toUpperCase() : 'Unit'));
      if (_packagingOptions.contains(source.packagingType)) {
          _packagingType = source.packagingType!;
      }
    }
  }

  Future<void> _loadConsumables() async {
    final repo = ref.read(productRepositoryProvider);
    final consumables = await repo.getConsumables(widget.productToEdit!.id);
    final allProducts = await repo.getAllProducts();
    
    if (consumables.isNotEmpty && mounted) {
      setState(() {
        for (final c in consumables) {
          final p = allProducts.firstWhere((prod) => prod.id == c.consumableId, orElse: () => widget.productToEdit!);
          _linkedProducts.add({
            'consumableId': c.consumableId,
            'consumableName': p.name,
            'quantityRequired': TextEditingController(text: c.quantityRequired.toString()),
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _nameFrController.dispose();
    _nameEsController.dispose();
    _referenceController.dispose();
    _sellingPriceController.dispose();

    _tier2PriceController.dispose();
    _tier3PriceController.dispose();
    _minimumStockController.dispose();
    _baseMinimumStockController.dispose();
    _magazinMinimumStockController.dispose();
    _unitSizeController.dispose();
    _unitsPerBoxController.dispose();
    for (final linked in _linkedProducts) {
      (linked['quantityRequired'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addLinkedProduct() {
    setState(() {
      _linkedProducts.add({
        'consumableId': null,
        'consumableName': null,
        'consumableUnit': null,
        'selectedUnit': 'Unit',
        'quantityRequired': TextEditingController(text: '1'),
      });
    });
  }

  void _removeLinkedProduct(int index) {
    setState(() {
      (_linkedProducts[index]['quantityRequired'] as TextEditingController).dispose();
      _linkedProducts.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final db = ref.read(databaseProvider);
    final refToCheck = _referenceController.text.trim();
    final existingRefList = await (db.select(db.products)..where((t) => t.reference.equals(refToCheck))).get();
    if (existingRefList.isNotEmpty && existingRefList.first.id != widget.productToEdit?.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product with this Reference already exists!')));
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fillRequiredFields)));
      return;
    }
    try {

    for (final linked in _linkedProducts) {
      if (linked['consumableId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.selectValidProductForLinked)),
        );
        return;
      }
    }

    final repo = ref.read(productRepositoryProvider);
    final id = const Uuid().v4();

    Decimal? tryParseDecimal(String text) {
      if (text.trim().isEmpty) return null;
      try {
        return Decimal.parse(text.trim());
      } catch (_) {
        return null;
      }
    }

    if (widget.productToEdit != null) {
      final product = widget.productToEdit!.copyWith(
        name: _nameController.text.trim(),
        nameAr: _nameArController.text.trim().isEmpty ? null : _nameArController.text.trim(),
        nameFr: _nameFrController.text.trim().isEmpty ? null : _nameFrController.text.trim(),
        nameEs: _nameEsController.text.trim().isEmpty ? null : _nameEsController.text.trim(),
        reference: _referenceController.text.trim().isEmpty ? widget.productToEdit!.id.substring(0, 8).toUpperCase() : _referenceController.text.trim(),
        unit: _unit,
        unitSize: tryParseDecimal(_unitSizeController.text) ?? Decimal.one,
        unitsPerBox: int.tryParse(_unitsPerBoxController.text) ?? 1,
        sellingPrice: tryParseDecimal(_sellingPriceController.text) ?? Decimal.zero,
        tier2Price: tryParseDecimal(_tier2PriceController.text),
        tier3Price: tryParseDecimal(_tier3PriceController.text),
        minimumStock: tryParseDecimal(_minimumStockController.text) ?? Decimal.zero,
        baseMinimumStock: tryParseDecimal(_baseMinimumStockController.text) ?? Decimal.zero,
        magazinMinimumStock: tryParseDecimal(_magazinMinimumStockController.text) ?? Decimal.zero,
        packagingType: _packagingType,
        imagePath: _imagePath,
        updatedAt: DateTime.now(),
      );
      await repo.updateProduct(product);
      final mappedConsumables = _linkedProducts.map((e) => {
        'consumableId': e['consumableId'],
        'quantityRequired': Decimal.parse((e['quantityRequired'] as TextEditingController).text),
      }).toList();
      await repo.replaceConsumables(product.id, mappedConsumables);
    } else {
      final product = Product(
        id: id,
        name: _nameController.text.trim(),
        nameAr: _nameArController.text.trim().isEmpty ? null : _nameArController.text.trim(),
        nameFr: _nameFrController.text.trim().isEmpty ? null : _nameFrController.text.trim(),
        nameEs: _nameEsController.text.trim().isEmpty ? null : _nameEsController.text.trim(),
        reference: _referenceController.text.trim().isEmpty ? id.substring(0, 8).toUpperCase() : _referenceController.text.trim(),
        unit: _unit,
        unitSize: tryParseDecimal(_unitSizeController.text) ?? Decimal.one,
        unitsPerBox: int.tryParse(_unitsPerBoxController.text) ?? 1,
        purchasePrice: Decimal.zero, // Auto-calculated via PurchaseService WAC
        sellingPrice: tryParseDecimal(_sellingPriceController.text) ?? Decimal.zero,
        tier2Price: tryParseDecimal(_tier2PriceController.text),
        tier3Price: tryParseDecimal(_tier3PriceController.text),
        minimumStock: tryParseDecimal(_minimumStockController.text) ?? Decimal.zero,
        baseMinimumStock: tryParseDecimal(_baseMinimumStockController.text) ?? Decimal.zero,
        magazinMinimumStock: tryParseDecimal(_magazinMinimumStockController.text) ?? Decimal.zero,
        packagingType: _packagingType,
        imagePath: _imagePath,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createProduct(product);
      final mappedConsumables = _linkedProducts.map((e) => {
        'consumableId': e['consumableId'],
        'quantityRequired': Decimal.parse((e['quantityRequired'] as TextEditingController).text),
      }).toList();
      await repo.replaceConsumables(product.id, mappedConsumables);
    }



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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? 'Edit Product' : (widget.templateProduct != null ? 'Add Family Member' : AppLocalizations.of(context)!.addNewProduct)),
        elevation: 0,
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
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: RawAutocomplete<String>(
                            textEditingController: _nameController,
                            focusNode: FocusNode(),
                            optionsBuilder: (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              final repo = ref.read(productRepositoryProvider);
                              final products = await repo.getAllProducts();
                              return products
                                  .where((p) => p.packagingType == 'Unit' && p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                                  .map((p) => p.name)
                                  .toSet();
                            },
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: _inputDecoration('Product Name (Family/Base)'),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  child: SizedBox(
                                    width: 300,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final String option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () {
                                            onSelected(option);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(option),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _referenceController,
                            decoration: _inputDecoration('Reference'),
                            
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Add Translations / Local Names (Optional)', style: TextStyle(color: Colors.blueGrey)),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: [
                        TextFormField(
                          controller: _nameArController,
                          decoration: _inputDecoration('Name (Arabic)'),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameFrController,
                          decoration: _inputDecoration('Name (French)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameEsController,
                          decoration: _inputDecoration('Name (Spanish)'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _unitSizeController,
                            decoration: _inputDecoration('Unit Size (e.g. 7 for 7L)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            decoration: _inputDecoration(AppLocalizations.of(context)!.unit),
                            items: UnitConversionService.allUnits.map((String type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type == 'Unit' ? AppLocalizations.of(context)!.unit : (type == 'Box' ? AppLocalizations.of(context)!.box : type)));
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _unit = newValue);
                            },
                          ),
                        ),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _packagingType,
                            decoration: _inputDecoration('Packaging Type'),
                            items: _packagingOptions.map((String type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type == 'Unit' ? AppLocalizations.of(context)!.unit : (type == 'Box' ? AppLocalizations.of(context)!.box : type)));
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _packagingType = newValue);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _unitsPerBoxController,
                      decoration: _inputDecoration('Units Per Box (For Inventory Math)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be integer';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ImagePickerField(
                      label: 'Product Image',
                      onChanged: (val) => setState(() => _imagePath = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Pricing & Inventory', Icons.attach_money),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            decoration: _inputDecoration('Tier 1 Price (Base)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _tier2PriceController,
                            decoration: _inputDecoration('Tier 2 Price (Opt)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _tier3PriceController,
                            decoration: _inputDecoration('Tier 3 Price (Opt)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _baseMinimumStockController,
                            decoration: _inputDecoration('Base Min Stock'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _magazinMinimumStockController,
                            decoration: _inputDecoration('Magazin Min Stock'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Linked / Composite Products (BOM)', Icons.link),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.addConsumablesDesc),
                    const SizedBox(height: 16),
                    if (_linkedProducts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No linked products added.', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ...List.generate(_linkedProducts.length, (index) {
                      final item = _linkedProducts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: productsAsync.when(
                                data: (products) {
                                  return Autocomplete<Product>(
                                    displayStringForOption: (p) => '${p.name} (${p.reference})',
                                    optionsBuilder: (textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<Product>.empty();
                                      }
                                      return products.where((p) =>
                                          p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                          p.reference.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (Product selection) {
                                      setState(() {
                                        _linkedProducts[index]['consumableId'] = selection.id;
                                        _linkedProducts[index]['consumableName'] = selection.name;
                                      });
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                      if (item['consumableName'] != null && controller.text.isEmpty) {
                                        controller.text = item['consumableName'] as String;
                                      }
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        onEditingComplete: onEditingComplete,
                                        decoration: _inputDecoration('Search Product...'),
                                        validator: (val) => item['consumableId'] == null ? 'Select product' : null,
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, s) => Text('${AppLocalizations.of(context)!.errorLoadingProducts}$e'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: item['quantityRequired'] as TextEditingController,
                                decoration: _inputDecoration('Qty'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: _validateOptionalNumber,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeLinkedProduct(index),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addLinkedProduct,
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addConsumable),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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

  String? _validateOptionalNumber(String? value) {
    if (value != null && value.trim().isNotEmpty && Decimal.tryParse(value.trim()) == null) {
      return 'Invalid number';
    }
    return null;
  }
}
