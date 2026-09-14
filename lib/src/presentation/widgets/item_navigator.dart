import 'package:flutter/material.dart';
import '../../domain/products/product.dart';
import 'product_profile_dialog.dart';

/// Global utility for navigating to item detail screens.
/// Centralizes the click-to-open behavior so every screen uses the same logic.
class ItemNavigator {
  /// Opens the product profile dialog. Call this from any onTap/onDoubleTap.
  static void openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductProfileDialog(product: product),
        fullscreenDialog: true,
      ),
    );
  }
}
