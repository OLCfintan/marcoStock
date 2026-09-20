import '../../application/payments/payment_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/logo_loader.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

class ViewPaymentsDialog extends ConsumerWidget {
  final String entityId;
  final String entityType; // 'INVOICE' or 'PURCHASE'

  const ViewPaymentsDialog({super.key, required this.entityId, required this.entityType});

  static Future<void> show(BuildContext context, {required String entityId, required String entityType}) {
    return showDialog(
      context: context,
      builder: (ctx) => ViewPaymentsDialog(entityId: entityId, entityType: entityType),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final paymentsStream = entityType == 'INVOICE'
        ? (db.select(db.payments)..where((t) => t.invoiceId.equals(entityId))).watch()
        : (db.select(db.payments)..where((t) => t.purchaseId.equals(entityId))).watch();

    return AlertDialog(
      title: Text('Payments Record ($entityType)'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: StreamBuilder<List<PaymentEntity>>(
          stream: paymentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: const LogoLoader());
            final payments = snapshot.data ?? [];
            if (payments.isEmpty) return const Center(child: Text('No payments recorded.'));
            
            return ListView.separated(
              itemCount: payments.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final p = payments[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.payment)),
                  title: Text('${p.amount.toStringAsFixed(2)} Dhs - ${p.method}'),
                  subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(p.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.checkImagePath != null && p.checkImagePath!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.teal),
                          tooltip: 'View Check Image',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Check Image'),
                                content: Image.file(File(p.checkImagePath!)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close'))
                                ],
                              ),
                            );
                          },
                        ),
                      if (p.isActive)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete Payment',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Payment?'),
                                content: const Text('This will algebraically reverse the payment.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(paymentServiceProvider).deletePayment(p.id);
                            }
                          },
                        ),
                      if (!p.isActive)
                        const Text('DELETED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
