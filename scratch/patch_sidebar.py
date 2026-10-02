import re

with open('lib/src/presentation/layout/main_layout.dart', 'r') as f:
    content = f.read()

old_state = """class _HoverNavItemState extends State<_HoverNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {"""

new_state = """class _HoverNavItemState extends State<_HoverNavItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {"""

content = content.replace(old_state, new_state)

old_icon = """              leading: Icon(widget.icon, color: isSelected ? colorScheme.primary : (_isHovered ? Colors.white : colorScheme.onSurfaceVariant)),"""

new_icon = """              leading: Builder(
                builder: (ctx) {
                  if (isSelected && !_rotationCtrl.isAnimating) {
                    _rotationCtrl.repeat();
                  } else if (!isSelected && _rotationCtrl.isAnimating) {
                    _rotationCtrl.stop();
                    _rotationCtrl.reset();
                  }
                  return RotationTransition(
                    turns: _rotationCtrl,
                    child: Icon(widget.icon, color: isSelected ? colorScheme.primary : (_isHovered ? Colors.white : colorScheme.onSurfaceVariant)),
                  );
                },
              ),"""

content = content.replace(old_icon, new_icon)

with open('lib/src/presentation/layout/main_layout.dart', 'w') as f:
    f.write(content)
print("Sidebar patched.")
