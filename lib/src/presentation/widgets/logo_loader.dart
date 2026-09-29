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
        // If the parent offers no constraints (e.g. Center inside an unbounded stack), we fill the screen!
        double w = constraints.maxWidth != double.infinity ? constraints.maxWidth : screenSize.width;
        double h = constraints.maxHeight != double.infinity ? constraints.maxHeight : screenSize.height;
        
        // If they explicitly passed a small size and didn't expand it, maybe respect it if it's explicitly tiny
        // But the requirement is to ALWAYS cover the gray background for wait screens.
        // Usually wait screens have infinity constraints if not wrapped strictly.
        
        // If we're inside a button, max width will be finite (e.g. 40), or we can check widget.size.
        if (constraints.maxWidth < 60 && constraints.maxWidth != double.infinity) {
           w = constraints.maxWidth;
           h = constraints.maxHeight;
        } else if (constraints.maxWidth == double.infinity && widget.size < 60) {
           // We are in an unbounded container but requested a small size!
           // BUT the user specifically wants the wait screens to COVER the whole gray background.
           // In pdf_preview_screen, PdfPreview centers the loader. So constraints are infinity, widget.size is 40.
           // We must fill the screen.
           w = screenSize.width;
           h = screenSize.height;
        }

        final double renderSize = (w < h ? w : h);
        
        if (renderSize < 60) {
           // For very small buttons/inlines
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

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
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
