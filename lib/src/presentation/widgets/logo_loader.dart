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
              // Sleek Apple-style Frosted / Animated Gradient Background
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3 + 0.2 * _controller.value),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                }
              ),
              // Elegant Logo Pulse
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Smooth pulsing effect using sine wave
                    
                    final pulse = 0.9 + 0.1 * math.sin(_controller.value * 2 * math.pi);
                    final logoSize = (w < h ? w : h) * 0.3;
                    return Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 30 * pulse,
                              spreadRadius: 10 * pulse,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Elegant orbital rings
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final logoSize = (w < h ? w : h) * 0.3;
                    return RotationTransition(
                      turns: _controller,
                      child: Container(
                        width: logoSize * 1.5,
                        height: logoSize * 1.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Theme.of(context).colorScheme.primary, blurRadius: 8),
                              ]
                            ),
                          ),
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
