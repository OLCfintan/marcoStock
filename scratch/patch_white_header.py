import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

old_header = """    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,"""
new_header = """    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,"""
content = content.replace(old_header, new_header)

old_header_end = """        ),
      ],
    );
  }

  pw.Widget _buildFactureInvoiceTable"""
new_header_end = """        ),
      ]),
    );
  }

  pw.Widget _buildFactureInvoiceTable"""
content = content.replace(old_header_end, new_header_end)

with open('lib/src/application/documents/pdf_generator.dart', 'w') as f:
    f.write(content)
print("Header patched")
