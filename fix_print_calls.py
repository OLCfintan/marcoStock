import re

def process(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We want to replace `Navigator.push(...)` up to `));`
    # Let's just find the `onTap: () { Navigator.push(...) }`
    
    # Let's replace the inner PdfPreviewScreen instantiations that have PrintOptions hardcoded
    
    pattern = r"Navigator\.push\(context,\s*MaterialPageRoute\(\s*builder:\s*\(\_\)\s*=>\s*PdfPreviewScreen\(\s*title:\s*(.*?),\s*buildPdf:\s*\(\)\s*=>\s*ref\.read\(pdfGeneratorProvider\)\.(generate[A-Za-z]+Pdf)\((.*?),\s*PrintOptions\(.*?\) \)\s*,?\s*\)\s*,?\s*\)\s*,?\s*\);"
    # Wait, the end of PrintOptions is `languageCode: Localizations.localeOf(context).languageCode))`
    
    # Let's just use string replacement because regex is annoying here.
    
    parts = content.split("Navigator.push(context, MaterialPageRoute(")
    
    new_parts = [parts[0]]
    for part in parts[1:]:
        if "PdfPreviewScreen(" in part and "PrintOptions(" in part and "buildPdf: () =>" in part:
            # It's one of ours!
            # Find the end of the push statement. It usually ends with `));`
            end_idx = part.find("));")
            if end_idx != -1:
                inner = part[:end_idx]
                rest = part[end_idx+3:]
                
                # Extract title, func, id
                title_match = re.search(r"title:\s*(.*?),", inner, re.DOTALL)
                func_match = re.search(r"ref\.read\(pdfGeneratorProvider\)\.(generate[A-Za-z]+Pdf)\((.*?),\s*PrintOptions", inner, re.DOTALL)
                
                if title_match and func_match:
                    title = title_match.group(1).strip()
                    func = func_match.group(1).strip()
                    id_var = func_match.group(2).strip()
                    
                    replacement = f"""
                        // Replaced navigation
                        () async {{
                          final options = await PrintDialog.show(context, defaultLanguageCode: Localizations.localeOf(context).languageCode);
                          if (options != null && context.mounted) {{
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PdfPreviewScreen(
                                title: {title},
                                buildPdf: () => ref.read(pdfGeneratorProvider).{func}({id_var}, options),
                              ),
                            ));
                          }}
                        }}();
                    """
                    new_parts.append(replacement + rest)
                    continue
        new_parts.append("Navigator.push(context, MaterialPageRoute(" + part)
        
    with open(filepath, 'w') as f:
        f.write("".join(new_parts))
    print(f"Updated {filepath}")

process("lib/src/presentation/documents/documents_screen.dart")
process("lib/src/presentation/widgets/human_profile_dialog.dart")
