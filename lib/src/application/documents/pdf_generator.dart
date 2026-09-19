import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/widgets/print_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:decimal/decimal.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';

import 'package:drift/drift.dart' as drift;
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';
import '../settings/settings_service.dart';

final pdfGeneratorProvider = Provider<PdfGeneratorService>((ref) {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsServiceProvider);
  return PdfGeneratorService(db, settings);
});

class PdfGeneratorService {
  final AppDatabase _db;
  final SettingsService _settings;

  PdfGeneratorService(this._db, this._settings);

  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, List<pw.Widget> Function() buildContent) {
    pw.Widget backgroundBuilder(pw.Context context) {
      if (bgImage == null) return pw.Container();
      return pw.Watermark(
        child: pw.Opacity(
          opacity: 0.25,
          child: pw.Image(bgImage, fit: pw.BoxFit.contain),
        ),
      );
    }

    if (options.layout == PrintLayout.a4_2up) {
      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(24),
            buildBackground: backgroundBuilder,
          ),
          build: (context) {
            return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Column(children: buildContent())),
                pw.SizedBox(width: 48),
                pw.Expanded(child: pw.Column(children: buildContent())),
              ],
            );
          },
        ),
      );
    } else {
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: options.layout == PrintLayout.a5 ? PdfPageFormat.a5 : PdfPageFormat.a4,
            textDirection: textDir,
            margin: const pw.EdgeInsets.all(32),
            buildBackground: backgroundBuilder,
          ),
          build: (context) => buildContent(),
        ),
      );
    }
  }



  String _localizedProductName(ProductEntity? product, String locale) {
    if (product == null) return 'Unknown';
    String finalName = product.name;
    if (locale.startsWith('ar') && product.nameAr != null && product.nameAr!.isNotEmpty) {
      finalName = product.nameAr!;
    } else if (locale.startsWith('fr') && product.nameFr != null && product.nameFr!.isNotEmpty) {
      finalName = product.nameFr!;
    } else if (locale.startsWith('es') && product.nameEs != null && product.nameEs!.isNotEmpty) {
      finalName = product.nameEs!;
    }
    
    // Append unit logic similar to UI
    final unitSize = product.unitSize;
    final unit = product.unit;
    
    return '$finalName $unitSize$unit';
  }

  Future<Uint8List> generateInvoicePdf(String invoiceId, PrintOptions options) async {
    final l10n = await AppLocalizations.delegate.load(Locale(options.languageCode));
    var invoice = await (_db.select(_db.invoices)..where((tbl) => tbl.id.equals(invoiceId))).getSingle();
    final client = invoice.clientId != null
        ? await (_db.select(_db.clients)..where((tbl) => tbl.id.equals(invoice.clientId!))).getSingleOrNull()
        : null;
    final lines = await (_db.select(_db.invoiceLines)..where((tbl) => tbl.invoiceId.equals(invoiceId))).get();
    
    final productIds = lines.map((l) => l.productId).toSet();
    final products = await (_db.select(_db.products)..where((tbl) => tbl.id.isIn(productIds))).get();
    final productMap = {for (var p in products) p.id: p};

    final companySettings = await _settings.getAllCompanySettings();
    final taxRateStr = companySettings['companyTaxRate'] ?? '0';
    final taxRate = double.tryParse(taxRateStr) ?? 0.0;
    
    final dynamicTaxesDouble = (invoice.subtotal.toDouble() * taxRate) / 100;
    final dynamicTaxes = Decimal.parse(dynamicTaxesDouble.toStringAsFixed(2));
    final dynamicTotal = invoice.subtotal + dynamicTaxes;

    if (dynamicTotal != invoice.total || dynamicTaxes != invoice.taxes) {
      await (_db.update(_db.invoices)..where((tbl) => tbl.id.equals(invoice.id))).write(
        InvoicesCompanion(
          taxes: drift.Value(dynamicTaxes),
          total: drift.Value(dynamicTotal),
        )
      );
      invoice = invoice.copyWith(taxes: dynamicTaxes, total: dynamicTotal);
    }

    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();
    
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
    );

    final logoBytes = companySettings['companyLogoPath'] != null && File(companySettings['companyLogoPath']!).existsSync()
        ? File(companySettings['companyLogoPath']!).readAsBytesSync()
        : null;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    
    final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';

    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;
    try {
      final file = File('assets/images/pdf_logo.jpeg');
      if (file.existsSync()) {
        watermarkBg = pw.MemoryImage(file.readAsBytesSync());
      } else {
        final ByteData data = await rootBundle.load('assets/images/pdf_logo.jpeg');
        watermarkBg = pw.MemoryImage(data.buffer.asUint8List());
      }
    } catch (e) {
      print('Could not load watermark: $e');
    }

    _addPages(doc, options, textDir, watermarkBg, () => [
      _buildHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage, l10n),
      pw.SizedBox(height: 32),
      _buildInvoiceTable(lines, productMap, l10n),
      pw.SizedBox(height: 16),
      _buildTotals(invoice, l10n),
      pw.Spacer(),
      pw.Divider(),
      pw.Container(
        alignment: pw.Alignment.center,
        child: pw.Text(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey)),
      ),
    ]);

    return doc.save();
  }

  Future<Uint8List> generatePurchasePdf(String purchaseId, PrintOptions options) async {
    final l10n = await AppLocalizations.delegate.load(Locale(options.languageCode));
    var purchase = await (_db.select(_db.purchases)..where((tbl) => tbl.id.equals(purchaseId))).getSingle();
    final supplier = await (_db.select(_db.suppliers)..where((tbl) => tbl.id.equals(purchase.supplierId))).getSingleOrNull();
    final lines = await (_db.select(_db.purchaseLines)..where((tbl) => tbl.purchaseId.equals(purchaseId))).get();
    
    final productIds = lines.map((l) => l.productId).toSet();
    final products = await (_db.select(_db.products)..where((tbl) => tbl.id.isIn(productIds))).get();
    final productMap = {for (var p in products) p.id: p};

    final companySettings = await _settings.getAllCompanySettings();
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();
    
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
    );

    final logoBytes = companySettings['companyLogoPath'] != null && File(companySettings['companyLogoPath']!).existsSync()
        ? File(companySettings['companyLogoPath']!).readAsBytesSync()
        : null;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    
    final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';

    final textDir = l10n.localeName.startsWith('ar') ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pw.ImageProvider? watermarkBg;
    try {
      final file = File('assets/images/pdf_logo.jpeg');
      if (file.existsSync()) {
        watermarkBg = pw.MemoryImage(file.readAsBytesSync());
      } else {
        final ByteData data = await rootBundle.load('assets/images/pdf_logo.jpeg');
        watermarkBg = pw.MemoryImage(data.buffer.asUint8List());
      }
    } catch (e) {
      print('Could not load watermark: $e');
    }

    _addPages(doc, options, textDir, watermarkBg, () => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) pw.Container(height: 50, margin: const pw.EdgeInsets.only(bottom: 8), child: pw.Image(logoImage)),
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (companyAddress.isNotEmpty) pw.Text(companyAddress),
            if (companyPhone.isNotEmpty) pw.Text(companyPhone),
                    if (companyPhone.isNotEmpty) pw.Text(companyPhone),
                    if (companyTaxId.isNotEmpty) pw.Text('Tax ID: $companyTaxId'),
                    pw.SizedBox(height: 16),
                    pw.Text(l10n.pdfPurchase.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 8),
                    pw.Text('${l10n.pdfPurchase} #: ${purchase.purchaseNumber}'),
                    pw.Text('${l10n.pdfDate}: ${purchase.date.toLocal().toString().split(' ')[0]}'),
                    pw.Text('${l10n.pdfStatus}: ${purchase.status}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(l10n.pdfSupplier, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(supplier?.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (supplier != null) pw.Text('${l10n.pdfTotalDebt}: ${supplier.balance.toStringAsFixed(2)} Dhs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.TableHelper.fromTextArray(
              headers: [l10n.pdfItem, l10n.pdfQty, l10n.pdfPrice, l10n.pdfTotal],
              data: lines.map((line) {
                final product = productMap[line.productId];
                String productName = _localizedProductName(product, l10n.localeName);
                
                return [
                  productName,
                  line.quantity.toStringAsFixed(2),
                  line.unitPrice.toStringAsFixed(2),
                  line.lineTotal.toStringAsFixed(2),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5))),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildTotalRow('${l10n.pdfTotal}:', purchase.total.toStringAsFixed(2), isBold: true, fontSize: 14),
                  ],
                ),
              ),
            ),
    ]);

    return doc.save();
  }

  pw.Widget _buildHeader(InvoiceEntity invoice, ClientEntity? client, String companyName, String companyAddress, String companyPhone, String companyTaxId, pw.ImageProvider? logoImage, AppLocalizations l10n) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null) 
              pw.Container(
                height: 50,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage),
              ),
            pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (companyAddress.isNotEmpty) pw.Text(companyAddress),
            if (companyPhone.isNotEmpty) pw.Text(companyPhone),
            if (companyTaxId.isNotEmpty) pw.Text('Tax ID: $companyTaxId'),
            pw.SizedBox(height: 16),
            pw.Text((invoice.documentType == 'BON' ? l10n.bon : (invoice.documentType == 'TICKET' ? l10n.ticket : l10n.invoice)).toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 8),
            pw.Text('${(invoice.documentType == 'BON' ? l10n.bon : (invoice.documentType == 'TICKET' ? l10n.ticket : l10n.invoice))} #: ${invoice.invoiceNumber}'),
            pw.Text('${l10n.pdfDate}: ${invoice.date.toLocal().toString().split(' ')[0]}'),
            pw.Text('${l10n.pdfStatus}: ${invoice.status}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(client?.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        if (client?.address != null && client!.address!.isNotEmpty) pw.Text(client.address!),
            if (client?.phone != null && client!.phone!.isNotEmpty) pw.Text(client.phone!),
            if (client?.contactDetails != null && client!.contactDetails!.isNotEmpty) pw.Text(client.contactDetails!),
            if (client != null) pw.Text('${l10n.pdfTotalDebt}: ${client.balance.toStringAsFixed(2)} Dhs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceTable(List<InvoiceLineEntity> lines, Map<String, ProductEntity> productMap, AppLocalizations l10n) {
    return pw.TableHelper.fromTextArray(
      headers: [l10n.pdfItem, l10n.pdfQty, l10n.pdfPrice, l10n.pdfTotal],
      data: lines.map((line) {
        final product = productMap[line.productId];
        String productName = _localizedProductName(product, l10n.localeName);
        
        return [
          productName,
          line.quantity.toStringAsFixed(2),
          line.unitPrice.toStringAsFixed(2),
          line.lineTotal.toStringAsFixed(2),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey800,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: .5,
          ),
        ),
      ),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
      },
    );
  }

  pw.Widget _buildTotals(InvoiceEntity invoice, AppLocalizations l10n) {
    final balance = invoice.total - invoice.paidAmount;
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildTotalRow('${l10n.pdfSubtotal}:', invoice.subtotal.toStringAsFixed(2)),
            pw.Divider(),
            _buildTotalRow('${l10n.pdfTotal}:', invoice.total.toStringAsFixed(2), isBold: true, fontSize: 14),
            pw.SizedBox(height: 8),
            _buildTotalRow('${l10n.pdfPaid}:', invoice.paidAmount.toStringAsFixed(2)),
            pw.Divider(color: PdfColors.grey400),
            _buildTotalRow('${l10n.pdfBalance}:', balance.toStringAsFixed(2), isBold: true, color: PdfColors.red700),
          ],
        ),
      ),
    );
  }
  
  pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false, double? fontSize, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label, 
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            )
          ),
          pw.Text(
            amount, 
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            )
          ),
        ],
      ),
    );
  }
}
