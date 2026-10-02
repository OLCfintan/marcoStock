import re

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'r') as f:
    content = f.read()

old_listener = """  void _resetTimer([_]) {
    if (_isScreensaverActive) return;
    _idleTimer?.cancel();
    final delay = ref.read(sleepDelayProvider);
    if (delay.inMinutes >= 9999) return; // 'Never'

    _idleTimer = Timer(delay, () {
      setState(() {
        _isScreensaverActive = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _resetTimer,
      onPointerMove: _resetTimer,
      onPointerHover: _resetTimer,
      onPointerPanZoomUpdate: _resetTimer,
      behavior: HitTestBehavior.translucent,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _resetTimer();
          return KeyEventResult.ignored;
        },"""

new_listener = """  DateTime _lastActive = DateTime.now();

  void _markActive([_]) {
    _lastActive = DateTime.now();
  }

  void _resetTimer([_]) {
    _idleTimer?.cancel();
    
    // Use a lightweight periodic timer that wakes up once a second, instead of rebuilding or resetting timers on every mouse frame!
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isScreensaverActive) return;
      final delay = ref.read(sleepDelayProvider);
      if (delay.inMinutes >= 9999) return; // 'Never'
      
      if (DateTime.now().difference(_lastActive) >= delay) {
        setState(() {
          _isScreensaverActive = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _markActive,
      onPointerMove: _markActive,
      onPointerHover: _markActive,
      onPointerPanZoomUpdate: _markActive,
      behavior: HitTestBehavior.translucent,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _markActive();
          return KeyEventResult.ignored;
        },"""

content = content.replace(old_listener, new_listener)

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'w') as f:
    f.write(content)
print("AppIdleWrapper optimized.")
