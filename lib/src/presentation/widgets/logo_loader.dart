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
    // Always show the premium puzzle crystal background, regardless of size
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            // Puzzle Crystal Background
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
                // Move from top-left (-size) to bottom-right (size)
                final progress = _controller.value;
                final offset = -widget.size + (progress * widget.size * 2);
                
                final stickerSize = widget.size * 0.3;
                final logoSize = widget.size * 0.4;
                
                return Stack(
                  children: [
                    // Moving Sticker 1
                    Positioned(
                      left: offset,
                      top: offset,
                      child: Icon(Icons.format_paint, color: Colors.blueAccent, size: stickerSize),
                    ),
                    // Moving Sticker 2 (Chemical)
                    Positioned(
                      left: offset + (widget.size * 0.6),
                      top: offset - (widget.size * 0.3),
                      child: Icon(Icons.science, color: Colors.greenAccent, size: stickerSize),
                    ),
                    // Moving Original Logo
                    Positioned(
                      left: offset + (widget.size * 0.2),
                      top: offset + (widget.size * 0.2),
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
      ),
    );
  }
}
