import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_stack = """        return SizedBox(
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
              // Premium Diagonal Lines and Traveling Stickers
              Positioned.fill(
                child: CustomPaint(
                  painter: _PremiumDiagonalPainter(_controller),
                ),
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
        );"""

content = content.replace(old_stack, new_stack)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
print("LogoLoader Stack patched.")
