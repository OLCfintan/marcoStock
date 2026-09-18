import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_restore = r"""  Future<void> _restoreStock\(\{
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
    required String locationId,
  \}\) async \{
    final product = await \(_db.select\(_db.products\)\.\.where\(\(t\) => t.id.equals\(productId\)\)\).getSingleOrNull\(\);
    if \(product == null\) return;
    
    final baseProduct = await getDeterministicBaseProduct\(_db, product\);
    String targetProductId = baseProduct.id;
    Decimal actualQtyToAdd = convertQuantityToBase\(quantity, product, baseProduct\);"""

new_restore = r"""  Future<void> _restoreStock({
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
    required String locationId,
  }) async {
    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final trackingInfo = await getStockTrackingInfo(_db, product, quantity, locationId);
    String targetProductId = trackingInfo.productId;
    Decimal actualQtyToAdd = trackingInfo.quantity;"""

content = re.sub(old_restore, new_restore, content)

with open(filepath, 'w') as f:
    f.write(content)
print("Updated sales_service.dart")
