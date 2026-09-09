
import 'package:flutter/material.dart';

class AutocompleteSearchField<T extends Object> extends StatelessWidget {
  final Future<List<T>> Function(String) getSuggestions;
  final String Function(T) displayStringForOption;
  final void Function(T)? onSelected;
  final String? labelText;
  final Widget? prefixIcon;
  final T? initialValue;

  const AutocompleteSearchField({
    super.key,
    required this.getSuggestions,
    required this.displayStringForOption,
    this.onSelected,
    this.labelText,
    this.prefixIcon,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<T>(
        displayStringForOption: displayStringForOption,
        initialValue: initialValue != null 
            ? TextEditingValue(text: displayStringForOption(initialValue!))
            : TextEditingValue.empty,
        optionsBuilder: (TextEditingValue textEditingValue) async {
          return await getSuggestions(textEditingValue.text);
        },
        onSelected: onSelected,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
            decoration: InputDecoration(
              labelText: labelText,
              prefixIcon: prefixIcon ?? const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<T> onSelected,
          Iterable<T> options,
        ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              clipBehavior: Clip.hardEdge,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 250, 
                  maxWidth: constraints.maxWidth,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final T option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Text(
                          displayStringForOption(option),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
