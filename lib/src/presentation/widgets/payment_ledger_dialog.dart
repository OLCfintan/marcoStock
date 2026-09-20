import '../../application/hr/hr_providers.dart';
import '../../application/suppliers/supplier_providers.dart';
import '../../application/clients/client_providers.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import '../../application/payments/payment_service.dart';
import 'package:drift/drift.dart' as drift;
import 'image_picker_field.dart';
import 'package:uuid/uuid.dart';

class PaymentLedgerDialog extends ConsumerStatefulWidget {
  final String? clientId;
  final String? supplierId;
  final String? employeeId;
  final Decimal initialBalance;
  final String entityName;

  const PaymentLedgerDialog({
    super.key,
    this.clientId,
    this.supplierId,
    this.employeeId,
    required this.initialBalance,
    required this.entityName,
  });

  @override
  ConsumerState<PaymentLedgerDialog> createState() => _PaymentLedgerDialogState();
}

class _PaymentEntry {
  late final TextEditingController amountController;
  String method = 'CASH';
  String? checkImagePath;

  _PaymentEntry({
    String initialAmount = '',
  }) {
    amountController = TextEditingController(text: initialAmount);
  }
}

class _PaymentLedgerDialogState extends ConsumerState<PaymentLedgerDialog> {
  final List<_PaymentEntry> _payments = [];
  
  @override
  void initState() {
    super.initState();
    _payments.add(_PaymentEntry());
  }

  @override
  void dispose() {
    for (var p in _payments) {
      p.amountController.dispose();
    }
    super.dispose();
  }

  Decimal get _totalPaid {
    Decimal total = Decimal.zero;
    for (var p in _payments) {
      if (p.method != 'CREDIT') {
        final amt = Decimal.tryParse(p.amountController.text) ?? Decimal.zero;
        total += amt;
      }
    }
    return total;
  }

  Future<void> _processPayments() async {
    final paymentService = ref.read(paymentServiceProvider);
    
    try {
      for (var p in _payments) {
        final amt = Decimal.tryParse(p.amountController.text) ?? Decimal.zero;
        if (amt > Decimal.zero) {
          await paymentService.allocatePayment(
            clientId: widget.clientId,
            supplierId: widget.supplierId,
            employeeId: widget.employeeId,
            amount: amt,
            method: p.method,
            checkImagePath: p.checkImagePath,
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorSavingPayments}$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Decimal currentBalance = widget.initialBalance;
    if (widget.clientId != null) {
      final clientsAsync = ref.watch(clientsStreamProvider);
      final c = clientsAsync.value?.where((e) => e.id == widget.clientId).firstOrNull;
      if (c != null) currentBalance = c.balance;
    } else if (widget.supplierId != null) {
      final suppliersAsync = ref.watch(suppliersStreamProvider);
      final s = suppliersAsync.value?.where((e) => e.id == widget.supplierId).firstOrNull;
      if (s != null) currentBalance = s.balance;
    } else if (widget.employeeId != null) {
      final employeesAsync = ref.watch(employeesStreamProvider);
      final e = employeesAsync.value?.where((e) => e.id == widget.employeeId).firstOrNull;
      if (e != null) currentBalance = e.remainingSalary;
    }
    
    final remainingBalance = currentBalance - _totalPaid;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Payment for ${widget.entityName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Balance:', style: TextStyle(fontSize: 16)),
                Text('${currentBalance.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remaining after Payment:', style: TextStyle(fontSize: 16)),
                Text('${remainingBalance.toStringAsFixed(2)} Dhs', style: TextStyle(fontSize: 16, color: remainingBalance >= Decimal.zero ? Colors.red : Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final p = _payments[index];
                  return Card(
                    
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: p.method,
                                  decoration: const InputDecoration(labelText: 'Method', isDense: true),
                                  items: [
                                    DropdownMenuItem(value: 'CASH', child: Text(AppLocalizations.of(context)!.cash.toUpperCase())),
                                    DropdownMenuItem(value: 'CHECK', child: Text(AppLocalizations.of(context)!.check.toUpperCase())),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      p.method = val!;
                                      if (val == 'CREDIT') {
                                        p.amountController.text = '0';
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: p.amountController,
                                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (val) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    p.amountController.dispose();
                                    _payments.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          if (p.method == 'CHECK') ...[
                            const SizedBox(height: 8),
                            ImagePickerField(
                              label: AppLocalizations.of(context)!.checkImage,
                              initialValue: p.checkImagePath,
                              onChanged: (path) => setState(() => p.checkImagePath = path),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _payments.add(_PaymentEntry(
                    initialAmount: remainingBalance > Decimal.zero ? remainingBalance.toStringAsFixed(2) : '',
                  ));
                });
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addPaymentMethod),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _processPayments,
                  child: Text(AppLocalizations.of(context)!.confirmPayment.toUpperCase()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
