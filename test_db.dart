import 'lib/src/infrastructure/database/app_database.dart';

void main() {
  var db = AppDatabase();
  print(db.allTables.length);
}
