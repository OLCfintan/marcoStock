import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class UniversalScanner {
  /// Opens a unified scanner experience.
  /// On Mobile: Opens the Camera using mobile_scanner.
  /// On Desktop: Opens a Keyboard Listening Dialog for USB Scanners.
  static Future<String?> scan(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const _MobileScannerScreen(),
        ),
      );
    } else {
      return showDialog<String>(
        context: context,
        builder: (context) => const _DesktopScannerDialog(),
      );
    }
  }
}

class _MobileScannerScreen extends StatefulWidget {
  const _MobileScannerScreen();

  @override
  State<_MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<_MobileScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            controller.stop();
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}

class _DesktopScannerDialog extends StatefulWidget {
  const _DesktopScannerDialog();

  @override
  State<_DesktopScannerDialog> createState() => _DesktopScannerDialogState();
}

class _DesktopScannerDialogState extends State<_DesktopScannerDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Barcode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text('Please scan the item using your USB Barcode Scanner. Ensure the scanner is configured to send an Enter keystroke after reading.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              labelText: 'Awaiting Scanner Input...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
