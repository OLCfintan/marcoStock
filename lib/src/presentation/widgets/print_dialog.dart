import 'package:flutter/material.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';

enum PrintLayout {
  a4,
  a5,

}

enum ExportFormat {
  pdf,
  image,
  excel,
}

class PrintOptions {
  final PrintLayout layout;
  final String languageCode;
  final ExportFormat format;

  PrintOptions({required this.layout, required this.languageCode, this.format = ExportFormat.pdf});
}

class PrintDialog extends StatefulWidget {
  final String defaultLanguageCode;
  
  const PrintDialog({super.key, required this.defaultLanguageCode});

  static Future<PrintOptions?> show(BuildContext context, {String defaultLanguageCode = 'fr'}) {
    return showDialog<PrintOptions>(
      context: context,
      builder: (ctx) => PrintDialog(defaultLanguageCode: defaultLanguageCode),
    );
  }

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  late PrintLayout _selectedLayout;
  late String _selectedLang;
  late ExportFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedLayout = PrintLayout.a4;
    _selectedLang = widget.defaultLanguageCode;
    _selectedFormat = ExportFormat.pdf;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Print Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Document Language:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLang,
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              DropdownMenuItem(value: 'fr', child: Text('French')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'es', child: Text('Spanish')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedLang = v);
            },
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
          const SizedBox(height: 16),
          const Text('Paper Format:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioListTile<PrintLayout>(
            title: const Text('A4 Portrait (Normal)'),
            value: PrintLayout.a4,
            groupValue: _selectedLayout,
            onChanged: (v) { if(v!=null) setState(() => _selectedLayout = v); },
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<PrintLayout>(
            title: const Text('A5 Portrait'),
            value: PrintLayout.a5,
            groupValue: _selectedLayout,
            onChanged: (v) { if(v!=null) setState(() => _selectedLayout = v); },
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),
          const Text('Export Format:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExportFormat>(
            value: _selectedFormat,
            items: const [
              DropdownMenuItem(value: ExportFormat.pdf, child: Text('PDF Document')),
              DropdownMenuItem(value: ExportFormat.image, child: Text('Image (JPEG)')),
              DropdownMenuItem(value: ExportFormat.excel, child: Text('Excel (CSV)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedFormat = v);
            },
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, PrintOptions(layout: _selectedLayout, languageCode: _selectedLang, format: _selectedFormat));
          },
          child: Text('Generate Document'),
        ),
      ],
    );
  }
}
