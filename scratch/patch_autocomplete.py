import re

with open('lib/src/presentation/widgets/autocomplete_search_field.dart', 'r') as f:
    content = f.read()

# Replace initialValue with initialText
old_props = """  final Widget? prefixIcon;
  final T? initialValue;"""
new_props = """  final Widget? prefixIcon;
  final T? initialValue;
  final String? initialText;"""
content = content.replace(old_props, new_props)

old_constructor = """    this.prefixIcon,
    this.initialValue,
  });"""
new_constructor = """    this.prefixIcon,
    this.initialValue,
    this.initialText,
  });"""
content = content.replace(old_constructor, new_constructor)

old_initial = """        initialValue: initialValue != null 
            ? TextEditingValue(text: displayStringForOption(initialValue!))
            : TextEditingValue.empty,"""
new_initial = """        initialValue: initialText != null 
            ? TextEditingValue(text: initialText!)
            : initialValue != null 
                ? TextEditingValue(text: displayStringForOption(initialValue!))
                : TextEditingValue.empty,"""
content = content.replace(old_initial, new_initial)

with open('lib/src/presentation/widgets/autocomplete_search_field.dart', 'w') as f:
    f.write(content)
