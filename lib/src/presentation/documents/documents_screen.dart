import "pdf_preview_screen.dart";
import '../../application/purchases/purchase_service.dart';
import '../../application/sales/sales_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import '../../application/documents/pdf_generator.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/view_payments_dialog.dart';

class InvoiceWithClient {
  final InvoiceEntity invoice;
  final ClientEntity? client;
  InvoiceWithClient({required this.invoice, this.client});
}

class PurchaseWithSupplier {
  final PurchaseEntity purchase;
  final SupplierEntity? supplier;
  PurchaseWithSupplier({required this.purchase, this.supplier});
}

final purchasesStreamProvider = StreamProvider.autoDispose<List<PurchaseWithSupplier>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = (db.select(db.purchases)..where((t) => t.isActive.equals(true))).join([
    drift.leftOuterJoin(db.suppliers, db.suppliers.id.equalsExp(db.purchases.supplierId)),
  ]);
  query.orderBy([drift.OrderingTerm(expression: db.purchases.date, mode: drift.OrderingMode.desc)]);
  
  return query.watch().map((rows) {
    return rows.map((row) {
      return PurchaseWithSupplier(
        purchase: row.readTable(db.purchases),
        supplier: row.readTableOrNull(db.suppliers),
      );
    }).toList();
  });
});

final invoicesStreamProvider = StreamProvider.autoDispose<List<InvoiceWithClient>>((ref) {
  final db = ref.watch(databaseProvider);
  
  final query = (db.select(db.invoices)..where((t) => t.isActive.equals(true))).join([
    drift.leftOuterJoin(db.clients, db.clients.id.equalsExp(db.invoices.clientId)),
  ]);
  
  query.orderBy([drift.OrderingTerm(expression: db.invoices.date, mode: drift.OrderingMode.desc)]);

  return query.watch().map((rows) {
    return rows.map((row) {
      return InvoiceWithClient(
        invoice: row.readTable(db.invoices),
        client: row.readTableOrNull(db.clients),
      );
    }).toList();
  });
});

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStreamProvider);
    final purchasesAsync = ref.watch(purchasesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive & Docs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales & Returns'),
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: INVOICES
          invoicesAsync.when(
            data: (invoices) {
              if (invoices.isEmpty) return const Center(child: Text('No invoices found.', style: TextStyle(color: Colors.grey)));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final data = invoices[index];
                  final invoice = data.invoice;
                  final client = data.client;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 1,
                    child: InkWell(
                      onDoubleTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PdfPreviewScreen(
                            title: '${invoice.documentType} #${invoice.invoiceNumber}',
                            buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, AppLocalizations.of(context)!),
                          ),
                        ));
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: invoice.status == 'PAID' ? Colors.green.shade50 : (invoice.status == 'PARTIAL' ? Colors.orange.shade50 : Colors.red.shade50),
                          child: Icon(Icons.receipt, color: invoice.status == 'PAID' ? Colors.green : (invoice.status == 'PARTIAL' ? Colors.orange : Colors.red)),
                        ),
                        title: Text('${invoice.documentType} #${invoice.invoiceNumber} - ${client?.name ?? "Walk-in Client"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${DateFormat('MMM dd, yyyy').format(invoice.date)} | Total: ${invoice.total.toStringAsFixed(2)} Dhs | Status: ${invoice.status}'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'print') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PdfPreviewScreen(
                                  title: '${invoice.documentType} #${invoice.invoiceNumber}',
                                  buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, AppLocalizations.of(context)!),
                                ),
                              ));
                            } else if (value == 'record_payment') {
                              PaymentDialog.show(context, entityId: invoice.id, entityType: 'INVOICE', partnerId: client?.id, currentTotal: invoice.total, currentlyPaid: invoice.paidAmount);
                            } else if (value == 'view_payments') {
                              ViewPaymentsDialog.show(context, entityId: invoice.id, entityType: 'INVOICE');
                            } else if (value == 'convert') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.convertToInvoice),
                                    content: Text(AppLocalizations.of(context)!.convertBonToInvoice),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.confirm)),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(salesServiceProvider).convertBonToInvoice(invoice.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.convertedSuccessfully)));
                                  }
                                }
                            } else if (value == 'delete') {
                              final userId = ref.read(currentUserProvider)?.id ?? '';
                              await ref.read(salesServiceProvider).deleteInvoice(invoice.id, userId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'print', child: Text('Print Document')),
                            const PopupMenuItem(value: 'record_payment', child: Text('Record Payment')),
                            const PopupMenuItem(value: 'view_payments', child: Text('View Payments & Checks')),
                            if (invoice.documentType == 'BON')
                              PopupMenuItem(value: 'convert', child: Text(AppLocalizations.of(context)!.convertToInvoice)),
                            if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PdfPreviewScreen(
                            title: '${invoice.documentType} #${invoice.invoiceNumber}',
                            buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, AppLocalizations.of(context)!),
                          ),
                        ));
                      },
                    ),
                  ),
                );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
          
          // TAB 2: PURCHASES
          purchasesAsync.when(
            data: (purchases) {
              if (purchases.isEmpty) return const Center(child: Text('No purchases found.', style: TextStyle(color: Colors.grey)));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: purchases.length,
                itemBuilder: (context, index) {
                  final data = purchases[index];
                  final purchase = data.purchase;
                  final supplier = data.supplier;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: purchase.status == 'PAID' ? Colors.green.shade50 : (purchase.status == 'PARTIAL' ? Colors.orange.shade50 : Colors.red.shade50),
                        child: Icon(Icons.shopping_cart, color: purchase.status == 'PAID' ? Colors.green : (purchase.status == 'PARTIAL' ? Colors.orange : Colors.red)),
                      ),
                      title: Text('Purchase #${purchase.purchaseNumber} - ${supplier?.name ?? "Unknown Supplier"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${DateFormat('MMM dd, yyyy').format(purchase.date)} | Total: ${purchase.total.toStringAsFixed(2)} Dhs | Status: ${purchase.status}'),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'print') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${purchase.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, AppLocalizations.of(context)!))));
                          } else if (value == 'record_payment') {
                            PaymentDialog.show(context, entityId: purchase.id, entityType: 'PURCHASE', partnerId: supplier?.id, currentTotal: purchase.total, currentlyPaid: purchase.paidAmount);
                          } else if (value == 'view_payments') {
                            ViewPaymentsDialog.show(context, entityId: purchase.id, entityType: 'PURCHASE');
                          } else if (value == 'delete') {
                            final userId = ref.read(currentUserProvider)?.id ?? '';
                            await ref.read(purchaseServiceProvider).deletePurchase(purchase.id, userId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'print', child: Text('Print Document')),
                          const PopupMenuItem(value: 'record_payment', child: Text('Record Payment')),
                          const PopupMenuItem(value: 'view_payments', child: Text('View Payments & Checks')),
                          if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${purchase.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, AppLocalizations.of(context)!))));
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

}