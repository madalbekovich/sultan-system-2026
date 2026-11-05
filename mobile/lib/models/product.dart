enum UnitType { kg, pcs }

UnitType unitTypeFromJson(String value) =>
    value == 'PCS' ? UnitType.pcs : UnitType.kg;

String unitTypeToJson(UnitType unit) => unit == UnitType.pcs ? 'PCS' : 'KG';

extension UnitTypeLabel on UnitType {
  String get label => this == UnitType.pcs ? 'шт' : 'кг';
}

class Product {
  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unitType,
    required this.pricePerUnit,
    required this.isActive,
    this.weightGrams,
  });

  final int id;
  final int categoryId;
  final String name;
  final UnitType unitType;
  final double pricePerUnit;
  final bool isActive;

  /// Net weight of one unit, in grams. Null until filled in — older/new
  /// catalog entries without a weight just don't contribute to weight
  /// totals.
  final int? weightGrams;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        name: json['name'] as String,
        unitType: unitTypeFromJson(json['unit_type'] as String),
        pricePerUnit: double.parse(json['price_per_unit'].toString()),
        isActive: json['is_active'] as bool,
        weightGrams: json['weight_grams'] as int?,
      );

  Map<String, dynamic> toCreateJson() => {
        'category_id': categoryId,
        'name': name,
        'unit_type': unitTypeToJson(unitType),
        'price_per_unit': pricePerUnit,
        'is_active': isActive,
        'weight_grams': weightGrams,
      };
}
