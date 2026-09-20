import re

with open('lib/src/presentation/products/add_product_screen.dart', 'r') as f:
    content = f.read()

# For Pricing & Inventory
old_pricing_row = """                    Row(
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
                    ),"""

new_pricing_row = """                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final fields = [
                          TextFormField(
                            controller: _sellingPriceController,
                            decoration: _inputDecoration('Tier 1 Price (Base)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                          TextFormField(
                            controller: _tier2PriceController,
                            decoration: _inputDecoration('Tier 2 Price (Opt)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                          TextFormField(
                            controller: _tier3PriceController,
                            decoration: _inputDecoration('Tier 3 Price (Opt)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                          TextFormField(
                            controller: _baseMinimumStockController,
                            decoration: _inputDecoration('Base Min Stock'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                          TextFormField(
                            controller: _magazinMinimumStockController,
                            decoration: _inputDecoration('Magazin Min Stock'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                        ];

                        if (isMobile) {
                          return Column(
                            children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: f)).toList(),
                          );
                        } else {
                          return Row(
                            children: fields.map((f) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: f))).toList(),
                          );
                        }
                      }
                    ),"""

content = content.replace(old_pricing_row, new_pricing_row)

with open('lib/src/presentation/products/add_product_screen.dart', 'w') as f:
    f.write(content)
