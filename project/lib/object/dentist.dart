class Dentist {
  final int id;
  final String nombres;
  final String phone;
  final String email;
  final String especialidad;

  Dentist({
    required this.id,
    required this.nombres,
    required this.phone,
    required this.email,
    required this.especialidad,
  });

  factory Dentist.fromJson(Map<String, dynamic> json) {
    return Dentist(
      id: json['id'] ?? 0,
      nombres: json['nombres'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      especialidad: json['especialidad'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': nombres,
      'phone': phone,
      'email': email,
      'especialidad': especialidad,
    };
  }

  // Método para convertir a formato de dropdown
  Map<String, String> toDropdownFormat() {
    return {
      'codigo': id.toString(),
      'descripcion': '$nombres - $especialidad',
    };
  }

  @override
  String toString() {
    return 'Dentist(id: $id, nombres: $nombres, especialidad: $especialidad)';
  }
} 