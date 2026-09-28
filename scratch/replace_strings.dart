import 'dart:io';

void main() {
  final dir = Directory('lib/src/presentation');
  final files = dir.listSync(recursive: true).where((f) => f.path.endsWith('.dart')).toList();
  
  for (final file in files) {
    if (file is File) {
      final content = file.readAsStringSync();
      if (content.contains("Text('")) {
        print(file.path);
      }
    }
  }
}
