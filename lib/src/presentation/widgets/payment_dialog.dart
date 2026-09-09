import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:decimal/decimal.dart';
import "image_picker_field.dart";
import 'package:uuid/uuid.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final String entityId;
  final String entityType; // 'INVOICE' or 'PURCHASE'
  final String? partnerId; // clientId or supplierId
  final Decimal currentTotal;
  final Decimal currentlyPaid;

  const PaymentDialog({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.partnerId,
    required this.currentTotal,
    required this.currentlyPaid,
  });

  static Future<void> show(BuildContext context, {
    required String entityId,
    required String entityType,
    String? partnerId,
    required Decimal currentTotal,
    required Decimal currentlyPaid,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PaymentDialog(
        entityId: entityId,
        entityType: entityType,
        partnerId: partnerId,
        currentTotal: currentTotal,
        currentlyPaid: currentlyPaid,
      ),
    );
  }

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _amountController = TextEditingController();
  final _methodController = TextEditingController(text: 'CASH');
  bool _isSubmitting = false;
  String? _checkImagePath;

  @override
  void dispose() {
    _amountController.dispose();
    _methodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;
    final amount = Decimal.tryParse(amountStr);
    if (amount == null || amount <= Decimal.zero) return;

    setState(() => _isSubmitting = true);
    
    try {
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        final uuid = const Uuid().v4();
        
        // 1. Record Payment
        if (widget.entityType == 'INVOICE') {
          await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: uuid,
            clientId: drift.Value(widget.partnerId),
            invoiceId: drift.Value(widget.entityId),
            amount: amount,
            method: _methodController.text,
            checkImagePath: drift.Value(_checkImagePath),
            date: DateTime.now(),
            status: 'CLEARED',
          ));
          
          // 2. Update Invoice Status
          final newPaid = widget.currentlyPaid + amount;
          String newStatus = 'UNPAID';
          if (newPaid >= widget.currentTotal) newStatus = 'PAID';
          else if (newPaid > Decimal.zero) newStatus = 'PARTIAL';
          
          await (db.update(db.invoices)..where((t) => t.id.equals(widget.entityId))).write(
            InvoicesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
          
          // 3. Update Client Balance (Subtract amount because they paid their debt)
          if (widget.partnerId != null) {
            final client = await (db.select(db.clients)..where((t) => t.id.equals(widget.partnerId!))).getSingleOrNull();
            if (client != null) {
              await db.update(db.clients).replace(client.copyWith(balance: client.balance - amount));
            }
          }
        } else {
          // PURCHASE
          await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: uuid,
            supplierId: drift.Value(widget.partnerId),
            purchaseId: drift.Value(widget.entityId),
            amount: amount,
            method: _methodController.text,
            checkImagePath: drift.Value(_checkImagePath),
            date: DateTime.now(),
            status: 'CLEARED',
          ));
          
          // 2. Update Purchase Status
          final newPaid = widget.currentlyPaid + amount;
          String newStatus = 'UNPAID';
          if (newPaid >= widget.currentTotal) newStatus = 'PAID';
          else if (newPaid > Decimal.zero) newStatus = 'PARTIAL';
          
          await (db.update(db.purchases)..where((t) => t.id.equals(widget.entityId))).write(
            PurchasesCompanion(status: drift.Value(newStatus), paidAmount: drift.Value(newPaid))
          );
          
          // 3. Update Supplier Balance (Subtract amount because we paid our debt)
          if (widget.partnerId != null) {
            final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals(widget.partnerId!))).getSingleOrNull();
            if (supplier != null) {
              await db.update(db.suppliers).replace(supplier.copyWith(balance: supplier.balance - amount));
            }
          }
        }
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded successfully!')));
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (errMsg.contains('no such column: purchase_id')) {
          errMsg = 'Migration pending! You MUST fully restart the app (close and reopen) to apply the new database schema.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.currentTotal - widget.currentlyPaid;
    
    return AlertDialog(
      title: Text('Record Payment (${widget.entityType})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total: ${widget.currentTotal.toStringAsFixed(2)} Dhs'),
          Text('Paid: ${widget.currentlyPaid.toStringAsFixed(2)} Dhs'),
          Text('Remaining: ${remaining.toStringAsFixed(2)} Dhs', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              suffixText: 'Dhs',
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Set to full remaining',
                onPressed: () {
                  _amountController.text = remaining.toStringAsFixed(2);
                },
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _methodController.text,
            items: ['CASH', 'CARD', 'CHECK', 'TRANSFER'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _methodController.text = v);
            },
            decoration: const InputDecoration(labelText: 'Payment Method'),
          ),
          if (_methodController.text == 'CHECK') ...[
            const SizedBox(height: 16),
            ImagePickerField(
              label: 'Check Image (Optional)',
              initialValue: _checkImagePath,
              onChanged: (path) => setState(() => _checkImagePath = path),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Record'),
        ),
      ],
    );
  }
}
