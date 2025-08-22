class ClinicalHistory {
  final int? id;
  final int patientId;
  final String observation;
  final String? fileName;
  final String? fileExtension;
  final String? fileBase64;
  final String? createdAt;
  final String? updatedAt;
  final int status;

  ClinicalHistory({
    this.id,
    required this.patientId,
    required this.observation,
    this.fileName,
    this.fileExtension,
    this.fileBase64,
    this.createdAt,
    this.updatedAt,
    this.status = 1,
  });

  factory ClinicalHistory.fromJson(Map<String, dynamic> json) {
    return ClinicalHistory(
      id: json['id'],
      patientId: json['patient_id'],
      observation: json['observation'],
      fileName: json['file_name'],
      fileExtension: json['file_extension'],
      fileBase64: json['file_base64'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      status: json['status'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'observation': observation,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_base64': fileBase64,
      'status': status,
    };
  }

  ClinicalHistory copyWith({
    int? id,
    int? patientId,
    String? observation,
    String? fileName,
    String? fileExtension,
    String? fileBase64,
    String? createdAt,
    String? updatedAt,
    int? status,
  }) {
    return ClinicalHistory(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      observation: observation ?? this.observation,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileBase64: fileBase64 ?? this.fileBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

class CreateClinicalHistory {
  final int patientId;
  final String observation;
  final String? fileName;
  final String? fileExtension;
  final String? fileBase64;

  CreateClinicalHistory({
    required this.patientId,
    required this.observation,
    this.fileName,
    this.fileExtension,
    this.fileBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'observation': observation,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_base64': fileBase64,
    };
  }
} 