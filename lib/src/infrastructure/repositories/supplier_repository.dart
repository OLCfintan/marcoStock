import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../database/providers.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository(ref.watch(databaseProvider));
});

class Supplier {
  final String id;
  final String name;
  final String type; // 'NORMAL' or 'SPECIAL'
  final String? contactDetails;
  final Decimal balance; // Money we owe them
  final bool isActive;
  final String? phone;
  final String? email;
  final String? imagePath;

  Supplier({
    required this.id,
    required this.name,
    required this.type,
    this.contactDetails,
    required this.balance,
    required this.isActive,
    this.phone,
    this.email,
    this.imagePath,
  });
}

class SupplierRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  SupplierRepository(this._db);

  Stream<List<Supplier>> watchAllSuppliers() {
    return (_db.select(_db.suppliers)..where((t) => t.isActive.equals(true))).watch().map((entities) {
      return entities.map((e) => Supplier(
        id: e.id,
        name: e.name,
        type: e.type,
        contactDetails: e.contactDetails,
        balance: e.balance,
        isActive: e.isActive,
        phone: e.phone,
        email: e.email,
        imagePath: e.imagePath,
      )).toList();
    });
  }

  Future<void> createSupplier(
    String name,
    String type, {
    String? contact,
    String? phone,
    String? email,
    String? imagePath,
  }) async {
    await _db.into(_db.suppliers).insert(SuppliersCompanion.insert(
      id: _uuid.v4(),
      name: name,
      type: drift.Value(type),
      contactDetails: contact != null ? drift.Value(contact) : const drift.Value.absent(),
      phone: phone != null ? drift.Value(phone) : const drift.Value.absent(),
      email: email != null ? drift.Value(email) : const drift.Value.absent(),
      imagePath: imagePath != null ? drift.Value(imagePath) : const drift.Value.absent(),
      balance: const drift.Value.absent(), // defaults to 0
    ));
  }
  Future<void> updateSupplier(
    String id,
    String name, {
    String? contact,
    String? phone,
    String? email,
    String? imagePath,
  }) async {
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        name: drift.Value(name),
        contactDetails: drift.Value(contact),
        phone: drift.Value(phone),
        email: drift.Value(email),
        imagePath: drift.Value(imagePath),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSupplier(String id) async {
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(const SuppliersCompanion(isActive: drift.Value(false)));
  }
  Future<void> restoreSupplier(String id) async {
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(const SuppliersCompanion(isActive: drift.Value(true)));
  }
  Future<void> permanentDeleteSupplier(String id) async {
    await (_db.delete(_db.suppliers)..where((t) => t.id.equals(id))).go();
  }
}
