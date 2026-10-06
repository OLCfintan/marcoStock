import 'package:pdf/pdf.dart';

void main() {
  print('A4: ${PdfPageFormat.a4.width}x${PdfPageFormat.a4.height}');
  print('A5: ${PdfPageFormat.a5.width}x${PdfPageFormat.a5.height}');
}
