import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../domain/products/product.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class QuantitySelectorDialog extends StatefulWidget {
  final Product product;
  final Decimal initialQuantity;

  const QuantitySelectorDialog({
    super.key,
    required this.product,
    required this.initialQuantity,
  });

  @override
  State<QuantitySelectorDialog> createState() => _QuantitySelectorDialogState();
}

class _QuantitySelectorDialogState extends State<QuantitySelectorDialog> {
  late TextEditingController _boxesController;
  late TextEditingController _unitsController;

  @override
  void initState() {
    super.initState();
    Decimal units = widget.initialQuantity;
    Decimal boxes = Decimal.zero;

    if (widget.product.unitsPerBox > 0) {
      final ratio = units / Decimal.fromInt(widget.product.unitsPerBox);
      boxes = ratio.toDecimal(scaleOnInfinitePrecision: 4);
    }

    _boxesController = TextEditingController(text: _formatDecimal(boxes));
    _unitsController = TextEditingController(text: _formatDecimal(units));
  }

  String _formatDecimal(Decimal d) {
    if (d == d.toBigInt().toDecimal()) {
      return d.toBigInt().toString();
    }
    return d.toString();
  }

  void _onBoxesChanged(String value) {
    if (value.isEmpty) {
      if (_unitsController.text.isNotEmpty) {
        _unitsController.text = '';
      }
      return;
    }
    final boxes = Decimal.tryParse(value);
    if (boxes != null) {
      final units = boxes * Decimal.fromInt(widget.product.unitsPerBox);
      final newUnitsStr = _formatDecimal(units);
      if (_unitsController.text != newUnitsStr) {
        _unitsController.text = newUnitsStr;
      }
    }
  }

  void _onUnitsChanged(String value) {
    if (value.isEmpty) {
      if (_boxesController.text.isNotEmpty) {
        _boxesController.text = '';
      }
      return;
    }
    final units = Decimal.tryParse(value);
    if (units != null) {
      if (widget.product.unitsPerBox > 0) {
        final ratio = units / Decimal.fromInt(widget.product.unitsPerBox);
        final boxes = ratio.toDecimal(scaleOnInfinitePrecision: 4);
        final newBoxesStr = _formatDecimal(boxes);
        if (_boxesController.text != newBoxesStr) {
          _boxesController.text = newBoxesStr;
        }
      }
    }
  }

  @override
  void dispose() {
    _boxesController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l10n?.adjustQuantity ?? "Adjust Quantity - "}${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _boxesController,
            decoration: InputDecoration(
              labelText: '${l10n?.boxes ?? "Boxes"} (x${widget.product.unitsPerBox})',
              suffixText: l10n?.boxes ?? 'boxes',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onBoxesChanged,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _unitsController,
            decoration: InputDecoration(
              labelText: 'Total ${l10n?.units ?? "Units"}',
              suffixText: l10n?.units ?? 'units',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onUnitsChanged,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(l10n?.cancel ?? 'CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            final units = Decimal.tryParse(_unitsController.text) ?? Decimal.zero;
            Navigator.pop(context, units);
          },
          child: Text(l10n?.save ?? 'SAVE'),
        ),
      ],
    );
  }
}
