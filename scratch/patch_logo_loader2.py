import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_build = """  @override
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
  }"""

new_build = """  @override
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
  }"""

content = content.replace(old_build, new_build)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
