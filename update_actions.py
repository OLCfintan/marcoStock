import os
import re

def replace_in_file(filepath, pattern, replacement):
    with open(filepath, 'r') as f:
        content = f.read()
    new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        print(f"No changes made to {filepath}")

# 1. Update AddProductScreen to accept templateProduct
add_product_path = "lib/src/presentation/products/add_product_screen.dart"
replace_in_file(
    add_product_path,
    r"final Product\? productToEdit;\n\s*const AddProductScreen\(\{super\.key, this\.productToEdit\}\);",
    r"final Product? productToEdit;\n  final Product? templateProduct;\n  const AddProductScreen({super.key, this.productToEdit, this.templateProduct});"
)

replace_in_file(
    add_product_path,
    r"if \(widget\.productToEdit != null\) \{",
    r"if (widget.productToEdit != null || widget.templateProduct != null) {\n      final source = widget.productToEdit ?? widget.templateProduct!;"
)

replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.name",
    r"source.name"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.nameAr",
    r"source.nameAr"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.nameFr",
    r"source.nameFr"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.nameEs",
    r"source.nameEs"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.reference",
    r"source.reference"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.sellingPrice",
    r"source.sellingPrice"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.tier2Price",
    r"source.tier2Price"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.tier3Price",
    r"source.tier3Price"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.minimumStock",
    r"source.minimumStock"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.baseMinimumStock",
    r"source.baseMinimumStock"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.magazinMinimumStock",
    r"source.magazinMinimumStock"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.imagePath",
    r"source.imagePath"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.unitSize",
    r"source.unitSize"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.unitsPerBox",
    r"source.unitsPerBox"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.unit",
    r"source.unit"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit!\.packagingType",
    r"source.packagingType"
)
replace_in_file(
    add_product_path,
    r"_loadConsumables\(\);",
    r"if (widget.productToEdit != null) _loadConsumables();"
)
replace_in_file(
    add_product_path,
    r"widget\.productToEdit != null \? 'Edit Product'",
    r"widget.productToEdit != null ? 'Edit Product' : (widget.templateProduct != null ? 'Add Family Member' : AppLocalizations.of(context)!.addNewProduct)"
)
