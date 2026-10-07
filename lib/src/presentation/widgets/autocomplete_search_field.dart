import 'package:flutter/material.dart';

class AutocompleteSearchField<T extends Object> extends StatefulWidget {
  final Future<List<T>> Function(String) getSuggestions;
  final String Function(T) displayStringForOption;
  final void Function(T)? onSelected;
  final String? labelText;
  final Widget? prefixIcon;
  final T? initialValue;
  final String? initialText;
  final FocusNode? focusNode;

  const AutocompleteSearchField({
    super.key,
    required this.getSuggestions,
    required this.displayStringForOption,
    this.onSelected,
    this.labelText,
    this.prefixIcon,
    this.initialValue,
    this.initialText,
    this.focusNode,
  });

  @override
  State<AutocompleteSearchField<T>> createState() => _AutocompleteSearchFieldState<T>();
}

class _AutocompleteSearchFieldState<T extends Object> extends State<AutocompleteSearchField<T>> {
  late String _displayText;
  
  @override
  void initState() {
    super.initState();
    _displayText = widget.initialText ?? (widget.initialValue != null ? widget.displayStringForOption(widget.initialValue!) : '');
  }
  
  @override
  void didUpdateWidget(covariant AutocompleteSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText || widget.initialValue != oldWidget.initialValue) {
      _displayText = widget.initialText ?? (widget.initialValue != null ? widget.displayStringForOption(widget.initialValue!) : '');
    }
  }

  void _showSearchDialog() async {
    final result = await showDialog<T>(
      context: context,
      builder: (ctx) => _SearchDialog<T>(
        getSuggestions: widget.getSuggestions,
        displayStringForOption: widget.displayStringForOption,
        labelText: widget.labelText,
      ),
    );
    if (result != null) {
      setState(() {
        _displayText = widget.displayStringForOption(result);
      });
      if (widget.onSelected != null) {
        widget.onSelected!(result);
      }
      widget.focusNode?.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showSearchDialog,
      focusNode: widget.focusNode,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isFocused: widget.focusNode?.hasFocus ?? false,
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon ?? const Icon(Icons.search),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        child: Text(_displayText.isEmpty ? 'Select...' : _displayText),
      ),
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final Future<List<T>> Function(String) getSuggestions;
  final String Function(T) displayStringForOption;
  final String? labelText;

  const _SearchDialog({
    super.key,
    required this.getSuggestions,
    required this.displayStringForOption,
    this.labelText,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  String _query = '';
  List<T> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await widget.getSuggestions(_query);
      if (mounted) setState(() => _results = res);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search ${widget.labelText ?? ''}...',
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (val) {
          _query = val;
          _fetch();
        },
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final option = _results[index];
                return ListTile(
                  title: Text(widget.displayStringForOption(option)),
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
