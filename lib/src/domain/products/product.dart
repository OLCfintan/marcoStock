import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameFr;
  final String? nameEs;
  final String reference;
  final String? category;
  final String unit;
  final Decimal unitSize;
  final int unitsPerBox;
  final Decimal purchasePrice;
  final Decimal sellingPrice;
  final Decimal? tier2Price;
  final Decimal? tier3Price;
  final Decimal minimumStock;
  final Decimal baseMinimumStock;
  final Decimal magazinMinimumStock;
  final String? description;
  final String? imagePath;
  final String? packagingType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameFr,
    this.nameEs,
    required this.reference,
    this.category,
    required this.unit,
    required this.unitSize,
    this.unitsPerBox = 1,
    required this.purchasePrice,
    required this.sellingPrice,
    this.tier2Price,
    this.tier3Price,
    required this.minimumStock,
    required this.baseMinimumStock,
    required this.magazinMinimumStock,
    this.description,
    this.imagePath,
    this.packagingType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the product name for the given locale code.
  /// Falls back to [name] if no translation exists.
  String localizedName(String locale) {
    if (locale.startsWith('ar')) return nameAr ?? name;
    if (locale.startsWith('fr')) return nameFr ?? name;
    if (locale.startsWith('es')) return nameEs ?? name;
    return name;
  }

  /// Returns "{localizedName} {unit}" or "{localizedName} {unitSize}{unit}"
  String localizedLabel(String locale) {
    final n = localizedName(locale);
    return unitSize == Decimal.one ? '$n $unit' : '$n $unitSize$unit';
  }


  Product copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? nameFr,
    String? nameEs,
    String? reference,
    String? category,
    String? unit,
    Decimal? unitSize,
    int? unitsPerBox,
    Decimal? purchasePrice,
    Decimal? sellingPrice,
    Decimal? tier2Price,
    Decimal? tier3Price,
    Decimal? minimumStock,
    Decimal? baseMinimumStock,
    Decimal? magazinMinimumStock,
    String? description,
    String? imagePath,
    String? packagingType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameFr: nameFr ?? this.nameFr,
      nameEs: nameEs ?? this.nameEs,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      unitSize: unitSize ?? this.unitSize,
      unitsPerBox: unitsPerBox ?? this.unitsPerBox,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      tier2Price: tier2Price ?? this.tier2Price,
      tier3Price: tier3Price ?? this.tier3Price,
      minimumStock: minimumStock ?? this.minimumStock,
      baseMinimumStock: baseMinimumStock ?? this.baseMinimumStock,
      magazinMinimumStock: magazinMinimumStock ?? this.magazinMinimumStock,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      packagingType: packagingType ?? this.packagingType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, nameAr, nameFr, nameEs, reference, category, unit, purchasePrice, sellingPrice,
        tier2Price, tier3Price, minimumStock, baseMinimumStock, magazinMinimumStock, description, imagePath, packagingType,
        isActive, createdAt, updatedAt,
      ];
}
