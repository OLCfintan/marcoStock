import 'package:intl/intl.dart';
import '../../application/auth/auth_service.dart';
import '../../application/payments/payment_service.dart';
import '../../application/purchases/purchase_service.dart';
import '../../application/sales/sales_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/database/providers.dart';
import '../../infrastructure/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import '../widgets/status_badge.dart';
import '../../utils/arabic_transliterator.dart';

class GarbageScreen extends ConsumerStatefulWidget {
  const GarbageScreen({super.key});

  @override
  ConsumerState<GarbageScreen> createState() => _GarbageScreenState();
}

class _GarbageScreenState extends ConsumerState<GarbageScreen> {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin (Admin Only)'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.green),
              tooltip: 'Restore Selected',
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final userId = ref.read(currentUserProvider)?.id ?? '';
                final salesSvc = ref.read(salesServiceProvider);
                final purchSvc = ref.read(purchaseServiceProvider);
                final paySvc = ref.read(paymentServiceProvider);

                for (final id in _selectedIds.toList()) {
                  final isInvoice = await (db.select(db.invoices)..where((t) => t.id.equals(id))).getSingleOrNull();
                  if (isInvoice != null) {
                    await salesSvc.restoreInvoice(id, userId);
                    continue;
                  }
                  final isPurchase = await (db.select(db.purchases)..where((t) => t.id.equals(id))).getSingleOrNull();
                  if (isPurchase != null) {
                    await purchSvc.restorePurchase(id, userId);
                    continue;
                  }
                  final isPayment = await (db.select(db.payments)..where((t) => t.id.equals(id))).getSingleOrNull();
                  if (isPayment != null) {
                    await paySvc.restorePayment(id);
                    continue;
                  }
                }
                setState(() => _selectedIds.clear());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected items restored successfully.')));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Permanently Delete Selected',
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await db.transaction(() async {
                  for (final id in _selectedIds.toList()) {
                    final isInvoice = await (db.select(db.invoices)..where((t) => t.id.equals(id))).getSingleOrNull();
                    if (isInvoice != null) {
                      await (db.delete(db.invoiceLines)..where((t) => t.invoiceId.equals(id))).go();
                      await (db.delete(db.payments)..where((t) => t.invoiceId.equals(id))).go();
                      await (db.delete(db.stockMovements)..where((t) => t.referenceOperationId.equals(id))).go();
                      await (db.delete(db.auditLogs)..where((t) => t.entityId.equals(id))).go();
                      await (db.delete(db.syncOutbox)..where((t) => t.entityId.equals(id))).go();
                      await (db.delete(db.invoices)..where((t) => t.id.equals(id))).go();
                      continue;
                    }
                    final isPurchase = await (db.select(db.purchases)..where((t) => t.id.equals(id))).getSingleOrNull();
                    if (isPurchase != null) {
                      await (db.delete(db.purchaseLines)..where((t) => t.purchaseId.equals(id))).go();
                      await (db.delete(db.payments)..where((t) => t.purchaseId.equals(id))).go();
                      await (db.delete(db.stockMovements)..where((t) => t.referenceOperationId.equals(id))).go();
                      await (db.delete(db.auditLogs)..where((t) => t.entityId.equals(id))).go();
                      await (db.delete(db.syncOutbox)..where((t) => t.entityId.equals(id))).go();
                      await (db.delete(db.purchases)..where((t) => t.id.equals(id))).go();
                      continue;
                    }
                    final isPayment = await (db.select(db.payments)..where((t) => t.id.equals(id))).getSingleOrNull();
                    if (isPayment != null) {
                      await (db.delete(db.payments)..where((t) => t.id.equals(id))).go();
                      continue;
                    }
                  }
                });
                setState(() => _selectedIds.clear());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected items deleted permanently.')));
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Recycle Bin',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSection<InvoiceEntity>(
                  context,
                  'Deleted Invoices & Bons',
                  (db.select(db.invoices)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
                  (invoice) => invoice.id,
                  (invoice) => '${invoice.documentType} - ${invoice.invoiceNumber}',
                  (invoice) async {
                    final userId = ref.read(currentUserProvider)?.id ?? '';
                    await ref.read(salesServiceProvider).restoreInvoice(invoice.id, userId);
                  },
                  (invoice) async {
                    await db.transaction(() async {
                      await (db.delete(db.invoiceLines)..where((t) => t.invoiceId.equals(invoice.id))).go();
                      await (db.delete(db.payments)..where((t) => t.invoiceId.equals(invoice.id))).go();
                      await (db.delete(db.stockMovements)..where((t) => t.referenceOperationId.equals(invoice.id))).go();
                      await (db.delete(db.auditLogs)..where((t) => t.entityId.equals(invoice.id))).go();
                      await (db.delete(db.syncOutbox)..where((t) => t.entityId.equals(invoice.id))).go();
                      await (db.delete(db.invoices)..where((t) => t.id.equals(invoice.id))).go();
                    });
                  },
                  buildSubtitle: (invoice) {
                    return FutureBuilder<ClientEntity?>(
                      future: invoice.clientId != null ? (db.select(db.clients)..where((t) => t.id.equals(invoice.clientId!))).getSingleOrNull() : Future.value(null),
                      builder: (ctx, snap) {
                        final clientName = snap.data?.name ?? 'Walk-in Client';
                        return Text('${DateFormat('MMM dd, yyyy (EEEE)').format(invoice.date)} | Client: $clientName | Total: ${invoice.total} Dhs');
                      },
                    );
                  },
                ),
                _buildSection<PurchaseEntity>(
                  context,
                  'Deleted Purchases',
                  (db.select(db.purchases)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
                  (purchase) => purchase.id,
                  (purchase) => 'Purchase - ${purchase.purchaseNumber}',
                  (purchase) async {
                    final userId = ref.read(currentUserProvider)?.id ?? '';
                    await ref.read(purchaseServiceProvider).restorePurchase(purchase.id, userId);
                  },
                  (purchase) async {
                    await db.transaction(() async {
                      await (db.delete(db.purchaseLines)..where((t) => t.purchaseId.equals(purchase.id))).go();
                      await (db.delete(db.payments)..where((t) => t.purchaseId.equals(purchase.id))).go();
                      await (db.delete(db.stockMovements)..where((t) => t.referenceOperationId.equals(purchase.id))).go();
                      await (db.delete(db.auditLogs)..where((t) => t.entityId.equals(purchase.id))).go();
                      await (db.delete(db.syncOutbox)..where((t) => t.entityId.equals(purchase.id))).go();
                      await (db.delete(db.purchases)..where((t) => t.id.equals(purchase.id))).go();
                    });
                  },
                  buildSubtitle: (purchase) {
                    return FutureBuilder<SupplierEntity?>(
                      future: purchase.supplierId != null ? (db.select(db.suppliers)..where((t) => t.id.equals(purchase.supplierId!))).getSingleOrNull() : Future.value(null),
                      builder: (ctx, snap) {
                        final supplierName = snap.data?.name ?? 'Unknown Supplier';
                        return Text('${DateFormat('MMM dd, yyyy (EEEE)').format(purchase.date)} | Supplier: $supplierName | Total: ${purchase.total} Dhs');
                      },
                    );
                  },
                ),
                _buildSection<PaymentEntity>(
                  context,
                  'Deleted Payments & Checks',
                  (db.select(db.payments)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
                  (payment) => payment.id,
                  (payment) => '${payment.method} - ${payment.amount} Dhs',
                  (payment) async => await ref.read(paymentServiceProvider).restorePayment(payment.id),
                  (payment) async => await (db.delete(db.payments)..where((t) => t.id.equals(payment.id))).go(),
                  buildSubtitle: (payment) {
                    return Row(
                      children: [
                        Text('${DateFormat('MMM dd, yyyy (EEEE)').format(payment.date)} '),
                        const SizedBox(width: 8),
                        StatusBadge(status: payment.status),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection<T>(
    BuildContext context,
    String title,
    Stream<List<T>> stream,
    String Function(T) getId,
    String Function(T) getName,
    Future<void> Function(T) onRestore,
    Future<void> Function(T) onPermanentDelete,
    {Widget Function(T)? buildSubtitle}
  ) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final items = snapshot.data!.where((item) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final aq = ArabicTransliterator.transliterate(_searchQuery);
          return getName(item).toLowerCase().contains(q) || getName(item).contains(aq);
        }).toList();

        if (items.isEmpty) return const SizedBox.shrink();

        final allSelected = items.every((item) => _selectedIds.contains(getId(item)));

        return ExpansionTile(
          title: Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.addAll(items.map((i) => getId(i)));
                    } else {
                      _selectedIds.removeAll(items.map((i) => getId(i)));
                    }
                  });
                },
              ),
              Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          children: items.map((item) {
            final id = getId(item);
            return ListTile(
              leading: Checkbox(
                value: _selectedIds.contains(id),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(id);
                    } else {
                      _selectedIds.remove(id);
                    }
                  });
                },
              ),
              title: Text(getName(item)),
              subtitle: buildSubtitle != null ? buildSubtitle(item) : null,
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'restore') onRestore(item);
                  if (value == 'delete_forever') onPermanentDelete(item);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'restore', child: Text('Restore', style: TextStyle(color: Colors.green))),
                  const PopupMenuItem(value: 'delete_forever', child: Text('Delete Permanently', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
