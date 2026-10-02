import re

with open('lib/src/presentation/widgets/screensaver_screen.dart', 'r') as f:
    content = f.read()

old_update = """  void _updateBoids() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    for (var boid in _boids) {
      boid.update(size, _mousePos);
    }
    setState(() {});
  }"""

new_update = """  void _updateBoids() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    for (var boid in _boids) {
      boid.update(size, _mousePos);
    }
    // Removed setState, we use AnimatedBuilder below
  }"""

content = content.replace(old_update, new_update)

old_stack_children = """            // Fishes
            Positioned.fill(
              child: CustomPaint(
                painter: AquariumPainter(_boids),
              ),
            ),
            // Custom Cursor
            Positioned(
              left: _mousePos.dx - 30,
              top: _mousePos.dy - 30,
              child: IgnorePointer(
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                       BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5),
                    ],
                  ),
                  child: ClipOval(child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover)),
                ),
              ),
            ),"""

new_stack_children = """            // Fishes and Cursor (Animated efficiently)
            AnimatedBuilder(
              animation: _ticker,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: AquariumPainter(_boids),
                      ),
                    ),
                    Positioned(
                      left: _mousePos.dx - 30,
                      top: _mousePos.dy - 30,
                      child: IgnorePointer(
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                               BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5),
                            ],
                          ),
                          child: ClipOval(child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),"""

content = content.replace(old_stack_children, new_stack_children)

with open('lib/src/presentation/widgets/screensaver_screen.dart', 'w') as f:
    f.write(content)
print("CPU optimized")
