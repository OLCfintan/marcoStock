import 'dart:ui' as ui;
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
import '../../utils/number_to_words.dart';

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

  pw.Widget _bidiText(String text, {pw.TextStyle? style, pw.TextAlign? textAlign, int? maxLines, pw.TextOverflow? overflow}) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return pw.Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: isArabic ? pw.TextDirection.rtl : null,
    );
  }

  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, List<pw.Widget> Function() buildContent, {pw.Widget Function(pw.Context)? buildFooter}) {
    pw.Widget backgroundBuilder(pw.Context context) {
      if (!isFacture) return pw.Container(color: PdfColors.white);
      if (bgImage == null) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: PdfColors.white),
        );
      }
      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            pw.Container(color: PdfColors.white),
            pw.Center(
              child: pw.Watermark(
                child: pw.Opacity(
                  opacity: 0.25,
                  child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (options.layout == PrintLayout.a4_2up) {
      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: textDir,
            margin: isFacture ? const pw.EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24) : const pw.EdgeInsets.all(24),
            buildBackground: backgroundBuilder,
          ),
          build: (context) {
            return pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: pw.Column(children: buildContent())),
                      pw.SizedBox(width: 48),
                      pw.Expanded(child: pw.Column(children: buildContent())),
                    ],
                  ),
                ),
                if (buildFooter != null) buildFooter(context)
              ]
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
            margin: isFacture ? const pw.EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32) : const pw.EdgeInsets.all(32),
            buildBackground: backgroundBuilder,
          ),
          footer: buildFooter,
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

    final font = await PdfGoogleFonts.amiriRegular();
    final boldFont = await PdfGoogleFonts.amiriBold();
    
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
    );

    final logoBytes = companySettings['companyLogoPath'] != null && File(companySettings['companyLogoPath']!).existsSync()
        ? File(companySettings['companyLogoPath']!).readAsBytesSync()
        : null;
    pw.ImageProvider? logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    
        final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyIce = companySettings['companyIce'] ?? '';
    final companyRc = companySettings['companyRc'] ?? '';
    final companyRib = companySettings['companyRib'] ?? '';
    final companyEmail = companySettings['companyEmail'] ?? '';


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

        final isFactureDoc = invoice.documentType == 'FACTURE' || invoice.documentType == 'FACTURE_DUMMY';
    _addPages(doc, options, textDir, watermarkBg, isFactureDoc, buildFooter: isFactureDoc ? (context) => _buildDocumentFooter(companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone) : null, () {
      if (isFactureDoc) {
        return [
          _buildFactureHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, companyIce, companyRc, companyRib, companyEmail, logoImage ?? watermarkBg, l10n),
          pw.SizedBox(height: 15),
          _buildFactureInvoiceTable(lines, productMap, l10n),
          pw.SizedBox(height: 15),
          _buildFactureTotals(invoice, l10n, companyAddress, companyIce, companyRc, companyRib, companyEmail, companyPhone),
        ];
      } else {
        return [
          _buildOldHeader(invoice, client, companyName, companyAddress, companyPhone, companyTaxId, logoImage ?? watermarkBg, l10n),
          pw.SizedBox(height: 32),
          _buildOldInvoiceTable(lines, productMap, l10n),
          pw.SizedBox(height: 16),
          _buildOldTotals(invoice, l10n),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Container(
            alignment: pw.Alignment.center,
            child: _bidiText(l10n.pdfThankYou, style: const pw.TextStyle(color: PdfColors.grey)),
          ),
        ];
      }
    });


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
    final font = await PdfGoogleFonts.amiriRegular();
    final boldFont = await PdfGoogleFonts.amiriBold();
    
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
    );

    final logoBytes = companySettings['companyLogoPath'] != null && File(companySettings['companyLogoPath']!).existsSync()
        ? File(companySettings['companyLogoPath']!).readAsBytesSync()
        : null;
    pw.ImageProvider? logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    
        final companyName = companySettings['companyName'] ?? 'Marko Group';
    final companyAddress = companySettings['companyAddress'] ?? '';
    final companyPhone = companySettings['companyPhone'] ?? '';
    final companyTaxId = companySettings['companyTaxId'] ?? '';
    final companyIce = companySettings['companyIce'] ?? '';
    final companyRc = companySettings['companyRc'] ?? '';
    final companyRib = companySettings['companyRib'] ?? '';
    final companyEmail = companySettings['companyEmail'] ?? '';


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

    _addPages(doc, options, textDir, watermarkBg, false, buildFooter: null, () => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null || watermarkBg != null) pw.Container(height: 80, constraints: const pw.BoxConstraints(maxWidth: 250), margin: const pw.EdgeInsets.only(bottom: 8), child: pw.Image(logoImage ?? watermarkBg!, fit: pw.BoxFit.contain)),
                    _bidiText(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (companyAddress.isNotEmpty) _bidiText(companyAddress),
                    if (companyPhone.isNotEmpty) _bidiText(companyPhone),
                    if (companyTaxId.isNotEmpty) _bidiText('Tax ID: $companyTaxId'),
                    pw.SizedBox(height: 16),
                    _bidiText(l10n.pdfPurchase.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 8),
                    _bidiText('${l10n.pdfPurchase} #: ${purchase.purchaseNumber}'),
                    _bidiText('${l10n.pdfDate}: ${purchase.date.toLocal().toString().split(' ')[0]}'),
                    _bidiText('${l10n.pdfStatus}: ${purchase.status}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _bidiText(l10n.pdfSupplier, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    _bidiText(supplier?.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (supplier != null) _bidiText('${l10n.pdfTotalDebt}: ${supplier.balance.toStringAsFixed(2)} Dhs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
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
              headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5))),
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

    pw.Widget _buildFactureHeader(InvoiceEntity invoice, ClientEntity? client, String companyName, String companyAddress, String companyPhone, String companyTaxId, String companyIce, String companyRc, String companyRib, String companyEmail, pw.ImageProvider? logoImage, AppLocalizations l10n) {
    String docTypeTitle = l10n.pdfFacture;
    if (invoice.documentType == 'BON') docTypeTitle = l10n.pdfBonDeLivraison;
    else if (invoice.documentType == 'COMMANDE') docTypeTitle = l10n.pdfBonDeCommande;
    else if (invoice.documentType == 'TICKET') docTypeTitle = l10n.ticket;

    final clientName = invoice.clientNameOverride ?? client?.name ?? 'Client Passager';
    final clientIce = invoice.clientIceOverride ?? '';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _bidiText(companyName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  _bidiText('SARL AU', style: pw.TextStyle(fontSize: 10)),
                ]
              )
            ),
            if (logoImage != null)
              pw.Container(
                width: 200,
                constraints: const pw.BoxConstraints(maxHeight: 120),
                alignment: pw.Alignment.topCenter,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.SizedBox(width: 200),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _bidiText('MD DES PRODUITS CHIMIQUES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  _bidiText('IMPORT EXPORT', style: pw.TextStyle(fontSize: 10)),
                ]
              )
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 20),
        
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _bidiText('le : ${invoice.date.day.toString().padLeft(2,'0')}/${invoice.date.month.toString().padLeft(2,'0')}/${invoice.date.year}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            _bidiText('${docTypeTitle.toUpperCase()} N°:${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 15),
        
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('ICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Mode de reglement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              ]
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText(clientName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText(clientIce.isNotEmpty ? 'ICE : $clientIce' : '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Espece', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              ]
            ),
          ]
        ),
      ],
    );
  }

  pw.Widget _buildFactureInvoiceTable(List<InvoiceLineEntity> lines, Map<String, ProductEntity> productMap, AppLocalizations l10n) {
    return pw.TableHelper.fromTextArray(
      headers: ['Produits', 'Quantités', 'P.U HT', 'MT HT'],
      data: lines.map((line) {
        final product = productMap[line.productId];
        String productName = _localizedProductName(product, l10n.localeName);
        
        return [
          productName,
          line.quantity.toStringAsFixed(2),
          line.unitPrice.toStringAsFixed(2) + ' DH',
          line.lineTotal.toStringAsFixed(2) + ' DH',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 10),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#e2e2e2'),
      ),
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
    );
  }

    pw.Widget _buildFactureTotals(InvoiceEntity invoice, AppLocalizations l10n, String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    // Facture Math logic
    final mtHt = invoice.total.toDouble();
    final mtTva = mtHt * 0.20;
    final totalTtc = mtHt + mtTva;
    
    final amountWords = decimalToWordsTranslated(totalTtc, l10n.localeName);
    
    return pw.Column(
      children: [
        if (invoice.paymentMethod != null)
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: _bidiText('${l10n.modeDeReglement}: ${_localizedPaymentMethod(invoice.paymentMethod, l10n)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Container(
              width: 300,
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('Total HT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('MT TVA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('TOTAL TTC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('${mtHt.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('${mtTva.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: _bidiText('${totalTtc.toStringAsFixed(2)} DH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    ]
                  ),
                ]
              ),
            ),
          ]
        ),
pw.SizedBox(height: 15),
        pw.Container(
          alignment: pw.Alignment.centerLeft,
          child: _bidiText('${l10n.invoiceStoppedAt} ${amountWords.substring(0,1).toUpperCase() + amountWords.substring(1)}.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 40),
        
        // Footer Signature Area
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(right: 50),
          child: pw.Container(
            width: 150,
            height: 80,
            // You can add a signature image here if needed, or leave it blank
          ),
        ),
        
              ]
    );
  }

  pw.Widget _buildDocumentFooter(String companyAddress, String companyIce, String companyRc, String companyRib, String companyEmail, String companyPhone) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Divider(thickness: 2, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1, color: PdfColor.fromHex('#C5A059')),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('SIEGE SOCIAL : $companyAddress', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#C5A059'), fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText('RIB : $companyRib | ICE : $companyIce | RC : $companyRc | Email : $companyEmail', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.center,
          child: _bidiText(companyPhone, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false, double? fontSize, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _bidiText(
            label, 
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            )
          ),
          _bidiText(
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
  Future<void> exportAndSharePdf(Uint8List pdfBytes, String fileName, ExportFormat format) async {
    if (format == ExportFormat.image) {
      // Fetch all pages instead of just [0]
      final rasters = await Printing.raster(pdfBytes, dpi: 300).toList();
      
      if (rasters.length == 1) {
         final imageBytes = await rasters.first.toPng();
         await Printing.sharePdf(bytes: imageBytes, filename: '$fileName.png');
      } else {
         // Stitch multiple pages vertically
         final uiImages = await Future.wait(rasters.map((r) => r.toImage()));
         
         int totalHeight = 0;
         int maxWidth = 0;
         for (var img in uiImages) {
            totalHeight += img.height;
            if (img.width > maxWidth) maxWidth = img.width;
         }
         
         final recorder = ui.PictureRecorder();
         final canvas = ui.Canvas(recorder);
         final paint = ui.Paint();
         
         // Fill white background just in case
         canvas.drawRect(ui.Rect.fromLTWH(0, 0, maxWidth.toDouble(), totalHeight.toDouble()), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
         
         int currentY = 0;
         for (var img in uiImages) {
            canvas.drawImage(img, ui.Offset(0, currentY.toDouble()), paint);
            currentY += img.height;
            img.dispose(); // Free memory
         }
         
         final picture = recorder.endRecording();
         final finalImg = await picture.toImage(maxWidth, totalHeight);
         final byteData = await finalImg.toByteData(format: ui.ImageByteFormat.png);
         
         if (byteData != null) {
            await Printing.sharePdf(bytes: byteData.buffer.asUint8List(), filename: '$fileName.png');
         }
         finalImg.dispose();
      }
    } else if (format == ExportFormat.excel) {
      // Create a dummy CSV since true excel needs extra package
      String csv = "Document,\$fileName\n";
      csv += "NOTE: CSV export of invoice layout is experimental.\n";
      await Printing.sharePdf(bytes: Uint8List.fromList(csv.codeUnits), filename: '$fileName.csv');
    } else {
      await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
    }
  }



pw.Widget _buildOldHeader(InvoiceEntity invoice, ClientEntity? client, String companyName, String companyAddress, String companyPhone, String companyTaxId, pw.ImageProvider? logoImage, AppLocalizations l10n) {
    String docTypeTitle = l10n.pdfFacture;
    if (invoice.documentType == 'BON') docTypeTitle = l10n.pdfBonDeLivraison;
    else if (invoice.documentType == 'COMMANDE') docTypeTitle = l10n.pdfBonDeCommande;
    else if (invoice.documentType == 'TICKET') docTypeTitle = l10n.ticket;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null) 
              pw.Container(
                height: 100,
                constraints: const pw.BoxConstraints(maxWidth: 300),
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            _bidiText(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (companyAddress.isNotEmpty) _bidiText(companyAddress),
            if (companyPhone.isNotEmpty) _bidiText(companyPhone),
            if (companyTaxId.isNotEmpty) _bidiText('Tax ID: $companyTaxId'),
            pw.SizedBox(height: 16),
            _bidiText(docTypeTitle.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 8),
            _bidiText('$docTypeTitle #: ${invoice.invoiceNumber}'),
            _bidiText('${l10n.pdfDate}: ${invoice.date.toLocal().toString().split(' ')[0]}'),
            _bidiText('${l10n.pdfStatus}: ${invoice.status}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _bidiText('Client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            _bidiText(invoice.clientNameOverride ?? client?.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        if (client?.address != null && client!.address!.isNotEmpty) _bidiText(client.address!),
            if (client?.phone != null && client!.phone!.isNotEmpty) _bidiText(client.phone!),
            if (client?.contactDetails != null && client!.contactDetails!.isNotEmpty) _bidiText(client.contactDetails!),
            if (client != null && invoice.documentType != 'COMMANDE') _bidiText('${l10n.pdfTotalDebt}: ${client.balance.toStringAsFixed(2)} Dhs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          ],
        ),
      ],
    );
  }

pw.Widget _buildOldInvoiceTable(List<InvoiceLineEntity> lines, Map<String, ProductEntity> productMap, AppLocalizations l10n) {
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

pw.Widget _buildOldTotals(InvoiceEntity invoice, AppLocalizations l10n) {
    final balance = invoice.total - invoice.paidAmount;
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (invoice.paymentMethod != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: _bidiText('${l10n.modeDeReglement}: ${_localizedPaymentMethod(invoice.paymentMethod, l10n)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
        pw.Container(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
            _buildOldTotalRow('${l10n.pdfSubtotal}:', invoice.subtotal.toStringAsFixed(2)),
            pw.Divider(),
            _buildOldTotalRow('${l10n.pdfTotal}:', invoice.total.toStringAsFixed(2), isBold: true, fontSize: 14),
            pw.SizedBox(height: 8),
            _buildOldTotalRow('${l10n.pdfPaid}:', invoice.paidAmount.toStringAsFixed(2)),
            pw.Divider(color: PdfColors.grey400),
            _buildOldTotalRow('${l10n.pdfBalance}:', balance.toStringAsFixed(2), isBold: true, color: PdfColors.red700),
            ],
          ),
        ),
      ],
    );
  }

pw.Widget _buildOldTotalRow(String label, String amount, {bool isBold = false, double? fontSize, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _bidiText(
            label, 
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            )
          ),
          _bidiText(
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
