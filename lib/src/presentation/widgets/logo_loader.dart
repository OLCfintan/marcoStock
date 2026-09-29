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
    if (widget.size < 60) {
      // For small inline loaders, fallback to simple rotating logo
      return Center(
        child: RotationTransition(
          turns: _controller,
          child: ClipOval(
            clipBehavior: Clip.antiAliasWithSaveLayer, 
            child: Image.asset('assets/images/logo.jpeg', width: widget.size, height: widget.size, fit: BoxFit.cover, filterQuality: FilterQuality.high)
          ),
        ),
      );
    }

    // For large/fullscreen loaders, show the premium puzzle crystal background
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
                
                return Stack(
                  children: [
                    // Moving Sticker 1
                    Positioned(
                      left: offset,
                      top: offset,
                      child: const Icon(Icons.format_paint, color: Colors.blueAccent, size: 30),
                    ),
                    // Moving Sticker 2 (Chemical)
                    Positioned(
                      left: offset + 60,
                      top: offset - 30,
                      child: const Icon(Icons.science, color: Colors.greenAccent, size: 30),
                    ),
                    // Moving Original Logo
                    Positioned(
                      left: offset + 20,
                      top: offset + 20,
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.jpeg', width: 40, height: 40, fit: BoxFit.cover),
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
