import '../../utils/arabic_transliterator.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:decimal/decimal.dart';

import '../database/app_database.dart';
import '../database/providers.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(databaseProvider));
});

class Client {
  final String id;
  final String name;
  final String? contactDetails;
  final String? address;
  final Decimal balance;
  final bool isActive;
  final String? phone;
  final String? email;
  final String? imagePath;
  final String tier;
  final String type;

  Client({
    required this.id,
    required this.name,
    this.contactDetails,
    this.address,
    required this.balance,
    required this.isActive,
    this.phone,
    this.email,
    this.imagePath,
    this.tier = 'Tier 1',
    this.type = 'NORMAL',
  });
}

class ClientRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ClientRepository(this._db);

  Stream<List<Client>> watchAllClients() {
    return (_db.select(_db.clients)..where((t) => t.isActive.equals(true))).watch().map((entities) {
      return entities.map((e) => Client(
        id: e.id,
        name: e.name,
        contactDetails: e.contactDetails,
        address: e.address,
        balance: e.balance,
        isActive: e.isActive,
        phone: e.phone,
        email: e.email,
        imagePath: e.imagePath,
        tier: e.tier,
        type: e.type,
      )).toList();
    });
  }

  Future<void> createClient(
    String name, {
    String? contact,
    String? address,
    String? phone,
    String? email,
    String? imagePath,
    String tier = 'Tier 1',
    String type = 'NORMAL',
  }) async {
    await _db.into(_db.clients).insert(ClientsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      contactDetails: contact != null ? drift.Value(contact) : const drift.Value.absent(),
      address: address != null ? drift.Value(address) : const drift.Value.absent(),
      phone: phone != null ? drift.Value(phone) : const drift.Value.absent(),
      email: email != null ? drift.Value(email) : const drift.Value.absent(),
      imagePath: imagePath != null ? drift.Value(imagePath) : const drift.Value.absent(),
      tier: drift.Value(tier),
      type: drift.Value(type),
      balance: const drift.Value.absent(), // defaults to 0
    ));
  }
  Future<void> updateClient(
    String id,
    String name, {
    String? contact,
    String? address,
    String? phone,
    String? email,
    String? imagePath,
    String tier = 'Tier 1',
    String type = 'NORMAL',
  }) async {
    await (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(
      ClientsCompanion(
        name: drift.Value(name),
        contactDetails: drift.Value(contact),
        address: drift.Value(address),
        phone: drift.Value(phone),
        email: drift.Value(email),
        imagePath: drift.Value(imagePath),
        tier: drift.Value(tier),
        type: drift.Value(type),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteClient(String id) async {
    await (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(const ClientsCompanion(isActive: drift.Value(false)));
  }
  Future<void> restoreClient(String id) async {
    await (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(const ClientsCompanion(isActive: drift.Value(true)));
  }
  Future<void> permanentDeleteClient(String id) async {
    await (_db.delete(_db.clients)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Client>> searchClients(String query) async {
    final lowerQuery = '%${query.toLowerCase()}%';
    final aQuery = '%${ArabicTransliterator.transliterate(query)}%';
    final entities = await (_db.select(_db.clients)
          ..where((t) => (t.name.lower().like(lowerQuery) | t.name.like(aQuery)) & t.isActive.equals(true)))
        .get();
    return entities.map((e) => Client(
      id: e.id,
      name: e.name,
      contactDetails: e.contactDetails,
      address: e.address,
      balance: e.balance,
      isActive: e.isActive,
      phone: e.phone,
      email: e.email,
      imagePath: e.imagePath,
      tier: e.tier,
      type: e.type,
    )).toList();
  }
}
