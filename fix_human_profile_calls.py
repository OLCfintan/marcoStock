import re

filepath = "lib/src/presentation/widgets/human_profile_dialog.dart"
with open(filepath, 'r') as f:
    content = f.read()

if "import 'print_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'print_dialog.dart';")

# In human_profile_dialog, there are probably IconButtons for printing invoices directly in the ledger table.
# E.g. onPressed: () => ... PdfPreviewScreen ...

def replacement(match):
    prefix = match.group(1)
    func_name = match.group(2)
    id_var = match.group(3)
    
    return f"""{prefix}{{
          final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
          if (options != null && context.mounted) {{
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(
                title: '{func_name}',
                buildPdf: () => ref.read(pdfGeneratorProvider).{func_name}({id_var}, options),
              ),
            ));
          }}
        }}"""

# Try to match the whole Navigator.push block for print buttons if we can't easily find it
# It's easier to just blindly replace the argument like I did before, but adding `await PrintDialog.show` would be nice.
# Since it's inside `onPressed`, we can just replace the whole `Navigator.push(...)` with the `PrintDialog` logic.

pattern = r"(onPressed:\s*\(\)\s*(?:async\s*)?)\{\s*Navigator\.push\(\s*context,\s*MaterialPageRoute\(\s*builder:\s*\(\_\)\s*=>\s*PdfPreviewScreen\(\s*title:\s*[^,]+,\s*buildPdf:\s*\(\)\s*=>\s*ref\.read\(pdfGeneratorProvider\)\.(generate[a-zA-Z]+Pdf)\(([^,]+),\s*AppLocalizations\.of\(context\)!?\)\s*,\s*\)\s*,\s*\)\s*\);\s*\}"

content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

# And as a fallback for any other calls
content = re.sub(
    r"generateInvoicePdf\(([^,]+),\s*AppLocalizations\.of\(context\)!?\)",
    r"generateInvoicePdf(\1, PrintOptions(layout: PrintLayout.a4, languageCode: Localizations.localeOf(context).languageCode))",
    content
)
content = re.sub(
    r"generatePurchasePdf\(([^,]+),\s*AppLocalizations\.of\(context\)!?\)",
    r"generatePurchasePdf(\1, PrintOptions(layout: PrintLayout.a4, languageCode: Localizations.localeOf(context).languageCode))",
    content
)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
