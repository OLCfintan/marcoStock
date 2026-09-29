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
        // If it is inside a bounded parent like Expanded or a full screen, it should fill it.
        // Otherwise it defaults to widget.size (or a sensible default).
        final double w = constraints.maxWidth != double.infinity ? constraints.maxWidth : widget.size;
        final double h = constraints.maxHeight != double.infinity ? constraints.maxHeight : widget.size;
        
        final double renderSize = (w < h ? w : h);
        
        if (renderSize < 60) {
           // For very small buttons/inlines, just do a rotating logo so it's not squished
           return Center(
             child: RotationTransition(
               turns: _controller,
               child: ClipOval(
                 clipBehavior: Clip.antiAliasWithSaveLayer, 
                 child: Image.asset('assets/images/logo.jpeg', width: renderSize, height: renderSize, fit: BoxFit.cover, filterQuality: FilterQuality.high)
               ),
             ),
           );
        }

        return Container(
          width: w,
          height: h,
          child: Stack(
            children: [
              // Puzzle Crystal Background covering everything
              Positioned.fill(
                child: Image.asset(
                  'assets/images/loading_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Diagonal moving elements
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = _controller.value;
                  final longestSide = (w > h ? w : h);
                  
                  // Move diagonally across the whole area
                  final offset = -longestSide + (progress * longestSide * 2);
                  
                  final stickerSize = longestSide * 0.15;
                  final logoSize = longestSide * 0.2;
                  
                  return Stack(
                    children: [
                      Positioned(
                        left: offset,
                        top: offset,
                        child: Icon(Icons.format_paint, color: Colors.blueAccent, size: stickerSize),
                      ),
                      Positioned(
                        left: offset + (longestSide * 0.3),
                        top: offset - (longestSide * 0.15),
                        child: Icon(Icons.science, color: Colors.greenAccent, size: stickerSize),
                      ),
                      Positioned(
                        left: offset + (longestSide * 0.1),
                        top: offset + (longestSide * 0.1),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.jpeg', width: logoSize, height: logoSize, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
