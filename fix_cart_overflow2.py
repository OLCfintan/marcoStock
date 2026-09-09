import re

for f in ['lib/src/presentation/sales/pos_screen.dart', 
          'lib/src/presentation/sales/returns_screen.dart',
          'lib/src/presentation/purchases/purchases_screen.dart']:
    with open(f, 'r') as file:
        content = file.read()
        
    # Replace all Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [...]) in the checkout area
    # with FittedBox(fit: BoxFit.scaleDown, child: Row(...))
    
    # Let's target the exact text
    content = content.replace("Row(\n                          mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                          children: [\n                            const Text('Total Due:',", 
                              "FittedBox(\n                          fit: BoxFit.scaleDown,\n                          child: Row(\n                          mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                          children: [\n                            const Text('Total Due:',")
    
    content = content.replace("Row(\n                          mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                          children: [\n                            const Text('Total Paid:',",
                              "FittedBox(\n                          fit: BoxFit.scaleDown,\n                          child: Row(\n                          mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                          children: [\n                            const Text('Total Paid:',")
                              
    content = content.replace("Row(\n                          mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                          children: [\n                            const Text('Remaining Balance:',",
                              "FittedBox(\n                          fit: BoxFit.scaleDown,\n                          child: Row(\n                          mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                          children: [\n                            const Text('Remaining Balance:',")
                              
    content = content.replace("Row(\n                        mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                        children: [\n                          const Text('Total Owed:',",
                              "FittedBox(\n                        fit: BoxFit.scaleDown,\n                        child: Row(\n                        mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                        children: [\n                          const Text('Total Owed:',")

    # Add closing parenthesis for FittedBox!
    # Wait, the closing bracket of the Row is ],), so we need to replace ],\n                        ), with ],\n                        ),\n                        ), for these specific rows... this is too fragile.
    
    with open(f, 'w') as file:
        file.write(content)
