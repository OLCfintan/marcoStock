import os
import re

def fix_logo(file_path):
    if not os.path.exists(file_path): return
    with open(file_path, 'r') as f:
        content = f.read()

    # main_layout and dashboard use this specific block:
    # ClipRRect(
    #   borderRadius: BorderRadius.circular(6),
    #   clipBehavior: Clip.antiAliasWithSaveLayer,
    #   child: Image.asset('assets/images/logo.jpeg', width: 45, height: 32, fit: BoxFit.cover, filterQuality: FilterQuality.high),
    # )
    
    # Let's just use regex to match the ClipRRect block for the logo and replace it with ClipOval
    content = re.sub(
        r'ClipRRect\(\s*borderRadius:\s*BorderRadius\.circular\(\d+\),\s*clipBehavior:\s*Clip\.antiAliasWithSaveLayer,\s*child:\s*Image\.asset\(\'assets/images/logo\.jpeg\',\s*width:\s*[\d\.]+,\s*height:\s*([\d\.]+),\s*fit:\s*BoxFit\.cover,\s*filterQuality:\s*FilterQuality\.high\),\s*\)',
        r"ClipOval(clipBehavior: Clip.antiAliasWithSaveLayer, child: Image.asset('assets/images/logo.jpeg', width: \1, height: \1, fit: BoxFit.cover, filterQuality: FilterQuality.high))",
        content
    )

    # For logo_loader:
    # child: Image.asset('assets/images/logo.jpeg', width: widget.size * 1.41, height: widget.size, fit: BoxFit.cover, filterQuality: FilterQuality.high),
    content = re.sub(
        r'ClipRRect\(\s*borderRadius:\s*BorderRadius\.circular\(\d+\),\s*clipBehavior:\s*Clip\.antiAliasWithSaveLayer,\s*child:\s*Image\.asset\(\'assets/images/logo\.jpeg\',\s*width:\s*widget\.size\s*\*\s*[\d\.]+,\s*height:\s*widget\.size,\s*fit:\s*BoxFit\.cover,\s*filterQuality:\s*FilterQuality\.high\),\s*\)',
        r"ClipOval(clipBehavior: Clip.antiAliasWithSaveLayer, child: Image.asset('assets/images/logo.jpeg', width: widget.size, height: widget.size, fit: BoxFit.cover, filterQuality: FilterQuality.high))",
        content
    )

    with open(file_path, 'w') as f:
        f.write(content)

fix_logo('lib/src/presentation/layout/main_layout.dart')
fix_logo('lib/src/presentation/dashboard/dashboard_screen.dart')
fix_logo('lib/src/presentation/auth/login_screen.dart')
fix_logo('lib/src/presentation/widgets/logo_loader.dart')
