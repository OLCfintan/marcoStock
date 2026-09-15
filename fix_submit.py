import re
filepath = "lib/src/presentation/products/add_product_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Fix the if condition back to what it should be
bad_submit = r"""    if \(widget\.productToEdit != null \|\| widget\.templateProduct != null\) \{
      final source = widget\.productToEdit \?\? widget\.templateProduct!;
      final product = widget\.productToEdit!\.copyWith\("""

good_submit = r"""    if (widget.productToEdit != null) {
      final product = widget.productToEdit!.copyWith("""

content = re.sub(bad_submit, good_submit, content)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Fixed {filepath}")
