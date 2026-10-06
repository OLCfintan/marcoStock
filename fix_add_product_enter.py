with open("lib/src/presentation/products/add_product_screen.dart", "r") as f:
    content = f.read()

old_build = """    return Scaffold("""

new_build = """    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold("""

if old_build in content:
    content = content.replace(old_build, new_build)
    import re
    # Match the end of the build method
    # It usually ends with `    );\n  }\n\n  InputDecoration _inputDecoration`
    content = re.sub(r'(\s*\);\n\s*\}\n\n\s*InputDecoration)', r'\n      ),\n    );\n  }\n\n  InputDecoration', content)
    
    with open("lib/src/presentation/products/add_product_screen.dart", "w") as f:
        f.write(content)
    print("Fixed add_product_screen.dart Enter key")
else:
    print("Old build not found")
