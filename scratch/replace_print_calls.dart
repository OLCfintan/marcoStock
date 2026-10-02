import 'dart:io';

void main() {
  final file = File('lib/src/presentation/documents/documents_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    '''                                    // Replaced navigation
                                    () async {
                                      final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                                      if (options != null && context.mounted) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => PdfPreviewScreen(
                                            title: '\${invoice.documentType} #\${invoice.invoiceNumber}',
                                            buildPdf: () => ref.read(pdfGeneratorProvider).generateInvoicePdf(invoice.id, options),
                                          ),
                                        ));
                                      }
                                    }();''',
    '''                                    _handlePrintInvoice(invoice, context);'''
  );
  
  file.writeAsStringSync(content);
}
