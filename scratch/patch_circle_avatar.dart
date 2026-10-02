import 'dart:io';

void main() {
  final files = [
    'lib/src/presentation/sales/pos_screen.dart',
    'lib/src/presentation/sales/returns_screen.dart',
    'lib/src/presentation/purchases/purchases_screen.dart',
  ];
  
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // Replace standard CircleAvatar with styled one
    content = content.replaceAll(
      "leading: CircleAvatar(child: Text('\${line.quantity}')),", 
      "leading: CircleAvatar(backgroundColor: const Color(0xFF93C572), child: Text('\${line.quantity}', style: const TextStyle(color: Colors.black))),"
    );
    
    file.writeAsStringSync(content);
  }
}
