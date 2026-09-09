import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerField extends StatefulWidget {
  final String label;
  final ValueChanged<String?> onChanged;
  final String? initialValue;

  const ImagePickerField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  String? _selectedPath;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialValue;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedPath = pickedFile.path;
        });
        widget.onChanged(pickedFile.path);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedPath = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Browse Image'),
            ),
            if (_selectedPath != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearImage,
                icon: const Icon(Icons.clear, color: Colors.red),
                tooltip: 'Clear image',
              ),
            ],
          ],
        ),
        if (_selectedPath != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Invalid Image', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(_selectedPath!, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}
