import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_builder = """            // Diagonal moving elements
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
            ),"""

new_builder = """            // Diagonal moving elements
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
            ),"""

content = content.replace(old_builder, new_builder)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
