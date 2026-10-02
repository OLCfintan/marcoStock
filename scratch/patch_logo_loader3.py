import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_build = """  @override
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

new_build = """  @override
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
  }"""

content = content.replace(old_build, new_build)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
