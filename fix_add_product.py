import re

with open("lib/src/presentation/products/add_product_screen.dart", "r") as f:
    content = f.read()

old_logic = """    final existingRefList = await (db.select(db.products)..where((t) => t.reference.equals(refToCheck) & t.isActive.equals(true))).get();
    if (existingRefList.isNotEmpty && existingRefList.first.id != widget.productToEdit?.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product with this Reference already exists!')));
      return;
    }"""

new_logic = """    final existingRefList = await (db.select(db.products)..where((t) => t.reference.equals(refToCheck))).get();
    if (existingRefList.isNotEmpty && existingRefList.first.id != widget.productToEdit?.id) {
      if (!existingRefList.first.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('A deleted product with this Reference exists in the Recycle Bin. Restore it or permanently delete it first.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product with this Reference already exists!')));
      }
      return;
    }"""

content = content.replace(old_logic, new_logic)

# Replace build start
old_build = """    return Scaffold("""
new_build = """    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold("""
content = content.replace(old_build, new_build)

# Add closing tags
# Look for the end of the build method
old_end = """        ),
      ),
    );
  }

  Widget _buildSectionHeader"""
new_end = """        ),
      ),
    ),
    ),
    );
  }

  Widget _buildSectionHeader"""
content = content.replace(old_end, new_end)

with open("lib/src/presentation/products/add_product_screen.dart", "w") as f:
    f.write(content)
print("Done")
