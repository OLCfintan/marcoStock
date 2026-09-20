import os
import re

files_to_fix = [
    'lib/src/presentation/layout/main_layout.dart',
    'lib/src/presentation/dashboard/dashboard_screen.dart',
    'lib/src/presentation/auth/login_screen.dart',
    'lib/src/presentation/widgets/logo_loader.dart'
]

for file_path in files_to_fix:
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            content = f.read()
        
        # We need to change the logo BoxDecoration to use white color and BoxFit.contain
        # The structure is usually:
        # decoration: const BoxDecoration(
        #   shape: BoxShape.circle,
        #   image: DecorationImage(
        #     image: AssetImage('assets/images/logo.jpeg'),
        #     fit: BoxFit.cover,
        #   ),
        # ),
        
        content = re.sub(
            r'decoration:\s*const\s*BoxDecoration\(\s*shape:\s*BoxShape\.circle,\s*image:\s*DecorationImage\(\s*image:\s*AssetImage\(\'assets/images/logo\.jpeg\'\),\s*fit:\s*BoxFit\.cover,\s*\),\s*\)',
            r"decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, image: DecorationImage(image: AssetImage('assets/images/logo.jpeg'), fit: BoxFit.contain))",
            content
        )
        
        with open(file_path, 'w') as f:
            f.write(content)

