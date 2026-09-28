import '../../application/payments/payment_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
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
      title: Text('${AppLocalizations.of(context)!.paymentsRecord} ($entityType)'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: StreamBuilder<List<PaymentEntity>>(
          stream: paymentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: const LogoLoader());
            final payments = snapshot.data ?? [];
            if (payments.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noPaymentsRecorded));
            
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
                          tooltip: AppLocalizations.of(context)!.viewCheckImage,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.checkImage),
                                content: Image.file(File(p.checkImagePath!)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(AppLocalizations.of(context)!.close))
                                ],
                              ),
                            );
                          },
                        ),
                      if (p.isActive)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: AppLocalizations.of(context)!.deletePayment,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.deletePaymentConfirm),
                                content: Text(AppLocalizations.of(context)!.deletePaymentDesc),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancelStr)),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(paymentServiceProvider).deletePayment(p.id);
                            }
                          },
                        ),
                      if (!p.isActive)
                        Text(AppLocalizations.of(context)!.deletedStr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.close)),
      ],
    );
  }
}
