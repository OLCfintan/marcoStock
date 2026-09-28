import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MagnifierWrapper extends StatefulWidget {
  final Widget child;
  const MagnifierWrapper({super.key, required this.child});

  @override
  State<MagnifierWrapper> createState() => _MagnifierWrapperState();
}

class _MagnifierWrapperState extends State<MagnifierWrapper> {
  bool _isZoomed = false;
  Offset _mousePos = Offset.zero;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyZ && HardwareKeyboard.instance.isControlPressed) {
      setState(() {
        _isZoomed = !_isZoomed;
      });
      // We don't return true to consume it, just in case undo is needed, 
      // but usually we might want to return false to let others handle it.
      return false; 
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (_isZoomed) {
          setState(() {
            _mousePos = event.position;
          });
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isZoomed)
            Positioned(
              left: _mousePos.dx - 125,
              top: _mousePos.dy - 40,
              child: IgnorePointer(
                child: RawMagnifier(
                  decoration: const MagnifierDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.purpleAccent, width: 2),
                    ),
                  ),
                  size: const Size(250, 80),
                  magnificationScale: 1.25,
                  focalPointOffset: Offset.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
