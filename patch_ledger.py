import re

with open('lib/src/presentation/widgets/payment_ledger_dialog.dart', 'r') as f:
    content = f.read()

# Add paymentServiceProvider import if missing
if "payment_service.dart" not in content:
    content = content.replace(
        "import '../../infrastructure/database/providers.dart';",
        "import '../../infrastructure/database/providers.dart';\nimport '../../application/payments/payment_service.dart';"
    )

old_logic = """  Future<void> _processPayments() async {
    final db = ref.read(databaseProvider);
    final uuid = const Uuid();
    
    try {
      await db.batch((batch) {
        for (var p in _payments) {
          final amt = Decimal.tryParse(p.amountController.text) ?? Decimal.zero;
          if (amt > Decimal.zero) {
            batch.insert(
              db.payments,
              PaymentsCompanion.insert(
                id: uuid.v4(),
                clientId: drift.Value(widget.clientId),
                supplierId: drift.Value(widget.supplierId),
                employeeId: drift.Value(widget.employeeId),
                amount: amt,
                method: p.method,
                checkImagePath: drift.Value(p.checkImagePath),
                date: DateTime.now(),
                status: 'CLEARED',
              ),
            );
          }
        }
      });
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorSavingPayments}$e')));
      }
    }
  }"""

new_logic = """  Future<void> _processPayments() async {
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
  }"""

content = content.replace(old_logic, new_logic)

with open('lib/src/presentation/widgets/payment_ledger_dialog.dart', 'w') as f:
    f.write(content)
