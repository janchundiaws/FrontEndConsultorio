class TransactionType {
  final String code;
  final String name;
  final String description;
  final String color;

  TransactionType({
    required this.code,
    required this.name,
    required this.description,
    required this.color,
  });

  factory TransactionType.fromJson(Map<String, dynamic> json) {
    return TransactionType(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'color': color,
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionType && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

class StatusOption {
  final String code;
  final String name;
  final String description;
  final String color;

  StatusOption({
    required this.code,
    required this.name,
    required this.description,
    required this.color,
  });

  factory StatusOption.fromJson(Map<String, dynamic> json) {
    return StatusOption(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'color': color,
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusOption && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
} 