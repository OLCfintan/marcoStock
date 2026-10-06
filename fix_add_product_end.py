import re

with open("lib/src/presentation/products/add_product_screen.dart", "r") as f:
    content = f.read()

# Replace the specific lines at the end of build
old_end = """        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader"""

new_end = """        ),
      ),
    ),
    );
  }

  Widget _buildSectionHeader"""

if old_end in content:
    content = content.replace(old_end, new_end)
    with open("lib/src/presentation/products/add_product_screen.dart", "w") as f:
        f.write(content)
    print("Fixed end of build")
else:
    print("Not found")
