class Appointment {
  final int? id;
  final int patientId;
  final int dentistId;
  final int officeId;
  final String appointmentTime;
  final String status;
  final String reason;
  final String? createdAt;
  final String? modifiedAt;

  Appointment({
    this.id,
    required this.patientId,
    required this.dentistId,
    required this.officeId,
    required this.appointmentTime,
    required this.status,
    required this.reason,
    this.createdAt,
    this.modifiedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      dentistId: json['dentist_id'],
      officeId: json['office_id'],
      appointmentTime: json['appointment_time'],
      status: json['status'],
      reason: json['reason'],
      createdAt: json['created_at'],
      modifiedAt: json['modified_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'dentist_id': dentistId,
      'office_id': officeId,
      'appointment_time': appointmentTime,
      'status': status,
      'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
    };
  }
}

class CreateAppointment {
  final int patientId;
  final int dentistId;
  final int officeId;
  final String appointmentTime;
  final String status;
  final String reason;

  CreateAppointment({
    required this.patientId,
    required this.dentistId,
    required this.officeId,
    required this.appointmentTime,
    required this.status,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'dentist_id': dentistId,
      'office_id': officeId,
      'appointment_time': appointmentTime,
      'status': status,
      'reason': reason,
    };
  }
} 