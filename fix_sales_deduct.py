import re

filepath = "lib/src/application/sales/sales_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_deduct = r"""  Future<void> _deductStock\(\{
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
    required String locationId,
    bool allowNegative = false,
  \}\) async \{
    final product = await \(_db.select\(_db.products\)\.\.where\(\(t\) => t.id.equals\(productId\)\)\).getSingleOrNull\(\);
    if \(product == null\) return;
    
    final baseProduct = await getDeterministicBaseProduct\(_db, product\);
    String targetProductId = baseProduct.id;
    Decimal actualQuantityToDeduct = convertQuantityToBase\(quantity, product, baseProduct\);
    
    final balanceQuery = _db.select\(_db.stockBalances\)\.\.where\(\(t\) => t.productId.equals\(targetProductId\) & t.locationId.equals\(locationId\)\);
    final balance = await balanceQuery.getSingleOrNull\(\);
    final currentQty = balance\?.quantity \?\? Decimal.zero;"""

new_deduct = r"""  Future<void> _deductStock({
    required String productId, 
    required Decimal quantity,
    required String reason,
    required String referenceOperationId,
    required String userId,
    required String locationId,
    bool allowNegative = false,
  }) async {
    final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingleOrNull();
    if (product == null) return;
    
    final trackingInfo = await getStockTrackingInfo(_db, product, quantity, locationId);
    String targetProductId = trackingInfo.productId;
    Decimal actualQuantityToDeduct = trackingInfo.quantity;
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;"""

content = re.sub(old_deduct, new_deduct, content)


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
    Decimal actualQuantityToRestore = convertQuantityToBase\(quantity, product, baseProduct\);
    
    final balanceQuery = _db.select\(_db.stockBalances\)\.\.where\(\(t\) => t.productId.equals\(targetProductId\) & t.locationId.equals\(locationId\)\);
    final balance = await balanceQuery.getSingleOrNull\(\);
    final currentQty = balance\?.quantity \?\? Decimal.zero;
    
    final newQty = currentQty \+ actualQuantityToRestore;"""

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
    Decimal actualQuantityToRestore = trackingInfo.quantity;
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;
    
    final newQty = currentQty + actualQuantityToRestore;"""

content = re.sub(old_restore, new_restore, content)


with open(filepath, 'w') as f:
    f.write(content)
print("Updated sales_service.dart")
