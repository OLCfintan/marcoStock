import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/products/product.dart';

/// Global reusable product image widget.
/// Checks [Product.imagePath] and renders the actual image if it exists on disk.
/// Falls back to a themed icon if no image is available.
class ProductImage extends StatelessWidget {
  final Product product;
  final double size;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.product,
    this.size = 48,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _hasImage {
    final path = product.imagePath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      final image = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Image.file(
          File(product.imagePath!),
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackIcon(context),
        ),
      );
      return SizedBox(width: size, height: size, child: image);
    }
    return _fallbackIcon(context);
  }

  Widget _fallbackIcon(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Circle avatar version for list tiles.
class ProductAvatarImage extends StatelessWidget {
  final Product product;
  final double radius;

  const ProductAvatarImage({
    super.key,
    required this.product,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final path = product.imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
    
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage ? null : Icon(Icons.inventory_2_outlined, size: radius),
    );
  }
}
