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
    this.fit = BoxFit.contain,
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
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Container(
          width: size == double.infinity ? double.infinity : size,
          height: size == double.infinity ? double.infinity : size,
          color: Theme.of(context).colorScheme.surface,
          child: Image.file(
            File(product.imagePath!),
            fit: fit,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }
    return _fallbackIcon(context);
  }

  Widget _fallbackIcon(BuildContext context) {
    return Container(
      width: size == double.infinity ? null : size,
      height: size == double.infinity ? null : size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = size == double.infinity 
              ? (constraints.maxHeight < constraints.maxWidth ? constraints.maxHeight * 0.5 : constraints.maxWidth * 0.5) 
              : size * 0.5;
          return Icon(
            Icons.inventory_2_outlined,
            size: iconSize,
            color: Theme.of(context).colorScheme.primary,
          );
        },
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
    
    if (hasImage) {
      return ClipOval(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: Colors.white,
          child: Image.file(
            File(path!),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: hasImage ? null : Center(child: Icon(Icons.inventory_2_outlined, size: radius, color: Theme.of(context).colorScheme.primary)),
    );
  }
}
