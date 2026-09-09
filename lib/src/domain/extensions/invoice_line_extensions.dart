import 'package:decimal/decimal.dart';
import '../../infrastructure/database/app_database.dart';
import '../../application/sales/sales_service.dart' show SaleLineRequest;
import '../../application/purchases/purchase_service.dart' show PurchaseLineRequest;

extension InvoiceLineExtension on InvoiceLineEntity {
  Decimal get calculatedTotal => (quantity * unitPrice) - discount;
}

extension PurchaseLineExtension on PurchaseLineEntity {
  Decimal get calculatedTotal => quantity * unitPrice;
}

extension SaleLineRequestExtension on SaleLineRequest {
  Decimal get calculatedTotal => (quantity * unitPrice) - discount;
}

extension PurchaseLineRequestExtension on PurchaseLineRequest {
  Decimal get calculatedTotal => quantity * unitPrice;
}
