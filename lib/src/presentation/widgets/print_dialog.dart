import 'package:flutter/material.dart';
import 'package:marko_group/src/localization/arb/app_localizations.dart';

enum PrintLayout {
  a4,
  a5,
  a4_2up, // 2-up A5 on A4 landscape
}

class PrintOptions {
  final PrintLayout layout;
  final String languageCode;

  PrintOptions({required this.layout, required this.languageCode});
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

  @override
  void initState() {
    super.initState();
    _selectedLayout = PrintLayout.a4;
    _selectedLang = widget.defaultLanguageCode;
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
          RadioListTile<PrintLayout>(
            title: const Text('A4 Landscape (2-up A5)'),
            subtitle: const Text('Prints 2 copies side-by-side on A4'),
            value: PrintLayout.a4_2up,
            groupValue: _selectedLayout,
            onChanged: (v) { if(v!=null) setState(() => _selectedLayout = v); },
            contentPadding: EdgeInsets.zero,
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
            Navigator.pop(context, PrintOptions(layout: _selectedLayout, languageCode: _selectedLang));
          },
          child: Text('Generate PDF'),
        ),
      ],
    );
  }
}
