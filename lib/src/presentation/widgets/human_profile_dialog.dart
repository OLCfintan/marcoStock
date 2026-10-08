import "../../infrastructure/repositories/client_repository.dart";
import "../../infrastructure/repositories/supplier_repository.dart";
import '../../application/payments/payment_service.dart';
import '../../application/auth/auth_service.dart';
import '../../application/purchases/purchase_service.dart';
import '../../application/sales/sales_service.dart';
import '../../application/hr/hr_providers.dart';
import '../../application/suppliers/supplier_providers.dart';
import '../../application/clients/client_providers.dart';
import "../documents/pdf_preview_screen.dart";
import 'package:marko_group/src/localization/arb/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../utils/arabic_transliterator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'print_dialog.dart';
import 'package:drift/drift.dart' as drift;
import '../widgets/logo_loader.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import 'payment_dialog.dart';
import 'view_payments_dialog.dart';
import '../../application/documents/pdf_generator.dart';
import 'payment_ledger_dialog.dart';
import '../../application/hr/payroll_service.dart';
import '../clients/client_details_screen.dart';

enum HumanType {
  client,
  supplier,
  employee,
}

class HumanProfileDialog extends ConsumerStatefulWidget {
  final HumanType type;
  final String id;
  final String name;
  final String roleOrType;
  final String? clientTier;
  final String? phone;
  final String? email;
  final String? imagePath;
  final Decimal balance;

  // For Employee
  final Decimal? baseSalary;

  const HumanProfileDialog({
    super.key,
    required this.type,
    required this.id,
    required this.name,
    required this.roleOrType,
    this.clientTier,
    this.phone,
    this.email,
    this.imagePath,
    required this.balance,
    this.baseSalary,
  });

  @override
  ConsumerState<HumanProfileDialog> createState() => _HumanProfileDialogState();
}

