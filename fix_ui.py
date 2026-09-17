import re

filepath = "lib/src/presentation/products/add_product_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_code = r"""                    if \(_packagingType == 'Unit'\) \.\.\.\[
                      TextFormField\(
                        controller: _unitsPerBoxController,
                        decoration: _inputDecoration\('Units Per Box \(For Inventory Math\)'\),
                        keyboardType: TextInputType.number,
                        validator: \(value\) \{
                          if \(value == null \|\| value.isEmpty\) return 'Required';
                          if \(int.tryParse\(value\) == null\) return 'Must be integer';
                          return null;
                        \},
                      \),
                      const SizedBox\(height: 16\),
                    \],"""

new_code = r"""                    TextFormField(
                      controller: _unitsPerBoxController,
                      decoration: _inputDecoration('Units Per Box (For Inventory Math)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be integer';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),"""

content = re.sub(old_code, new_code, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated add_product_screen.dart")
