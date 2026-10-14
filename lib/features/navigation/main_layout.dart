import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/auth/presentation/pin_switch_dialog.dart';
import 'package:pos_kuliner/features/auth/providers/auth_provider.dart';
import 'package:pos_kuliner/features/menu/presentation/menu_management_screen.dart';
import 'package:pos_kuliner/features/pos/presentation/pos_screen.dart';
import 'package:pos_kuliner/features/reports/presentation/reports_screen.dart';
import 'package:pos_kuliner/features/settings/presentation/settings_screen.dart';
import 'package:pos_kuliner/features/settings/providers/settings_provider.dart';
import 'package:pos_kuliner/features/shift/presentation/shift_screen.dart';
import 'package:pos_kuliner/features/shift/providers/shift_provider.dart';
import 'package:pos_kuliner/features/sync/providers/sync_provider.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(NavigationIndexNotifier.new);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final currentUser = ref.watch(currentUserProvider);
    final shiftState = ref.watch(shiftProvider);
    final syncState = ref.watch(syncProvider);
    final settings = ref.watch(settingsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = const [
      PosScreen(),
      MenuManagementScreen(),
      ShiftScreen(),
      ReportsScreen(),
      SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 900;

        return Scaffold(
          // Universal Header across all pages
          appBar: AppBar(
            leadingWidth: isWideScreen ? 240 : null,
            leading: isWideScreen
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.storeName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                settings.outletName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            title: !isWideScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.storeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(settings.outletName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  )
                : null,
            actions: [
              // 1. Sync Status Badge (Online / Offline / Pending Count)
              InkWell(
                onTap: () {
                  ref.read(syncProvider.notifier).syncNow();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 10 : 8, vertical: 6),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: syncState.isOnline
                        ? (syncState.pendingCount > 0 ? AppColors.warningLight : AppColors.successLight)
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: syncState.isOnline
                          ? (syncState.pendingCount > 0 ? AppColors.warning : AppColors.success)
                          : AppColors.warning,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (syncState.isSyncing)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          syncState.isOnline ? Icons.circle : Icons.offline_bolt,
                          color: syncState.isOnline
                              ? (syncState.pendingCount > 0 ? AppColors.warning : AppColors.success)
                              : AppColors.warning,
                          size: 10,
                        ),
                      if (isWideScreen || !syncState.isOnline || syncState.pendingCount > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          syncState.isOnline
                              ? (syncState.pendingCount > 0 ? '${syncState.pendingCount} Tertunda' : 'Online')
                              : 'Offline (${syncState.pendingCount})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: syncState.isOnline
                                ? (syncState.pendingCount > 0 ? AppColors.warning : AppColors.success)
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 2. Active Shift Indicator Button
              if (shiftState.activeShift != null)
                InkWell(
                  onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(2),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 10 : 8, vertical: 6),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.point_of_sale, size: 14, color: AppColors.primary),
                        if (isWideScreen) ...[
                          const SizedBox(width: 6),
                          Text(
                            CurrencyFormatter.format(shiftState.activeShift!.expectedClosingCash),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 6),

              // 3. User Avatar & Quick PIN Switcher
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const PinSwitchDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 8 : 4, vertical: 4),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          currentUser.name.substring(0, 1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      if (isWideScreen) ...[
                        const SizedBox(width: 6),
                        Text(
                          currentUser.name.split(' ').first,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.swap_horiz, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          body: Row(
            children: [
              // Navigation Rail on Wide Screen
              if (isWideScreen)
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                    ref.read(navigationIndexProvider.notifier).setIndex(index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
                      label: Text('Kasir POS'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      selectedIcon: Icon(Icons.restaurant_menu, color: AppColors.primary),
                      label: Text('Kelola Menu'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.work_history_outlined),
                      selectedIcon: Icon(Icons.work_history, color: AppColors.primary),
                      label: Text('Shift & Kas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
                      label: Text('Laporan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings, color: AppColors.primary),
                      label: Text('Pengaturan'),
                    ),
                  ],
                ),

              // Main Body Content
              Expanded(
                child: screens[currentIndex],
              ),
            ],
          ),

          // Bottom Navigation Bar on Mobile
          bottomNavigationBar: !isWideScreen
              ? NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                    ref.read(navigationIndexProvider.notifier).setIndex(index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
                      label: 'Kasir',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      selectedIcon: Icon(Icons.restaurant_menu, color: AppColors.primary),
                      label: 'Menu',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.work_history_outlined),
                      selectedIcon: Icon(Icons.work_history, color: AppColors.primary),
                      label: 'Shift',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
                      label: 'Laporan',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings, color: AppColors.primary),
                      label: 'Pengaturan',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
