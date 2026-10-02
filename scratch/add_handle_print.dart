import 'dart:io';

void main() {
  final file = File('lib/src/presentation/documents/documents_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('Future<void> _handlePrintInvoice')) {
    final methodStr = '''
  Future<void> _handlePrintInvoice(dynamic invoice, BuildContext context) async {
    final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
    if (options == null || !context.mounted) return;

    if (options.format == ExportFormat.pdf) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: '\${invoice.documentType} #\${invoice.invoiceNumber}',
          buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options),
        ),
      ));
    } else {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating document...')));
      try {
        final pdfBytes = await ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options);
        final fileName = '\${invoice.documentType}_\${invoice.invoiceNumber}';
        await ref.read(pdfGeneratorProvider).exportAndSharePdf(pdfBytes, fileName, options.format);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
        }
      }
    }
  }
''';
    
    // Insert before _ConvertInvoiceDialog
    final insertIndex = content.indexOf('class _ConvertInvoiceDialog ');
    content = content.replaceRange(insertIndex, insertIndex, methodStr + '\n');
    file.writeAsStringSync(content);
  }
}