class _HumanProfileDialogState extends ConsumerState<HumanProfileDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    int tabsCount = widget.type == HumanType.client ? 3 : 2;
    _tabController = TabController(length: tabsCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPaymentLedgerDialog() {
    showDialog(
      context: context,
      builder: (_) => PaymentLedgerDialog(
        clientId: widget.type == HumanType.client ? widget.id : null,
        supplierId: widget.type == HumanType.supplier ? widget.id : null,
        employeeId: widget.type == HumanType.employee ? widget.id : null,
        initialBalance: widget.balance,
        entityName: widget.name,
      ),
    );
  }

  void _showPayrollActionDialog() {
    final amountController = TextEditingController();
    String selectedAction = 'SALARY'; 
    final baseSalary = widget.baseSalary ?? Decimal.zero;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${AppLocalizations.of(context)!.payrollAction}${widget.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedAction,
                    decoration: const InputDecoration(labelText: 'Action Type'),
                    items: [
                      DropdownMenuItem(value: 'SALARY', child: Text(AppLocalizations.of(context)!.creditMonthlySalary)),
                      DropdownMenuItem(value: 'BONUS', child: Text(AppLocalizations.of(context)!.creditBonus)),
                      DropdownMenuItem(value: 'ADVANCE', child: Text(AppLocalizations.of(context)!.issueAdvance)),
                      DropdownMenuItem(value: 'PAYMENT', child: Text(AppLocalizations.of(context)!.issueFinalPayment)),
                    ],
                    onChanged: (v) => setState(() => selectedAction = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: selectedAction == 'SALARY' ? baseSalary.toString() : '0.00'
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final str = amountController.text.trim();
                    final amount = str.isEmpty && selectedAction == 'SALARY' 
                        ? baseSalary 
                        : Decimal.tryParse(str) ?? Decimal.zero;
                        
                    if (amount <= Decimal.zero) return;

                    if (selectedAction == 'PAYMENT') {
                      Navigator.pop(context);
                      _showPaymentLedgerDialog();
                      return;
                    }
                    
                    await ref.read(payrollServiceProvider).executePayrollTransaction(
                      employeeId: widget.id,
                      type: selectedAction,
                      amount: amount,
                      currentUserId: 'ADMIN_01', 
                    );
                    
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    
    Decimal currentBalance = widget.balance;
    if (widget.type == HumanType.client) {
      final clientsAsync = ref.watch(clientsStreamProvider);
      final c = clientsAsync.value?.where((e) => e.id == widget.id).firstOrNull;
      if (c != null) currentBalance = c.balance;
    } else if (widget.type == HumanType.supplier) {
      final suppliersAsync = ref.watch(suppliersStreamProvider);
      final s = suppliersAsync.value?.where((e) => e.id == widget.id).firstOrNull;
      if (s != null) currentBalance = s.balance;
    } else if (widget.type == HumanType.employee) {
      final employeesAsync = ref.watch(employeesStreamProvider);
      final e = employeesAsync.value?.where((e) => e.id == widget.id).firstOrNull;
      if (e != null) currentBalance = e.remainingSalary;
    }
    
    final balanceColor = currentBalance > Decimal.zero ? Colors.red : Colors.green;
    final String balanceLabel = widget.type == HumanType.employee ? 'Salary Owed' : 'Total Debt';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name}${AppLocalizations.of(context)!.profileOf}'),
        actions: [
          if (widget.type == HumanType.employee)
            IconButton(
              icon: const Icon(Icons.money),
              tooltip: 'Payroll Actions',
              onPressed: _showPayrollActionDialog,
            )
          else
            IconButton(
              icon: const Icon(Icons.payment),
              tooltip: widget.type == HumanType.client ? 'Receive Payment' : 'Make Payment',
              onPressed: _showPaymentLedgerDialog,
            )
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                ClipOval(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: Container(
                    width: 80, height: 80,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: widget.imagePath != null && widget.imagePath!.isNotEmpty
                        ? Image.file(File(widget.imagePath!), fit: BoxFit.cover, filterQuality: FilterQuality.high)
                        : Icon(
                            widget.type == HumanType.client ? Icons.person 
                          : widget.type == HumanType.supplier ? Icons.business 
                          : Icons.badge, 
                            size: 40
                          ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(widget.roleOrType, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                      if (widget.clientTier != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration( borderRadius: BorderRadius.circular(12)),
                          child: Text(widget.clientTier!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (widget.phone != null && widget.phone!.isNotEmpty)
                        Row(children: [const Icon(Icons.phone, size: 16), const SizedBox(width: 8), Text(widget.phone!)]),
                      if (widget.email != null && widget.email!.isNotEmpty)
                        Row(children: [const Icon(Icons.email, size: 16), const SizedBox(width: 8), Text(widget.email!)]),
                      if (widget.type == HumanType.client)
                        Consumer(builder: (context, ref, child) {
                          final c = ref.watch(clientsStreamProvider).value?.where((e) => e.id == widget.id).firstOrNull;
                          if (c == null) return const SizedBox.shrink();
                          if (c.type == 'SPECIAL') return const SizedBox.shrink();
                          return Row(
                            children: [
                              const Text('Show in Dashboard', style: TextStyle(fontSize: 12)),
                              Switch(
                                value: c.showInDashboard,
                                onChanged: (val) async {
                                  await ref.read(clientRepositoryProvider).updateClientDashboardStatus(c.id, val);
                                },
                              ),
                            ],
                          );
                        }),
                      if (widget.type == HumanType.supplier)
                        Consumer(builder: (context, ref, child) {
                          final s = ref.watch(suppliersStreamProvider).value?.where((e) => e.id == widget.id).firstOrNull;
                          if (s == null) return const SizedBox.shrink();
                          return Row(
                            children: [
                              const Text('Show in Dashboard', style: TextStyle(fontSize: 12)),
                              Switch(
                                value: s.showInDashboard,
                                onChanged: (val) async {
                                  await ref.read(supplierRepositoryProvider).updateSupplierDashboardStatus(s.id, val);
                                },
                              ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(balanceLabel, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${currentBalance.toStringAsFixed(2)} Dhs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: balanceColor)),
                  ],
                ),
                if (widget.type == HumanType.client) ...[
                  const SizedBox(width: 24),
                  Consumer(builder: (context, ref, child) {
                    final db = ref.watch(databaseProvider);
                    final query = db.select(db.invoices)
                      ..where((t) => t.clientId.equals(widget.id) & t.documentType.equals('BON') & t.isActive.equals(true));
                    return StreamBuilder<List<InvoiceEntity>>(
                      stream: query.watch(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final docs = snapshot.data!;
                        Decimal totalRev = Decimal.zero;
                        for (final inv in docs) {
                          totalRev += inv.total;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Revenue', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('${totalRev.toStringAsFixed(2)} Dhs', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        );
                      },
                    );
                  }),
                ],
                const SizedBox(width: 16),
                Builder(
                  builder: (ctx) {
                    String qrData = '';
                    if (widget.type == HumanType.client) {
                      qrData = 'BEGIN:VCARD\nVERSION:3.0\nFN:${widget.name}\nTEL:${widget.phone ?? ''}\nNOTE:ICE: \nEND:VCARD';
                    } else if (widget.type == HumanType.supplier) {
                      qrData = 'TYPE: SUPPLIER\nNAME: ${widget.name}\nPHONE: ${widget.phone ?? ''}\nEMAIL: ${widget.email ?? ''}';
                    } else {
                      qrData = 'TYPE: EMPLOYEE\nNAME: ${widget.name}\nPHONE: ${widget.phone ?? ''}\nROLE: ${widget.roleOrType}';
                    }
                    return InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: qrData));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Profile info copied to clipboard')));
                        }
                      },
                      child: Tooltip(
                        message: 'Scan or click to copy',
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(4),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 80.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: widget.type == HumanType.employee ? 'Payroll Records' : 'Transaction History'),
              const Tab(text: 'Payments & Checks'),
              if (widget.type == HumanType.client)
                const Tab(text: 'Remaining Products'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Transactions (Invoices/Purchases)
                _buildTransactionsTab(db),
                
                // Tab 2: Payments
                _buildPaymentsTab(db),

                // Tab 3: Remaining Products
                if (widget.type == HumanType.client)
                  RemainingProductsSection(clientId: widget.id),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTransactionsTab(AppDatabase db) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: _buildTransactionsList(db),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(AppDatabase db) {
    if (widget.type == HumanType.client) {
      return StreamBuilder<List<InvoiceEntity>>(
        stream: (db.select(db.invoices)..where((t) => t.clientId.equals(widget.id) & t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: const LogoLoader());
          var items = snapshot.data!;
          if (_searchQuery.isNotEmpty) {
            final q = ArabicTransliterator.transliterate(_searchQuery.toLowerCase());
            items = items.where((inv) {
              final num = ArabicTransliterator.transliterate(inv.invoiceNumber.toLowerCase());
              final cName = ArabicTransliterator.transliterate(inv.clientNameOverride?.toLowerCase() ?? '');
              final dType = ArabicTransliterator.transliterate(inv.documentType.toLowerCase());
              final dDate = '${inv.date.day.toString().padLeft(2,'0')}/${inv.date.month.toString().padLeft(2,'0')}/${inv.date.year}';
              return num.contains(q) || cName.contains(q) || dType.contains(q) || dDate.contains(q);
            }).toList();
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final inv = items[i];
              return GestureDetector(
                onDoubleTap: () async {
                  final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                  if (options != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Invoice ${inv.invoiceNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, options))));
                  }
                },
                child: ListTile(
                  onTap: () {
                    if (inv.documentType == 'BON') {
                      PaymentDialog.show(context, entityId: inv.id, entityType: 'INVOICE', partnerId: widget.id, currentTotal: inv.total, currentlyPaid: inv.paidAmount);
                    }
                  },
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text('${inv.documentType == 'FACTURE_DUMMY' ? 'FACTURE' : inv.documentType} #${inv.invoiceNumber}' + (inv.clientNameOverride != null && inv.clientNameOverride!.isNotEmpty ? ' - ${inv.clientNameOverride}' : '')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${inv.date.toString().split(' ')[0]}'),
                      if (inv.documentType == 'BON')
                        Text('${inv.total.toStringAsFixed(2)} Dhs - ${inv.status}', style: TextStyle(fontWeight: FontWeight.bold, color: inv.status == 'PAID' ? Colors.green : (inv.status == 'PARTIAL' ? Colors.orange : Colors.red)))
                      else
                        Text('${inv.total.toStringAsFixed(2)} Dhs', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ]
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'print') {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Invoice ${inv.invoiceNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, options))));
                        }
                      } else if (value == 'record_payment' && inv.documentType == 'BON') {
                        PaymentDialog.show(context, entityId: inv.id, entityType: 'INVOICE', partnerId: widget.id, currentTotal: inv.total, currentlyPaid: inv.paidAmount);
                      } else if (value == 'view_payments' && inv.documentType == 'BON') {
                        ViewPaymentsDialog.show(context, entityId: inv.id, entityType: 'INVOICE');
                      } else if (value == 'delete') {
                        final userId = ref.read(currentUserProvider)?.id ?? '';
                        await ref.read(salesServiceProvider).deleteInvoice(inv.id, userId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context)?.printDocument ?? 'Print')),
                      if (inv.documentType == 'BON')
                        PopupMenuItem(value: 'record_payment', child: Text(AppLocalizations.of(context)?.recordPayment ?? 'Record Payment')),
                      if (inv.documentType == 'BON')
                        PopupMenuItem(value: 'view_payments', child: Text(AppLocalizations.of(context)?.viewPaymentsChecks ?? 'View Payments')),
                      if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                        PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else if (widget.type == HumanType.supplier) {
      return StreamBuilder<List<PurchaseEntity>>(
        stream: (db.select(db.purchases)..where((t) => t.supplierId.equals(widget.id) & t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: const LogoLoader());
          var items = snapshot.data!;
          if (_searchQuery.isNotEmpty) {
            final q = ArabicTransliterator.transliterate(_searchQuery.toLowerCase());
            items = items.where((pur) {
              final num = ArabicTransliterator.transliterate(pur.purchaseNumber.toLowerCase());
              final dDate = '${pur.date.day.toString().padLeft(2,'0')}/${pur.date.month.toString().padLeft(2,'0')}/${pur.date.year}';
              return num.contains(q) || dDate.contains(q);
            }).toList();
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final pur = items[i];
              return GestureDetector(
                onDoubleTap: () async {
                  final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                  if (options != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${pur.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(pur.id, options))));
                  }
                },
                child: ListTile(
                  onTap: () {
                    PaymentDialog.show(context, entityId: pur.id, entityType: 'PURCHASE', partnerId: widget.id, currentTotal: pur.total, currentlyPaid: pur.paidAmount);
                  },
                  leading: const Icon(Icons.shopping_cart, color: Colors.purple),
                  title: Text('Purchase #${pur.purchaseNumber}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${pur.date.toString().split(' ')[0]}'),
                      Text('${pur.total.toStringAsFixed(2)} Dhs - ${pur.status}', style: TextStyle(fontWeight: FontWeight.bold, color: pur.status == 'PAID' ? Colors.green : (pur.status == 'PARTIAL' ? Colors.orange : Colors.red))),
                    ]
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'print') {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Purchase ${pur.purchaseNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generatePurchasePdf(pur.id, options))));
                        }
                      } else if (value == 'record_payment') {
                        PaymentDialog.show(context, entityId: pur.id, entityType: 'PURCHASE', partnerId: widget.id, currentTotal: pur.total, currentlyPaid: pur.paidAmount);
                      } else if (value == 'view_payments') {
                        ViewPaymentsDialog.show(context, entityId: pur.id, entityType: 'PURCHASE');
                      } else if (value == 'delete') {
                        final userId = ref.read(currentUserProvider)?.id ?? '';
                        await ref.read(purchaseServiceProvider).deletePurchase(pur.id, userId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'print', child: Text(AppLocalizations.of(context)?.printDocument ?? 'Print')),
                      PopupMenuItem(value: 'record_payment', child: Text(AppLocalizations.of(context)?.recordPayment ?? 'Record Payment')),
                      PopupMenuItem(value: 'view_payments', child: Text(AppLocalizations.of(context)?.viewPaymentsChecks ?? 'View Payments')),
                      if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                        PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else if (widget.type == HumanType.employee) {
      return StreamBuilder<List<PayrollRecordEntity>>(
        stream: (db.select(db.payrollRecords)..where((t) => t.employeeId.equals(widget.id))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: LogoLoader());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('No payroll records'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final rec = items[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: ['SALARY', 'BONUS'].contains(rec.type) ? Colors.green : Colors.red,
                  child: Icon(['SALARY', 'BONUS'].contains(rec.type) ? Icons.add : Icons.remove, color: Colors.white),
                ),
                title: Text('${rec.type}: ${rec.amount.toStringAsFixed(2)} Dhs'),
                subtitle: Text('Date: ${rec.date.toString().split('.')[0]}${rec.notes != null ? ' - ${rec.notes}' : ''}'),
              );
            },
          );
        },
      );
    }
    return const Center(child: Text('No transactions'));
  }

  Widget _buildPaymentsTab(AppDatabase db) {
    return StreamBuilder<List<PaymentEntity>>(
      stream: _watchPayments(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: const LogoLoader());
        final payments = snapshot.data!;
        return _buildLedgerList(payments);
      },
    );
  }

  Stream<List<PaymentEntity>> _watchPayments(AppDatabase db) {
    return (db.select(db.payments)
          ..where((t) => t.isActive.equals(true))
          ..where((t) {
            if (widget.type == HumanType.client) return t.clientId.equals(widget.id);
            if (widget.type == HumanType.supplier) return t.supplierId.equals(widget.id);
            return t.employeeId.equals(widget.id);
          })
          ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])
        )
        .watch();
  }

  Widget _buildLedgerList(List<PaymentEntity> payments) {
    if (payments.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noTransactionsFound));
    }
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        
        return ListTile(
              onTap: payment.method == 'CHECK' && payment.checkImagePath != null && payment.checkImagePath!.isNotEmpty
                  ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          content: Image.file(File(payment.checkImagePath!)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                          ],
                        ),
                      );
                    }
                  : null,
              leading: CircleAvatar(
            backgroundColor: payment.method == 'CHECK' ? Colors.orange : Colors.blue,
            child: Icon(payment.method == 'CHECK' ? Icons.receipt : Icons.attach_money, color: const Color(0xff64748b)),
          ),
          title: Text('Amount: ${payment.amount.toStringAsFixed(2)}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Method: ${payment.method} - Date: ${payment.date.toString().split(' ')[0]}'),
              if (payment.method == 'CHECK' && payment.checkImagePath != null)
                Text(AppLocalizations.of(context)!.checkImageAvailable, style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(payment.status, style: TextStyle(
                color: payment.status == 'CLEARED' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold
              )),
              if (ref.watch(currentUserProvider)?.role == 'ADMIN')
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'delete') {
                       await ref.read(paymentServiceProvider).deletePayment(payment.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)?.deleteStr ?? 'Delete', style: const TextStyle(color: Colors.red))),
                  ],
                ),
            ]
          ),
        );
      },
    );
  }
}
