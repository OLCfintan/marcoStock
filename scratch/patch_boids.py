import re

with open('lib/src/presentation/widgets/screensaver_screen.dart', 'r') as f:
    content = f.read()

# 1. Reduce boids to 15
old_init = """    for (int i = 0; i < 40; i++) {"""
new_init = """    for (int i = 0; i < 15; i++) {"""
content = content.replace(old_init, new_init)

# 2. Optimize the Boid class to not use O(N^2) if possible, or at least avoid square roots
old_boid_class_regex = re.compile(r'class Boid \{.*?\}(?=\n\n|$)', re.DOTALL)

optimized_boid_class = """class Boid {
  Offset position;
  Offset velocity;

  Boid({required this.position, required this.velocity});

  void update(Size size, Offset mousePos) {
    // Extremely lightweight update without N^2 checking.
    // Fish simply swim in their direction, bounce off walls, and flee the mouse.
    
    // Flee mouse
    final dMouseSq = (position - mousePos).distanceSquared;
    if (dMouseSq < 40000) { // 200 pixel radius
      final escape = (position - mousePos);
      if (escape.dx != 0 || escape.dy != 0) {
          final norm = escape / escape.distance;
          velocity += norm * 0.5;
      }
    }
    
    // Constant forward speed
    if (velocity.distanceSquared > 0) {
      final norm = velocity / velocity.distance;
      velocity = norm * 2.0; // Fixed speed
    } else {
      velocity = const Offset(2.0, 0);
    }
    
    position += velocity;
    
    // Bounce walls
    if (position.dx < 0) {
      position = Offset(0, position.dy);
      velocity = Offset(-velocity.dx, velocity.dy);
    } else if (position.dx > size.width) {
      position = Offset(size.width, position.dy);
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    
    if (position.dy < 0) {
      position = Offset(position.dx, 0);
      velocity = Offset(velocity.dx, -velocity.dy);
    } else if (position.dy > size.height) {
      position = Offset(position.dx, size.height);
      velocity = Offset(velocity.dx, -velocity.dy);
    }
  }
}"""

content = old_boid_class_regex.sub(optimized_boid_class, content)

with open('lib/src/presentation/widgets/screensaver_screen.dart', 'w') as f:
    f.write(content)
print("Boids optimized.")
