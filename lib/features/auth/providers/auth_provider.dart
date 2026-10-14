import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final availableUsersProvider = Provider<List<User>>((ref) {
  return const [
    User(
      id: 'usr-001',
      name: 'Budi Santoso',
      email: 'owner@warungbudi.com',
      pin: '1234',
      role: UserRole.owner,
      outletId: 'out-01',
    ),
    User(
      id: 'usr-002',
      name: 'Dewi Lestari',
      email: 'dewi@warungbudi.com',
      pin: '2222',
      role: UserRole.manager,
      outletId: 'out-01',
    ),
    User(
      id: 'usr-003',
      name: 'Andi Pratama',
      email: 'andi.kasir@warungbudi.com',
      pin: '1111',
      role: UserRole.cashier,
      outletId: 'out-01',
    ),
    User(
      id: 'usr-004',
      name: 'Siti Rahma',
      email: 'siti.kasir@warungbudi.com',
      pin: '3333',
      role: UserRole.cashier,
      outletId: 'out-01',
    ),
    User(
      id: 'usr-005',
      name: 'Chef Joko',
      email: 'joko@warungbudi.com',
      pin: '4444',
      role: UserRole.kitchen,
      outletId: 'out-01',
    ),
  ];
});

class AuthNotifier extends Notifier<User> {
  @override
  User build() {
    // Default active user is Andi Pratama (Cashier)
    final users = ref.watch(availableUsersProvider);
    return users.firstWhere((u) => u.pin == '1111', orElse: () => users.first);
  }

  bool switchUserByPin(String pin) {
    final users = ref.read(availableUsersProvider);
    final match = users.where((u) => u.pin == pin && u.isActive).firstOrNull;
    if (match != null) {
      state = match;
      return true;
    }
    return false;
  }

  void switchUser(User user) {
    state = user;
  }
}

final currentUserProvider = NotifierProvider<AuthNotifier, User>(AuthNotifier.new);
