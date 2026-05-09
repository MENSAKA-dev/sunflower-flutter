class Customer {
  final int id;
  final String name;
  final String? nif;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? notes;

  const Customer({
    required this.id,
    required this.name,
    this.nif,
    this.address,
    this.city,
    this.postalCode,
    this.phone,
    this.email,
    this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    id:         j['id'] as int,
    name:       j['name'] as String,
    nif:        j['nif'] as String?,
    address:    j['address'] as String?,
    city:       j['city'] as String?,
    postalCode: j['postal_code'] as String?,
    phone:      j['phone'] as String?,
    email:      j['email'] as String?,
    notes:      j['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'nif':         nif,
    'address':     address,
    'city':        city,
    'postal_code': postalCode,
    'phone':       phone,
    'email':       email,
    'notes':       notes,
  };
}
