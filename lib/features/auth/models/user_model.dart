enum UserRole {
  owner,
  manager,
  cashier,
  kitchen;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner / Pemilik';
      case UserRole.manager:
        return 'Manajer Outlet';
      case UserRole.cashier:
        return 'Kasir';
      case UserRole.kitchen:
        return 'Dapur / Koki';
    }
  }

  bool get canGiveDiscount => this == UserRole.owner || this == UserRole.manager;
  bool get canRefund => this == UserRole.owner || this == UserRole.manager;
  bool get canCloseShift => this == UserRole.owner || this == UserRole.manager || this == UserRole.cashier;
  bool get canManageMenu => this == UserRole.owner || this == UserRole.manager;
  bool get canAccessSettings => this == UserRole.owner;
}

class User {
  final String id;
  final String name;
  final String email;
  final String pin;
  final UserRole role;
  final String outletId;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.pin,
    required this.role,
    required this.outletId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'pin': pin,
    'role': role.name,
    'outlet_id': outletId,
    'is_active': isActive,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    pin: json['pin'] as String,
    role: UserRole.values.byName(json['role'] as String),
    outletId: json['outlet_id'] as String,
    isActive: json['is_active'] as bool? ?? true,
  );
}
