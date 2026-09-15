import re

import os

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # If PrintDialog isn't imported, add it
    if "import 'package:flutter_riverpod/flutter_riverpod.dart';" in content and "print_dialog.dart" not in content:
        # Check if in widgets dir or outer
        if "widgets" in filepath:
            content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'print_dialog.dart';")
        else:
            content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../widgets/print_dialog.dart';")

    # The pattern is:
    # Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(title: "...", buildPdf: () => ref.read(pdfGeneratorProvider).generate[A-Za-z]+Pdf(id_var, PrintOptions(...)))));
    # Or split over multiple lines.
    
    # Actually, the safest way is to find `Navigator.push(...)` wrapping `PdfPreviewScreen` 
    # and replace the whole expression.
    
    # We will use regex to find: `Navigator.push(context, MaterialPageRoute(... PdfPreviewScreen(... generateX(id, PrintOptions(...))) ...))`
    
    pattern = r"Navigator\.push\(\s*context,\s*MaterialPageRoute\(\s*builder:\s*\(\_\)\s*=>\s*PdfPreviewScreen\(\s*title:\s*([^,]+),\s*buildPdf:\s*\(\)\s*=>\s*ref\.read\(pdfGeneratorProvider\)\.(generate[a-zA-Z]+Pdf)\(([^,]+),\s*PrintOptions\([^\)]+\)\)\s*,?\s*\)\s*,?\s*\)\s*\)"
    
    def replacement(m):
        title_str = m.group(1).strip()
        func_name = m.group(2).strip()
        id_var = m.group(3).strip()
        return f"""() async {{
          final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
          if (options != null && context.mounted) {{
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(
                title: {title_str},
                buildPdf: () => ref.read(pdfGeneratorProvider).{func_name}({id_var}, options),
              ),
            ));
          }}
        }}()"""
        
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

process_file("lib/src/presentation/documents/documents_screen.dart")
process_file("lib/src/presentation/widgets/human_profile_dialog.dart")

