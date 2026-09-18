import '../../application/auth/auth_service.dart';
import '../../application/purchases/purchase_service.dart';
import '../../application/sales/sales_service.dart';
import '../../application/hr/hr_providers.dart';
import '../../application/suppliers/supplier_providers.dart';
import '../../application/clients/client_providers.dart';
import "../documents/pdf_preview_screen.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'print_dialog.dart';
import 'package:drift/drift.dart' as drift;

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import 'payment_dialog.dart';
import 'view_payments_dialog.dart';
import '../../application/documents/pdf_generator.dart';
import 'payment_ledger_dialog.dart';
import '../../application/hr/payroll_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final String balanceLabel = widget.type == HumanType.employee ? 'Salary Owed' : 'Balance';

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
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.imagePath != null && widget.imagePath!.isNotEmpty
                      ? FileImage(File(widget.imagePath!))
                      : null,
                  child: widget.imagePath == null || widget.imagePath!.isEmpty 
                      ? Icon(
                          widget.type == HumanType.client ? Icons.person 
                        : widget.type == HumanType.supplier ? Icons.business 
                        : Icons.badge, 
                          size: 40
                        ) 
                      : null,
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
                          decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Text(widget.clientTier!, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (widget.phone != null && widget.phone!.isNotEmpty)
                        Row(children: [const Icon(Icons.phone, size: 16), const SizedBox(width: 8), Text(widget.phone!)]),
                      if (widget.email != null && widget.email!.isNotEmpty)
                        Row(children: [const Icon(Icons.email, size: 16), const SizedBox(width: 8), Text(widget.email!)]),
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
              ],
            ),
          ),
          
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Transaction History'),
              Tab(text: 'Checks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Transactions (Invoices/Purchases)
                _buildTransactionsTab(db),
                
                // Tab 2: Checks
                _buildChecksTab(db),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTransactionsTab(AppDatabase db) {
    if (widget.type == HumanType.client) {
      return StreamBuilder<List<InvoiceEntity>>(
        stream: (db.select(db.invoices)..where((t) => t.clientId.equals(widget.id) & t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
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
                    PaymentDialog.show(context, entityId: inv.id, entityType: 'INVOICE', partnerId: widget.id, currentTotal: inv.total, currentlyPaid: inv.paidAmount);
                  },
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text('Invoice #${inv.invoiceNumber}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${inv.date.toString().split(' ')[0]}'),
                      Text('${inv.total.toStringAsFixed(2)} Dhs - ${inv.status}', style: TextStyle(fontWeight: FontWeight.bold, color: inv.status == 'PAID' ? Colors.green : (inv.status == 'PARTIAL' ? Colors.orange : Colors.red))),
                    ]
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'print') {
                        final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                        if (options != null && context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "Invoice ${inv.invoiceNumber}", buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(inv.id, options))));
                        }
                      } else if (value == 'record_payment') {
                        PaymentDialog.show(context, entityId: inv.id, entityType: 'INVOICE', partnerId: widget.id, currentTotal: inv.total, currentlyPaid: inv.paidAmount);
                      } else if (value == 'view_payments') {
                        ViewPaymentsDialog.show(context, entityId: inv.id, entityType: 'INVOICE');
                      } else if (value == 'delete') {
                        final userId = ref.read(currentUserProvider)?.id ?? '';
                        await ref.read(salesServiceProvider).deleteInvoice(inv.id, userId);
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
    } else if (widget.type == HumanType.supplier) {
      return StreamBuilder<List<PurchaseEntity>>(
        stream: (db.select(db.purchases)..where((t) => t.supplierId.equals(widget.id) & t.isActive.equals(true))..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
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
    }
    return const Center(child: Text('No transactions'));
  }

  Widget _buildChecksTab(AppDatabase db) {
    return StreamBuilder<List<PaymentEntity>>(
      stream: _watchPayments(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final payments = snapshot.data!.where((p) => p.method == 'CHECK').toList();
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
            child: Icon(payment.method == 'CHECK' ? Icons.receipt : Icons.attach_money, color: Colors.white),
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
                       final db = ref.read(databaseProvider);
                       await (db.update(db.payments)..where((t) => t.id.equals(payment.id))).write(const PaymentsCompanion(isActive: drift.Value(false)));
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
