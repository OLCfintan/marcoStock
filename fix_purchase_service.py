import re

filepath = "lib/src/application/purchases/purchase_service.dart"
with open(filepath, 'r') as f:
    content = f.read()

old_add = r"""  Future<void> _addStock\(\{
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
    Decimal actualQuantityToAdd = convertQuantityToBase\(quantity, product, baseProduct\);
    
    final balanceQuery = _db.select\(_db.stockBalances\)\.\.where\(\(t\) => t.productId.equals\(targetProductId\) & t.locationId.equals\(locationId\)\);
    final balance = await balanceQuery.getSingleOrNull\(\);
    final currentQty = balance\?.quantity \?\? Decimal.zero;"""

new_add = r"""  Future<void> _addStock({
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
    Decimal actualQuantityToAdd = trackingInfo.quantity;
    
    final balanceQuery = _db.select(_db.stockBalances)..where((t) => t.productId.equals(targetProductId) & t.locationId.equals(locationId));
    final balance = await balanceQuery.getSingleOrNull();
    final currentQty = balance?.quantity ?? Decimal.zero;"""

content = re.sub(old_add, new_add, content)

old_deduct = r"""  Future<void> _deductStock\(\{
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

with open(filepath, 'w') as f:
    f.write(content)
print("Updated purchase_service.dart")
