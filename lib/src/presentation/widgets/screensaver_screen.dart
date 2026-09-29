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
  Offset _mousePos = Offset(-1000, -1000);
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
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
    setState(() {}); // trigger repaint
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _showUnlockDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock Application'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          autofocus: true,
          onSubmitted: (val) {
             if (val == widget.correctPassword) {
                 Navigator.pop(ctx);
                 widget.onUnlock();
             } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
             }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text == widget.correctPassword) {
                 Navigator.pop(ctx);
                 widget.onUnlock();
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
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
            // Fishes
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
            ),
            // Unlock Button
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
                  onPressed: _showUnlockDialog,
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
  final double maxSpeed = 3.0;

  Boid({required this.position, required this.velocity});

  void update(Size bounds, Offset mousePos) {
    // Basic avoidance of mouse
    final d = (position - mousePos).distance;
    if (d < 150) {
      final repel = (position - mousePos) / d;
      velocity += repel * 1.5;
    }

    // Move
    position += velocity;

    // Limit speed
    if (velocity.distance > maxSpeed) {
      velocity = (velocity / velocity.distance) * maxSpeed;
    }

    // Wrap around bounds
    if (position.dx < -50) position = Offset(bounds.width + 50, position.dy);
    if (position.dx > bounds.width + 50) position = Offset(-50, position.dy);
    if (position.dy < -50) position = Offset(position.dx, bounds.height + 50);
    if (position.dy > bounds.height + 50) position = Offset(position.dx, -50);
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
      
      // Draw fish body (orange with opacity)
      paint.color = Colors.orangeAccent.withValues(alpha: 0.8);
      final path = Path()
        ..moveTo(10, 0) // nose
        ..quadraticBezierTo(5, -8, -10, -3)
        ..lineTo(-15, -8) // tail fin top
        ..lineTo(-10, 0) // tail center
        ..lineTo(-15, 8) // tail fin bottom
        ..lineTo(-10, 3)
        ..quadraticBezierTo(5, 8, 10, 0);
        
      canvas.drawPath(path, paint);
      
      // Eye
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
