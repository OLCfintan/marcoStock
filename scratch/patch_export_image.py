import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# We need to import dart:ui
if "import 'dart:ui' as ui;" not in content:
    content = "import 'dart:ui' as ui;\n" + content

old_export = """  Future<void> exportAndSharePdf(Uint8List pdfBytes, String fileName, ExportFormat format) async {
    if (format == ExportFormat.image) {
      final raster = await Printing.raster(pdfBytes, pages: [0], dpi: 300).first;
      final imageBytes = await raster.toPng();
      await Printing.sharePdf(bytes: imageBytes, filename: '$fileName.png');
    } else if (format == ExportFormat.excel) {"""

new_export = """  Future<void> exportAndSharePdf(Uint8List pdfBytes, String fileName, ExportFormat format) async {
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
    } else if (format == ExportFormat.excel) {"""

content = content.replace(old_export, new_export)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Image export stitched.")
