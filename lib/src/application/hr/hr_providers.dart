import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/employee_repository.dart';

final employeesStreamProvider = StreamProvider<List<Employee>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.watchAllEmployees();
});
