import re

with open('lib/src/presentation/products/add_product_screen.dart', 'r') as f:
    content = f.read()

# Only replace TextFormField( that doesn't have onFieldSubmitted inside it?
# Actually, the duplicate was because I ran two regexes in my previous script!
# `content = re.sub(r'(TextFormField\(\s*controller:\s*[^,]+,)', r'\1\n                                      onFieldSubmitted: (_) => _submit(),', content)`
# AND THEN
# `content = re.sub(r'(TextFormField\()', r'\1\n  onFieldSubmitted: (_) => _submit(),', content)`

content = re.sub(r'(TextFormField\()', r'\1\n  onFieldSubmitted: (_) => _submit(),', content)

with open('lib/src/presentation/products/add_product_screen.dart', 'w') as f:
    f.write(content)
print("add product screen patched")
