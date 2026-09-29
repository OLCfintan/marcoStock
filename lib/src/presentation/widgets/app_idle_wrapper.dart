import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/settings/settings_service.dart';
import 'screensaver_screen.dart';
import '../../application/auth/auth_service.dart';

class AppIdleWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppIdleWrapper({super.key, required this.child});

  @override
  ConsumerState<AppIdleWrapper> createState() => _AppIdleWrapperState();
}

class _AppIdleWrapperState extends ConsumerState<AppIdleWrapper> {
  Timer? _timer;
  bool _isScreensaverActive = false;
  DateTime _lastActive = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startPeriodicTimer();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  void _markActive() {
    _lastActive = DateTime.now();
  }

  bool _handleKey(KeyEvent event) {
    _markActive();
    return false;
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isScreensaverActive) return;
      if (!mounted) return;
      
      final delayMinutes = ref.read(sleepDelayProvider);
      if (delayMinutes <= 0 || delayMinutes >= 9999) return; // Never or disabled
      
      final diff = DateTime.now().difference(_lastActive);
      if (diff.inMinutes >= delayMinutes) {
        setState(() {
          _isScreensaverActive = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // No need to reset timer on provider change, the periodic timer checks the provider dynamically.

    return Listener(
      onPointerDown: (_) => _markActive(),
      onPointerMove: (_) => _markActive(),
      onPointerHover: (_) => _markActive(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          if (_isScreensaverActive)
            Positioned.fill(
              child: Navigator(
                onGenerateRoute: (settings) => PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return ScreensaverScreen(
                      onUnlock: () {
                        setState(() {
                          _isScreensaverActive = false;
                        });
                        _markActive();
                      },
                      correctPassword: ref.watch(currentUserProvider)?.pinCode ?? '1234', 
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
