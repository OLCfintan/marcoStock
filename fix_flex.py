import re, glob

files = glob.glob('lib/src/presentation/**/*.dart', recursive=True)
for f in files:
    with open(f, 'r') as file:
        content = file.read()
        
    orig = content
    
    # We will replace `Row(\n  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n  children: [\n    const Text('Total`
    # with `FittedBox(fit: BoxFit.scaleDown, child: Row(...`
    # We will just replace `Row(` with `FittedBox(fit: BoxFit.scaleDown, child: Row(` when it is followed by `Total Due` or `Total Paid` etc.
    
    # This is still annoying because of the closing `)`.
    # Let's fix the problem in a different way. Instead of FittedBox, we can just use `Expanded` on the text.
    # Text('...', overflow: TextOverflow.ellipsis)
    
    pass
