import re

with open('lib/src/presentation/products/add_product_screen.dart', 'r') as f:
    content = f.read()

old_units_row = """                    Row(
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
                    ),"""

new_units_row = """                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final fields = [
                          TextFormField(
                            controller: _unitSizeController,
                            decoration: _inputDecoration('Unit Size (e.g. 7 for 7L)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateOptionalNumber,
                          ),
                          DropdownButtonFormField<String>(
                            value: _unit,
                            decoration: _inputDecoration(AppLocalizations.of(context)!.unit),
                            items: UnitConversionService.allUnits.map((String type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type == 'Unit' ? AppLocalizations.of(context)!.unit : (type == 'Box' ? AppLocalizations.of(context)!.box : type)));
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _unit = newValue);
                            },
                          ),
                          DropdownButtonFormField<String>(
                            value: _packagingType,
                            decoration: _inputDecoration('Packaging Type'),
                            items: _packagingOptions.map((String type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type == 'Unit' ? AppLocalizations.of(context)!.unit : (type == 'Box' ? AppLocalizations.of(context)!.box : type)));
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _packagingType = newValue);
                            },
                          ),
                        ];

                        if (isMobile) {
                          return Column(
                            children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 16), child: f)).toList(),
                          );
                        } else {
                          return Row(
                            children: fields.map((f) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: f))).toList(),
                          );
                        }
                      }
                    ),"""

content = content.replace(old_units_row, new_units_row)

with open('lib/src/presentation/products/add_product_screen.dart', 'w') as f:
    f.write(content)
