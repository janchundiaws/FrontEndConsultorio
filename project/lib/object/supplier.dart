class Supplier {
  final int? supplierId;
  final String code;
  final String name;
  final String businessName;
  final String taxId;
  final String address;
  final String phone;
  final String email;
  final String mainContact;

  Supplier({
    this.supplierId,
    required this.code,
    required this.name,
    required this.businessName,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.email,
    required this.mainContact,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierId: json['supplier_id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      businessName: json['business_name'] ?? '',
      taxId: json['tax_id'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      mainContact: json['main_contact'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (supplierId != null) 'supplier_id': supplierId,
      'code': code,
      'name': name,
      'business_name': businessName,
      'tax_id': taxId,
      'address': address,
      'phone': phone,
      'email': email,
      'main_contact': mainContact,
    };
  }
}

class CreateSupplier {
  final String code;
  final String name;
  final String businessName;
  final String taxId;
  final String address;
  final String phone;
  final String email;
  final String mainContact;

  CreateSupplier({
    required this.code,
    required this.name,
    required this.businessName,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.email,
    required this.mainContact,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'business_name': businessName,
      'tax_id': taxId,
      'address': address,
      'phone': phone,
      'email': email,
      'main_contact': mainContact,
    };
  }
} 