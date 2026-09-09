import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/client_repository.dart';

final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final repo = ref.watch(clientRepositoryProvider);
  return repo.watchAllClients();
});
