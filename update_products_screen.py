import re

filepath = "lib/src/presentation/products/products_screen.dart"
with open(filepath, 'r') as f:
    content = f.read()

# Modify DataRow in ProductsScreen
old_row_actions = r"""        DataCell\(
          Row\(
            mainAxisSize: MainAxisSize\.min,
            children: \[
              IconButton\(icon: const Icon\(Icons\.add_box, color: Colors\.green\), tooltip: 'Create Consumables', onPressed: \(\) => onConsumable\(p\)\),
              IconButton\(icon: const Icon\(Icons\.edit, color: Colors\.blue\), onPressed: \(\) => onEdit\(p\)\),
              if \(isAdmin\)
                IconButton\(icon: const Icon\(Icons\.delete, color: Colors\.red\), onPressed: \(\) => onDelete\(p\)\),
            \],
          \),
        \),"""

new_row_actions = r"""        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'consumables') onConsumable(p);
              if (value == 'edit') onEdit(p);
              if (value == 'delete') onDelete(p);
              if (value == 'family') onAddFamilyMember(p);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'consumables', child: Text('Create Consumables')),
              const PopupMenuItem(value: 'family', child: Text('Add Family Member')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (isAdmin)
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ),"""

content = re.sub(old_row_actions, new_row_actions, content, flags=re.MULTILINE | re.DOTALL)

# Add onAddFamilyMember to _ProductDataSource
content = content.replace("final Function(Product) onEdit;", "final Function(Product) onEdit;\n  final Function(Product) onAddFamilyMember;")
content = content.replace("required this.onEdit,", "required this.onEdit,\n    required this.onAddFamilyMember,")

# Add onAddFamilyMember to _ProductDataSource instantiation
old_instantiation = r"""                  onConsumable: \(p\) => _showConsumableDialog\(context, p\),
                  onEdit: \(p\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(\_\) => AddProductScreen\(productToEdit: p\)\)\),"""

new_instantiation = r"""                  onConsumable: (p) => _showConsumableDialog(context, p),
                  onEdit: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(productToEdit: p))),
                  onAddFamilyMember: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(templateProduct: p))),"""

content = re.sub(old_instantiation, new_instantiation, content)

with open(filepath, 'w') as f:
    f.write(content)
print(f"Updated {filepath}")
