// Modelo para Unidades de Medida
class UnitOfMeasure {
  final int unitId;
  final String name;

  UnitOfMeasure({
    required this.unitId,
    required this.name,
  });

  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) {
    return UnitOfMeasure(
      unitId: json['unit_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'name': name,
    };
  }

  @override
  String toString() => name;
}

// Modelo para Categorías de Suministros
class SupplyCategory {
  final int categoryId;
  final String name;

  SupplyCategory({
    required this.categoryId,
    required this.name,
  });

  factory SupplyCategory.fromJson(Map<String, dynamic> json) {
    return SupplyCategory(
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
    };
  }

  @override
  String toString() => name;
}