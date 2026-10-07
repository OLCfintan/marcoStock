import sys

with open('lib/src/application/sales/sales_service.dart', 'r') as f:
    content = f.read()

exception_class = '''class InsufficientStockException implements Exception {
  final String productName;
  final String available;
  final String requested;

  InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
  });

  @override
  String toString() {
    return 'Insufficient stock for "$productName".\\nAvailable: $available\\nRequested: $requested';
  }
}

class SalesService {'''

content = content.replace('class SalesService {', exception_class)

content = content.replace('''        throw Exception('Insufficient stock for "$productName".\\nAvailable: ${currentQty.toStringAsFixed(2)}\\nRequested: ${actualQuantityToDeduct.toStringAsFixed(2)}');''', '''        throw InsufficientStockException(
          productName: productName,
          available: currentQty.toStringAsFixed(2),
          requested: actualQuantityToDeduct.toStringAsFixed(2),
        );''')

with open('lib/src/application/sales/sales_service.dart', 'w') as f:
    f.write(content)
