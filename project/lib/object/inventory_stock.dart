class InventoryStock {
  final int stockId;
  final String tenantId;
  final String code;
  final String name;
  final String category;
  final String unitMeasure;
  final String batchNumber;
  final String availableQuantity;
  final String reservedQuantity;
  final String totalQuantity;
  final String averageCost;
  final String expirationDate;
  final String warehouseLocation;
  final int minStock;
  final int maxStock;
  final String stockStatus;
  final String lastUpdated;

  InventoryStock({
    required this.stockId,
    required this.tenantId,
    required this.code,
    required this.name,
    required this.category,
    required this.unitMeasure,
    required this.batchNumber,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.totalQuantity,
    required this.averageCost,
    required this.expirationDate,
    required this.warehouseLocation,
    required this.minStock,
    required this.maxStock,
    required this.stockStatus,
    required this.lastUpdated,
  });

  factory InventoryStock.fromJson(Map<String, dynamic> json) {
    return InventoryStock(
      stockId: json['stock_id'] ?? 0,
      tenantId: json['tenant_id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      unitMeasure: json['unit_measure'] ?? '',
      batchNumber: json['batch_number'] ?? '',
      availableQuantity: json['available_quantity'] ?? '0.000',
      reservedQuantity: json['reserved_quantity'] ?? '0.000',
      totalQuantity: json['total_quantity'] ?? '0.000',
      averageCost: json['average_cost'] ?? '0.00',
      expirationDate: json['expiration_date'] ?? '',
      warehouseLocation: json['warehouse_location'] ?? '',
      minStock: json['min_stock'] ?? 0,
      maxStock: json['max_stock'] ?? 0,
      stockStatus: json['stock_status'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_id': stockId,
      'tenant_id': tenantId,
      'code': code,
      'name': name,
      'category': category,
      'unit_measure': unitMeasure,
      'batch_number': batchNumber,
      'available_quantity': availableQuantity,
      'reserved_quantity': reservedQuantity,
      'total_quantity': totalQuantity,
      'average_cost': averageCost,
      'expiration_date': expirationDate,
      'warehouse_location': warehouseLocation,
      'min_stock': minStock,
      'max_stock': maxStock,
      'stock_status': stockStatus,
      'last_updated': lastUpdated,
    };
  }
} 