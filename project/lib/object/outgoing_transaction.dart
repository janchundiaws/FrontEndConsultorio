class OutgoingTransaction {
  final int? outgoingId;
  final String transactionNumber;
  final String transactionDate;
  final String transactionType;
  final int patientId;
  final int dentistId;
  final String reason;
  final double total;
  final String status;
  final List<OutgoingDetail> details;

  OutgoingTransaction({
    this.outgoingId,
    required this.transactionNumber,
    required this.transactionDate,
    required this.transactionType,
    required this.patientId,
    required this.dentistId,
    required this.reason,
    required this.total,
    required this.status,
    required this.details,
  });

  factory OutgoingTransaction.fromJson(Map<String, dynamic> json) {
    return OutgoingTransaction(
      outgoingId: json['outgoing_id'],
      transactionNumber: json['transaction_number'] ?? '',
      transactionDate: json['transaction_date'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      patientId: json['patient_id'] ?? 0,
      dentistId: json['dentist_id'] ?? 0,
      reason: json['reason'] ?? '',
      total: double.tryParse (json['total'] ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      details: json['details'] != null
          ? (json['details'] as List)
              .map((detail) => OutgoingDetail.fromJson(detail))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (outgoingId != null) 'outgoing_id': outgoingId,
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate,
      'transaction_type': transactionType,
      'patient_id': patientId,
      'dentist_id': dentistId,
      'reason': reason,
      'total': total,
      'status': status,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}

class CreateOutgoingTransaction {
  final String transactionNumber;
  final String transactionDate;
  final String transactionType;
  final int patientId;
  final int dentistId;
  final String reason;
  final double total;
  final List<CreateOutgoingDetail> details;

  CreateOutgoingTransaction({
    required this.transactionNumber,
    required this.transactionDate,
    required this.transactionType,
    required this.patientId,
    required this.dentistId,
    required this.reason,
    required this.total,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction_number': transactionNumber,
      'transaction_date': transactionDate,
      'transaction_type': transactionType,
      'patient_id': patientId,
      'dentist_id': dentistId,
      'reason': reason,
      'total': total,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}

class OutgoingDetail {
  final int? detailId;
  final int? outgoingId;
  final int supplyId;
  final double quantity;
  final double unitCost;
  final double subtotal;
  final String batchNumber;
  final String notes;

  OutgoingDetail({
    this.detailId,
    this.outgoingId,
    required this.supplyId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    required this.batchNumber,
    required this.notes,
  });

  factory OutgoingDetail.fromJson(Map<String, dynamic> json) {
    return OutgoingDetail(
      detailId: json['detail_id'],
      outgoingId: json['outgoing_id'],
      supplyId: json['supply_id'] ?? 0,
      quantity: double.tryParse(json['quantity'] ?? '0') ?? 0.0,
      unitCost: double.tryParse(json['unit_cost'] ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal'] ?? '0') ?? 0.0,
      batchNumber: json['batch_number'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (detailId != null) 'detail_id': detailId,
      if (outgoingId != null) 'outgoing_id': outgoingId,
      'supply_id': supplyId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'subtotal': subtotal,
      'batch_number': batchNumber,
      'notes': notes,
    };
  }
}

class CreateOutgoingDetail {
  final int supplyId;
  final double quantity;
  final double unitCost;
  final double subtotal;
  final String batchNumber;
  final String notes;

  CreateOutgoingDetail({
    required this.supplyId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    required this.batchNumber,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'supply_id': supplyId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'subtotal': subtotal,
      'batch_number': batchNumber,
      'notes': notes,
    };
  }
}