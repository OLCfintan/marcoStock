import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_painter = """    for (int i = 0; i < 3; i++) {
      final offset = (size.width * 0.3) * (i - 1); // Center, left, right lines
      
      final p1 = Offset(-size.height + offset, -size.height);
      final p2 = Offset(size.width + offset, size.width + size.height);
      
      canvas.drawLine(p1, p2, paint);
      
      // Moving dot/sticker inside the line
      final stickerPaint = Paint()
        ..color = lineColors[i]
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);
        
      // Offset by progress
      final moveProgress = (progress + (i * 0.3)) % 1.0;
      final stickerPos = Offset.lerp(p1, p2, moveProgress)!;
      
      canvas.drawCircle(stickerPos, 12, stickerPaint);
      canvas.drawCircle(stickerPos, 6, Paint()..color = Colors.white);
    }"""

new_painter = """    for (int i = 0; i < 3; i++) {
      final offset = (size.width * 0.3) * (i - 1); // Center, left, right lines
      
      final p1 = Offset(-size.height + offset, -size.height);
      final p2 = Offset(size.width + offset, size.width + size.height);
      
      canvas.drawLine(p1, p2, paint);
    }"""

content = content.replace(old_painter, new_painter)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
print("Diagonal Painter patched.")
