import 'dart:io';

void main() {
  final file = File('lib/src/application/documents/pdf_generator.dart');
  var content = file.readAsStringSync();
  
  // Need to replace _buildHeader, _buildInvoiceTable, _buildTotals.
  
  // First, add imports
  if (!content.contains("import '../../utils/number_to_words.dart';")) {
    content = content.replaceFirst(
      "import 'package:marko_group/src/localization/arb/app_localizations.dart';",
      "import 'package:marko_group/src/localization/arb/app_localizations.dart';\nimport '../../utils/number_to_words.dart';"
    );
  }

  file.writeAsStringSync(content);
}
