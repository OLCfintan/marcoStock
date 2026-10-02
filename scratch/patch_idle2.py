import re

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'r') as f:
    content = f.read()

old_state = """class _AppIdleWrapperState extends ConsumerState<AppIdleWrapper> {
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
      onPointerHover: (_) => _resetTimer(),"""

new_state = """class _AppIdleWrapperState extends ConsumerState<AppIdleWrapper> {
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
      behavior: HitTestBehavior.translucent,"""

content = content.replace(old_state, new_state)

with open('lib/src/presentation/widgets/app_idle_wrapper.dart', 'w') as f:
    f.write(content)
print("AppIdleWrapper optimized.")
