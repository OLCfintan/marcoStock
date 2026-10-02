import re

with open('lib/src/presentation/widgets/logo_loader.dart', 'r') as f:
    content = f.read()

old_stack = """              // Premium Golden Crystal Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/loading_bg.jpg',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low, // Lower quality for RAM efficiency
                ),
              ),"""

new_stack = """              // Pure code sleek background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),"""

content = content.replace(old_stack, new_stack)

with open('lib/src/presentation/widgets/logo_loader.dart', 'w') as f:
    f.write(content)
print("Removed loading_bg.jpg from LogoLoader.")
