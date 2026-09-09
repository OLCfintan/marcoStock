import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
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
                  trailing: p.checkImagePath != null && p.checkImagePath!.isNotEmpty
                      ? IconButton(
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
                        )
                      : null,
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
