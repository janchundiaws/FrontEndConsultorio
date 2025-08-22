class MasterSupply {
  final int? supplyId;
  final String code;
  final String name;
  final String description;
  final String category;
  final String unitMeasure;
  final String presentation;
  final double unitCost;
  final double salePrice;
  final int minStock;
  final int maxStock;
  final String mainSupplier;
  final String warehouseLocation;
  final bool status;

  MasterSupply({
    this.supplyId,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.unitMeasure,
    required this.presentation,
    required this.unitCost,
    required this.salePrice,
    required this.minStock,
    required this.maxStock,
    required this.mainSupplier,
    required this.warehouseLocation,
    required this.status,
  });

  factory MasterSupply.fromJson(Map<String, dynamic> json) {
    return MasterSupply(
      supplyId: json['supply_id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      unitMeasure: json['unit_measure'] ?? '',
      presentation: json['presentation'] ?? '',
      unitCost: double.tryParse(json['unit_cost'] ?? '0.00') ?? 0.0,
      salePrice: double.tryParse(json['sale_price'] ?? '0.00') ?? 0.0,
      minStock: json['min_stock'] ?? 0,
      maxStock: json['max_stock'] ?? 0,
      mainSupplier: json['main_supplier'] ?? '',
      warehouseLocation: json['warehouse_location'] ?? '',
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (supplyId != null) 'supply_id': supplyId,
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'unit_measure': unitMeasure,
      'presentation': presentation,
      'unit_cost': unitCost,
      'sale_price': salePrice,
      'min_stock': minStock,
      'max_stock': maxStock,
      'main_supplier': mainSupplier,
      'warehouse_location': warehouseLocation,
      'status': status,
    };
  }
}

class CreateMasterSupply {
  final String code;
  final String name;
  final String description;
  final String category;
  final String unitMeasure;
  final String presentation;
  final double unitCost;
  final double salePrice;
  final int minStock;
  final int maxStock;
  final String mainSupplier;
  final String warehouseLocation;
  final bool status;

  CreateMasterSupply({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.unitMeasure,
    required this.presentation,
    required this.unitCost,
    required this.salePrice,
    required this.minStock,
    required this.maxStock,
    required this.mainSupplier,
    required this.warehouseLocation,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'unit_measure': unitMeasure,
      'presentation': presentation,
      'unit_cost': unitCost,
      'sale_price': salePrice,
      'min_stock': minStock,
      'max_stock': maxStock,
      'main_supplier': mainSupplier,
      'warehouse_location': warehouseLocation,
      'status': status,
    };
  }
}