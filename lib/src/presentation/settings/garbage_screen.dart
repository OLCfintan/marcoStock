import "../../application/auth/auth_service.dart";
import '../../application/purchases/purchase_service.dart';
import '../../application/sales/sales_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/database/providers.dart';
import '../../infrastructure/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class GarbageScreen extends ConsumerWidget {
  const GarbageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recycle Bin (Admin Only)')),
      body: ListView(
        children: [
          _buildSection<ClientEntity>(
            context,
            'Deleted Clients',
            (db.select(db.clients)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (client) => client.name,
            (client) async => await (db.update(db.clients)..where((t) => t.id.equals(client.id))).write(const ClientsCompanion(isActive: drift.Value(true))),
            (client) async => await (db.delete(db.clients)..where((t) => t.id.equals(client.id))).go(),
          ),
          _buildSection<SupplierEntity>(
            context,
            'Deleted Suppliers',
            (db.select(db.suppliers)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (supplier) => supplier.name,
            (supplier) async => await (db.update(db.suppliers)..where((t) => t.id.equals(supplier.id))).write(const SuppliersCompanion(isActive: drift.Value(true))),
            (supplier) async => await (db.delete(db.suppliers)..where((t) => t.id.equals(supplier.id))).go(),
          ),
          _buildSection<EmployeeEntity>(
            context,
            'Deleted Employees',
            (db.select(db.employees)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (employee) => employee.name,
            (employee) async => await (db.update(db.employees)..where((t) => t.id.equals(employee.id))).write(const EmployeesCompanion(isActive: drift.Value(true))),
            (employee) async => await (db.delete(db.employees)..where((t) => t.id.equals(employee.id))).go(),
          ),
          _buildSection<ProductEntity>(
            context,
            'Deleted Products',
            (db.select(db.products)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (product) => product.name,
            (product) async => await (db.update(db.products)..where((t) => t.id.equals(product.id))).write(const ProductsCompanion(isActive: drift.Value(true))),
            (product) async => await (db.delete(db.products)..where((t) => t.id.equals(product.id))).go(),
          ),
          _buildSection<InvoiceEntity>(
            context,
            'Deleted Invoices & Bons',
            (db.select(db.invoices)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (invoice) => '${invoice.documentType} - ${invoice.invoiceNumber}',
            (invoice) async {
              final userId = ref.read(currentUserProvider)?.id ?? '';
              await ref.read(salesServiceProvider).restoreInvoice(invoice.id, userId);
            },
            (invoice) async => await (db.delete(db.invoices)..where((t) => t.id.equals(invoice.id))).go(),
          ),
          _buildSection<PurchaseEntity>(
            context,
            'Deleted Purchases',
            (db.select(db.purchases)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (purchase) => 'Purchase - ${purchase.purchaseNumber}',
            (purchase) async {
              final userId = ref.read(currentUserProvider)?.id ?? '';
              await ref.read(purchaseServiceProvider).restorePurchase(purchase.id, userId);
            },
            (purchase) async => await (db.delete(db.purchases)..where((t) => t.id.equals(purchase.id))).go(),
          ),
          _buildSection<PaymentEntity>(
            context,
            'Deleted Payments & Checks',
            (db.select(db.payments)..where((t) => t.isActive.equals(false))..limit(50)).watch(),
            (payment) => '${payment.method} - ${payment.amount} Dhs',
            (payment) async => await (db.update(db.payments)..where((t) => t.id.equals(payment.id))).write(const PaymentsCompanion(isActive: drift.Value(true))),
            (payment) async => await (db.delete(db.payments)..where((t) => t.id.equals(payment.id))).go(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection<T>(
    BuildContext context,
    String title,
    Stream<List<T>> stream,
    String Function(T) getName,
    Future<void> Function(T) onRestore,
    Future<void> Function(T) onPermanentDelete,
  ) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final items = snapshot.data!;
        return ExpansionTile(
          title: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          children: items.map((item) => ListTile(
            title: Text(getName(item)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => onRestore(item)),
                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => onPermanentDelete(item)),
              ],
            ),
          )).toList(),
        );
      },
    );
  }
}
