import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ScreensaverScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final String correctPassword;

  const ScreensaverScreen({super.key, required this.onUnlock, required this.correctPassword});

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<Boid> _boids = [];
  Offset _mousePos = const Offset(-1000, -1000);
  final Random _rand = Random();
  
  bool _showPasswordInput = false;
  String _errorMsg = '';
  final TextEditingController _pwdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _boids.add(Boid(
        position: Offset(_rand.nextDouble() * 1000, _rand.nextDouble() * 1000),
        velocity: Offset((_rand.nextDouble() - 0.5) * 4, (_rand.nextDouble() - 0.5) * 4),
      ));
    }
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_updateBoids);
  }

  void _updateBoids() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    for (var boid in _boids) {
      boid.update(size, _mousePos);
    }
    // Removed setState, we use AnimatedBuilder below
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _attemptUnlock() {
    if (_pwdCtrl.text == widget.correctPassword) {
      widget.onUnlock();
    } else {
      setState(() {
        _errorMsg = 'Incorrect password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onHover: (e) {
          _mousePos = e.position;
        },
        child: Stack(
          children: [
            // Glassy water background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.6),
                      Colors.indigo.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Fishes and Cursor (Animated efficiently)
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
            ),
            
            // Password Modal
            if (_showPasswordInput)
              Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 48, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _pwdCtrl,
                          obscureText: true,
                          autofocus: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                          onSubmitted: (_) => _attemptUnlock(),
                        ),
                      ),
                      if (_errorMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => setState(() { _showPasswordInput = false; _errorMsg = ''; _pwdCtrl.clear(); }),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _attemptUnlock,
                            child: const Text('Unlock'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open, color: Colors.blueAccent),
                    label: const Text('Unlock', style: TextStyle(color: Colors.blueAccent, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => setState(() => _showPasswordInput = true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Boid {
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
}

class AquariumPainter extends CustomPainter {
  final List<Boid> boids;
  AquariumPainter(this.boids);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var boid in boids) {
      final angle = boid.velocity.direction;
      canvas.save();
      canvas.translate(boid.position.dx, boid.position.dy);
      canvas.rotate(angle);
      paint.color = Colors.orangeAccent.withValues(alpha: 0.8);
      final path = Path()
        ..moveTo(10, 0)
        ..quadraticBezierTo(5, -8, -10, -3)
        ..lineTo(-15, -8)
        ..lineTo(-10, 0)
        ..lineTo(-15, 8)
        ..lineTo(-10, 3)
        ..quadraticBezierTo(5, 8, 10, 0);
      canvas.drawPath(path, paint);
      paint.color = Colors.white;
      canvas.drawCircle(const Offset(4, -2), 1.5, paint);
      paint.color = Colors.black;
      canvas.drawCircle(const Offset(4.5, -2), 0.5, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
