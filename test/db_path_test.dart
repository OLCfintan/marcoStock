import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('print db path', () async {
    final dir = await getApplicationDocumentsDirectory();
    print("PATH: ${dir.path}");
  });
}
