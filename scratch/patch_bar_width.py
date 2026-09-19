import re

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'r') as f:
    content = f.read()

# Replace the SizedBox(height: 300, child: salesAsync.when(...)) with a LayoutBuilder
old_code = """        child: SizedBox(
          height: 300,
          child: salesAsync.when(
            data: (sales) {"""

new_code = """        child: SizedBox(
          height: 300,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return salesAsync.when(
                data: (sales) {"""

content = content.replace(old_code, new_code)

# Replace the bar width with dynamic width
old_bar = """                          width: 32,
                          borderRadius: BorderRadius.zero,"""
new_bar = """                          width: sales.isEmpty ? 32 : (constraints.maxWidth / sales.length).clamp(10.0, 100.0) * 0.9,
                          borderRadius: BorderRadius.zero,"""
content = content.replace(old_bar, new_bar)

# Close the LayoutBuilder parenthesis
old_end = """            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Failed to load chart data: $err')),
          ),
        ),
      ),"""
new_end = """            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Failed to load chart data: $err')),
          );
            }
          ),
        ),
      ),"""
content = content.replace(old_end, new_end)

with open('lib/src/presentation/dashboard/dashboard_screen.dart', 'w') as f:
    f.write(content)

