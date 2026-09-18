import re

filepath = "lib/src/application/stock/stock_helpers.dart"
with open(filepath, 'r') as f:
    content = f.read()

new_code = """
class StockTrackingInfo {
  final String productId;
  final Decimal quantity;

  StockTrackingInfo(this.productId, this.quantity);
}

Future<StockTrackingInfo> getStockTrackingInfo(
  AppDatabase db,
  ProductEntity product,
  Decimal physicalQuantity,
  String locationId,
) async {
  // Magazin tracks independent physical counts
  if (locationId == 'MAGAZIN_01') {
    return StockTrackingInfo(product.id, physicalQuantity);
  }
  
  // Base warehouse tracks mathematically aggregated SI units at the family head
  final baseProduct = await getDeterministicBaseProduct(db, product);
  final siUnits = convertQuantityToBase(physicalQuantity, product, baseProduct);
  return StockTrackingInfo(baseProduct.id, siUnits);
}
"""

content += new_code

with open(filepath, 'w') as f:
    f.write(content)
print("Updated stock_helpers.dart")
