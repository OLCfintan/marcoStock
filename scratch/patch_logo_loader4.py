import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_stack = """        return SizedBox(
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
        );"""

new_stack = """        return SizedBox(
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
                    import 'dart:math' as math;
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
        );"""

content = content.replace(old_stack, new_stack)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
print("LogoLoader rewritten to sleek gradient.")
