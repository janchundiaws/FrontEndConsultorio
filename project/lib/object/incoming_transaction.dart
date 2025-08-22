class IncomingTransaction {
  final int? incomingId;
  final String transactionNumber;
  final String transactionDate;
  final int supplierId;
  final String invoiceNumber;
  final String transactionType;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String notes;
  final String status;
  final List<IncomingDetail> details;

  IncomingTransaction({
    this.incomingId,
    required this.transactionNumber,
    required this.transactionDate,
    required this.supplierId,
    required this.invoiceNumber,
    required this.transactionType,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.notes,
    required this.status,
    required this.details,
  });

  factory IncomingTransaction.fromJson(Map<String, dynamic> json) {
    return IncomingTransaction(
      incomingId: json['incoming_id'],
      transactionNumber: json['transaction_number'] ?? '',
      transactionDate: json['transaction_date'] ?? '',
      supplierId: json['supplier_id'] ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      subtotal: double.tryParse(json['subtotal'] ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount'] ?? '0') ?? 0.0,
      total: double.tryParse(json['total'] ?? '0') ?? 0.0,
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
      details: json['details'] != null
          ? (json['details'] as List)
              .map((detail) => IncomingDetail.fromJson(detail))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (incomingId != null) 'incoming_id': incomingId,
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'transaction_type': transactionType,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
      'status': status,
      'details': details.map((detail) => detail.toJson()).toList(),
    };
  }
}

class CreateIncomingTransaction {
  final String transactionNumber;
  final String transactionDate;
  final int supplierId;
  final String invoiceNumber;
  final String transactionType;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String notes;
  final List<CreateIncomingDetail> details;

  CreateIncomingTransaction({
    required this.transactionNumber,
    required this.transactionDate,
    required this.supplierId,
    required this.invoiceNumber,
    required this.transactionType,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.notes,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'transaction_type': transactionType,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
      'details': details.map((detail) => detail.toJson()).toList(),
    };
  }
}

class IncomingDetail {
  final int? detailId;
  final int? incomingId;
  final int supplyId;
  final double quantity;
  final double unitCost;
  final double subtotal;
  final String batchNumber;
  final String expirationDate;
  final String warehouseLocation;
  final String notes;

  IncomingDetail({
    this.detailId,
    this.incomingId,
    required this.supplyId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    required this.batchNumber,
    required this.expirationDate,
    required this.warehouseLocation,
    required this.notes,
  });

  factory IncomingDetail.fromJson(Map<String, dynamic> json) {
    return IncomingDetail(
      detailId: json['detail_id'],
      incomingId: json['incoming_id'],
      supplyId: json['supply_id'] ?? 0,
      quantity: double.tryParse(json['quantity'] ?? '0') ?? 0.0,
      unitCost: double.tryParse(json['unit_cost'] ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal'] ?? '0') ?? 0.0,
      batchNumber: json['batch_number'] ?? '',
      expirationDate: json['expiration_date'] ?? '',
      warehouseLocation: json['warehouse_location'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (detailId != null) 'detail_id': detailId,
      if (incomingId != null) 'incoming_id': incomingId,
      'supply_id': supplyId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'subtotal': subtotal,
      'batch_number': batchNumber,
      'expiration_date': expirationDate,
      'warehouse_location': warehouseLocation,
      'notes': notes,
    };
  }
}

class CreateIncomingDetail {
  final int supplyId;
  final double quantity;
  final double unitCost;
  final double subtotal;
  final String batchNumber;
  final String expirationDate;
  final String warehouseLocation;
  final String notes;

  CreateIncomingDetail({
    required this.supplyId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    required this.batchNumber,
    required this.expirationDate,
    required this.warehouseLocation,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'supply_id': supplyId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'subtotal': subtotal,
      'batch_number': batchNumber,
      'expiration_date': expirationDate,
      'warehouse_location': warehouseLocation,
      'notes': notes,
    };
  }
} 