import re
import glob

files = glob.glob('lib/src/presentation/**/*.dart', recursive=True)

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Remove const from PopupMenuItem when it contains AppLocalizations
    content = re.sub(r'const\s+PopupMenuItem\(([^)]*AppLocalizations[^)]*)\)', r'PopupMenuItem(\1)', content)
    
    # Remove unnecessary const in TextStyle inside PopupMenuItem that were left behind if I replaced
    # wait, the regex above handles the outer const. What about `Text(..., style: const TextStyle(...))`?
    # the error was `unnecessary_const` for `const TextStyle(color: Colors.red)` inside something that is already not const? No, if we removed the outer const, the inner might need it, which is fine. The error was because I added `const TextStyle` inside a `const PopupMenuItem`! Now that `PopupMenuItem` is not const, `const TextStyle` is perfectly valid and required if we want to save allocations, or maybe just fine.
    
    with open(f, 'w') as file:
        file.write(content)
        
print("Consts fixed.")
