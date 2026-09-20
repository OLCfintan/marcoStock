import 'dart:io';

void main() {
  final dir = Directory('lib/src/presentation');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.endsWith('logo_loader.dart')) continue;

    String content = file.readAsStringSync();
    if (!content.contains('CircularProgressIndicator')) continue;

    // Calculate relative path to lib/src/presentation/widgets/logo_loader.dart
    final parts = file.path.split('/');
    // lib/src/presentation/ ...
    final depth = parts.length - 4; // 'lib/src/presentation' is length 3. So if it's lib/src/presentation/stock/stock_screen.dart (5), depth = 1.
    final importPrefix = depth == 0 ? 'widgets/' : '../' * depth + 'widgets/';
    final importStatement = "import '${importPrefix}logo_loader.dart';";

    if (!content.contains('logo_loader.dart')) {
      // add import at the end of imports
      final importIndex = content.lastIndexOf(RegExp(r"import 'package:.*;"));
      if (importIndex != -1) {
        final endOfLine = content.indexOf('\n', importIndex);
        content = content.substring(0, endOfLine + 1) + importStatement + '\n' + content.substring(endOfLine + 1);
      } else {
        content = importStatement + '\n' + content;
      }
    }

    // Replace basic usages
    content = content.replaceAll('const CircularProgressIndicator()', 'const LogoLoader()');
    content = content.replaceAll('CircularProgressIndicator()', 'const LogoLoader()');
    // Replace with parameters (like color or strokeWidth)
    content = content.replaceAllMapped(RegExp(r'(const )?CircularProgressIndicator\([^)]*\)'), (match) {
      return 'const LogoLoader(size: 32.0)';
    });
    
    // There might be some 'const Center(child: LogoLoader())' that become invalid if LogoLoader is not fully const compatible, but it is.

    file.writeAsStringSync(content);
    print('Updated ${file.path}');
  }
}
