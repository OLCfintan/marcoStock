import sys

with open('lib/src/presentation/purchases/purchases_screen.dart', 'r') as f:
    content = f.read()

content = content.replace('''        ),
      ),
    );
    );
  }
}''', '''        ),
      ),
    ),
    );
  }
}''')

with open('lib/src/presentation/purchases/purchases_screen.dart', 'w') as f:
    f.write(content)
