import 'dart:math' as math;
import 'package:flutter/material.dart';

class LogoLoader extends StatefulWidget {
  final double size;
  const LogoLoader({super.key, this.size = 40.0});

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        double w = constraints.maxWidth != double.infinity ? constraints.maxWidth : screenSize.width;
        double h = constraints.maxHeight != double.infinity ? constraints.maxHeight : screenSize.height;
        
        if (constraints.maxWidth < 60 && constraints.maxWidth != double.infinity) {
           w = constraints.maxWidth;
           h = constraints.maxHeight;
        } else if (constraints.maxWidth == double.infinity && widget.size < 60) {
           w = screenSize.width;
           h = screenSize.height;
        }

        final double renderSize = (w < h ? w : h);
        
        if (renderSize < 60) {
           return Center(
             child: RotationTransition(
               turns: _controller,
               child: ClipOval(
                 clipBehavior: Clip.antiAliasWithSaveLayer, 
                 child: Image.asset('assets/images/logo.jpeg', width: renderSize, height: renderSize, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
               ),
             ),
           );
        }

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Pure code sleek background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
              // Premium Diagonal Lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _PremiumDiagonalPainter(_controller),
                ),
              ),
              // Traveling logos along the diagonals
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = _controller.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: List.generate(3, (i) {
                      final moveProgress = (progress + (i * 0.33)) % 1.0;
                      final offset = (w * 0.3) * (i - 1);
                      final p1 = Offset(-h + offset, -h);
                      final p2 = Offset(w + offset, w + h);
                      final pos = Offset.lerp(p1, p2, moveProgress)!;
                      return Positioned(
                        left: pos.dx - 24,
                        top: pos.dy - 24,
                        child: RotationTransition(
                           turns: _controller,
                           child: ClipOval(
                             clipBehavior: Clip.antiAliasWithSaveLayer,
                             child: Image.asset('assets/images/logo.jpeg', width: 48, height: 48, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                           ),
                        ),
                      );
                    }),
                  );
                },
              ),
              // Center main pulsing/rotating logo
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                     final pulse = 1.0 + 0.1 * math.sin(_controller.value * math.pi * 2);
                     return Transform.scale(
                       scale: pulse,
                       child: RotationTransition(
                         turns: _controller,
                         child: ClipOval(
                           clipBehavior: Clip.antiAliasWithSaveLayer,
                           child: Image.asset('assets/images/logo.jpeg', width: 120, height: 120, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                         ),
                       ),
                     );
                  }
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumDiagonalPainter extends CustomPainter {
  final Animation<double> animation;
  _PremiumDiagonalPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final maxDist = size.width + size.height;
    
    // Draw 3 beautiful glowing diagonal lines
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final lineColors = [
      Colors.greenAccent.withValues(alpha: 0.8),
      Colors.orangeAccent.withValues(alpha: 0.8),
      Colors.blueAccent.withValues(alpha: 0.8),
    ];
    
    for (int i = 0; i < 3; i++) {
      final offset = (size.width * 0.3) * (i - 1); // Center, left, right lines
      
      final p1 = Offset(-size.height + offset, -size.height);
      final p2 = Offset(size.width + offset, size.width + size.height);
      
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumDiagonalPainter oldDelegate) => true;
}
