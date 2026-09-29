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

  @override
  void initState() {
    super.initState();
    _startTimer();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    _resetTimer();
    return false;
  }

  void _startTimer() {
    _timer?.cancel();
    final delayMinutes = ref.read(sleepDelayProvider);
    if (delayMinutes > 0) {
      _timer = Timer(Duration(minutes: delayMinutes), () {
        setState(() {
          _isScreensaverActive = true;
        });
      });
    }
  }

  void _resetTimer() {
    if (_isScreensaverActive) return; // Don't reset if already showing screensaver, wait for unlock
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sleepDelayProvider, (prev, next) {
      if (!_isScreensaverActive) _startTimer();
    });

    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerHover: (_) => _resetTimer(),
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
                        _resetTimer();
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
