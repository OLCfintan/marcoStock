import re

def remove_action_menu(filepath, object_type):
    with open(filepath, 'r') as f:
        content = f.read()

    # Remove onLongPress: () => _showActionMenu(context, ref, client/supplier)
    content = re.sub(r"\s*onLongPress: \(\) => _showActionMenu\(context, ref, [a-z]+\),", "", content)

    # Remove the _showActionMenu function definition
    pattern = r"    void _showActionMenu\(BuildContext context, WidgetRef ref, " + object_type + r" [a-z]+\) \{[\s\S]*?    \}\n"
    content = re.sub(pattern, "", content)

    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Cleaned {filepath}")

remove_action_menu("lib/src/presentation/clients/clients_screen.dart", "Client")
remove_action_menu("lib/src/presentation/suppliers/suppliers_screen.dart", "Supplier")
