import re

with open('lib/src/application/documents/pdf_generator.dart', 'r') as f:
    content = f.read()

# Modify _addPages signature
old_sig = """  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, {pw.Widget Function(pw.Context)? buildFooter}, List<pw.Widget> Function() buildContent) {"""
new_sig = """  void _addPages(pw.Document doc, PrintOptions options, pw.TextDirection textDir, pw.ImageProvider? bgImage, bool isFacture, double bgOpacity, {pw.Widget Function(pw.Context)? buildFooter}, List<pw.Widget> Function() buildContent) {"""
# wait, the signature in the file is different! Let's check exactly what it is.
