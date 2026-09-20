import '../../utils/arabic_transliterator.dart';
import "pdf_preview_screen.dart";
import '../../application/purchases/purchase_service.dart';
import "package:marko_group/src/presentation/widgets/status_badge.dart";
import '../../application/sales/sales_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/print_dialog.dart';
import '../../application/auth/auth_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import '../widgets/logo_loader.dart';

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
  final Set<String> _selectedIds = {};
  String _searchQuery = '';

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
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected Documents',
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final userId = ref.read(currentUserProvider)?.id ?? '';
                final salesSvc = ref.read(salesServiceProvider);
                final purchSvc = ref.read(purchaseServiceProvider);

                for (final id in _selectedIds.toList()) {
                  final isInvoice = await (db.select(db.invoices)..where((t) => t.id.equals(id))).getSingleOrNull();
                  if (isInvoice != null) {
                    await salesSvc.deleteInvoice(id, userId);
                    continue;
                  }
                  final isPurchase = await (db.select(db.purchases)..where((t) => t.id.equals(id))).getSingleOrNull();
                  if (isPurchase != null) {
                    await purchSvc.deletePurchase(id, userId);
                    continue;
                  }
                }
                setState(() => _selectedIds.clear());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected documents deleted.')));
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales & Returns'),
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Documents',
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
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: INVOICES
                invoicesAsync.when(
                  data: (allInvoices) {
                    final invoices = allInvoices.where((i) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      final aq = ArabicTransliterator.transliterate(_searchQuery);
                      return i.invoice.invoiceNumber.toLowerCase().contains(q) ||
                             (i.client?.name.toLowerCase().contains(q) ?? false) ||
                             (i.client?.name.contains(aq) ?? false);
                    }).toList();

                    if (invoices.isEmpty) return const Center(child: Text('No invoices found.', style: TextStyle(color: Colors.grey)));
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: invoices.isNotEmpty && invoices.every((i) => _selectedIds.contains(i.invoice.id)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.addAll(invoices.map((i) => i.invoice.id));
                                    } else {
                                      _selectedIds.removeAll(invoices.map((i) => i.invoice.id));
                                    }
                                  });
                                },
                              ),
                              const Text('Select All'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: invoices.length,
                            itemBuilder: (context, index) {
                              final data = invoices[index];
                              final invoice = data.invoice;
                              final client = data.client;
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                
                                child: InkWell(
                                  onDoubleTap: () {
                                    
                                    // Replaced navigation
                                    () async {
                                      final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                                      if (options != null && context.mounted) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => PdfPreviewScreen(
                                            title: '${invoice.documentType} #${invoice.invoiceNumber}',
                                            buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options),
                                          ),
                                        ));
                                      }
                                    }();
                                
                                  },
                                  child: ListTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: _selectedIds.contains(invoice.id),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedIds.add(invoice.id);
                                              } else {
                                                _selectedIds.remove(invoice.id);
                                              }
                                            });
                                          },
                                        ),
                                        CircleAvatar(
                                          backgroundColor: const Color(0xfff1f5f9),
                                          child: Icon(Icons.receipt, color: const Color(0xff64748b)),
                                        ),
                                      ],
                                    ),
                                    title: Text('${invoice.documentType} #${invoice.invoiceNumber} - ${client?.name ?? "Walk-in Client"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Text('${DateFormat('MMM dd, yyyy').format(invoice.date)} | Total: ${invoice.total.toStringAsFixed(2)} Dhs'),
                                          const SizedBox(width: 8),
                                          StatusBadge(status: invoice.status),
                                        ],
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) async {
                                        if (value == 'print') {
                                          final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                                          if (options != null && context.mounted) {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => PdfPreviewScreen(
                                                title: '${invoice.documentType} #${invoice.invoiceNumber}',
                                                buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options),
                                              ),
                                            ));
                                          }
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
                                        PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context)!.printDocument)),
                                        PopupMenuItem(value: 'record_payment', child: Text(AppLocalizations.of(context)!.recordPayment)),
                                        PopupMenuItem(value: 'view_payments', child: Text(AppLocalizations.of(context)!.viewPaymentsChecks)),
                                        if (invoice.documentType == 'BON')
                                          PopupMenuItem(value: 'convert', child: Text(AppLocalizations.of(context)!.convertToInvoice)),
                                        if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                                          PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  onTap: () {
                                    
                                    // Replaced navigation
                                    () async {
                                      final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                                      if (options != null && context.mounted) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => PdfPreviewScreen(
                                            title: '${invoice.documentType} #${invoice.invoiceNumber}',
                                            buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options),
                                          ),
                                        ));
                                      }
                                    }();
                                
                                  },
                                ),
                              ),
                            );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: const LogoLoader()),
                  error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                ),
                
                // TAB 2: PURCHASES
                purchasesAsync.when(
                  data: (allPurchases) {
                    final purchases = allPurchases.where((p) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      final aq = ArabicTransliterator.transliterate(_searchQuery);
                      return p.purchase.purchaseNumber.toLowerCase().contains(q) ||
                             (p.supplier?.name.toLowerCase().contains(q) ?? false) ||
                             (p.supplier?.name.contains(aq) ?? false);
                    }).toList();

                    if (purchases.isEmpty) return const Center(child: Text('No purchases found.', style: TextStyle(color: Colors.grey)));
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: purchases.isNotEmpty && purchases.every((p) => _selectedIds.contains(p.purchase.id)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.addAll(purchases.map((p) => p.purchase.id));
                                    } else {
                                      _selectedIds.removeAll(purchases.map((p) => p.purchase.id));
                                    }
                                  });
                                },
                              ),
                              const Text('Select All'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: purchases.length,
                            itemBuilder: (context, index) {
                              final data = purchases[index];
                              final purchase = data.purchase;
                              final supplier = data.supplier;
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _selectedIds.contains(purchase.id),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIds.add(purchase.id);
                                            } else {
                                              _selectedIds.remove(purchase.id);
                                            }
                                          });
                                        },
                                      ),
                                      CircleAvatar(
                                        backgroundColor: const Color(0xfff1f5f9),
                                        child: Icon(Icons.shopping_cart, color: const Color(0xff64748b)),
                                      ),
                                    ],
                                  ),
                                  title: Text('Purchase #${purchase.purchaseNumber} - ${supplier?.name ?? "Unknown"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Text('${DateFormat('MMM dd, yyyy').format(purchase.date)} | Total: ${purchase.total.toStringAsFixed(2)} Dhs'),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: purchase.status),
                                      ],
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'print') {
                                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                                        if (options != null && context.mounted) {
                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => PdfPreviewScreen(
                                              title: "Purchase ${purchase.purchaseNumber}",
                                              buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, options),
                                            )
                                          ));
                                        }
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
                                      PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context)!.printDocument)),
                                      PopupMenuItem(value: 'record_payment', child: Text(AppLocalizations.of(context)!.recordPayment)),
                                      PopupMenuItem(value: 'view_payments', child: Text(AppLocalizations.of(context)!.viewPaymentsChecks)),
                                      if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                                        PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.deleteStr, style: const TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                  onTap: () {
                                    
                                    // Replaced navigation
                                    () async {
                                      final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                                      if (options != null && context.mounted) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => PdfPreviewScreen(
                                            title: "Purchase ${purchase.purchaseNumber}",
                                            buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(purchase.id, options),
                                          ),
                                        ));
                                      }
                                    }();
                                
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: const LogoLoader()),
                  error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}