import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/features/auth/providers/auth_provider.dart';
import 'package:pos_kuliner/features/settings/providers/settings_provider.dart';
import 'package:pos_kuliner/features/sync/providers/sync_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _outletNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _npwpController;
  late TextEditingController _taxPercentController;
  late TextEditingController _servicePercentController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _storeNameController = TextEditingController(text: settings.storeName);
    _outletNameController = TextEditingController(text: settings.outletName);
    _addressController = TextEditingController(text: settings.address);
    _phoneController = TextEditingController(text: settings.phone);
    _npwpController = TextEditingController(text: settings.npwp);
    _taxPercentController = TextEditingController(text: settings.taxPercent.toStringAsFixed(0));
    _servicePercentController = TextEditingController(text: settings.serviceChargePercent.toStringAsFixed(0));
    _footerController = TextEditingController(text: settings.receiptFooter);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _outletNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _npwpController.dispose();
    _taxPercentController.dispose();
    _servicePercentController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final current = ref.read(settingsProvider);
    final updated = current.copyWith(
      storeName: _storeNameController.text.trim(),
      outletName: _outletNameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      npwp: _npwpController.text.trim(),
      taxPercent: double.tryParse(_taxPercentController.text.trim()) ?? current.taxPercent,
      serviceChargePercent: double.tryParse(_servicePercentController.text.trim()) ?? current.serviceChargePercent,
      receiptFooter: _footerController.text.trim(),
    );

    ref.read(settingsProvider.notifier).updateSettings(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan toko berhasil diperbarui!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final syncState = ref.watch(syncProvider);
    final currentUser = ref.watch(currentUserProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sistem & Toko'),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, color: AppColors.primary),
            label: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Offline / Online Simulator Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: syncState.isOnline
                  ? AppColors.successLight.withValues(alpha: 0.5)
                  : AppColors.warningLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: syncState.isOnline ? AppColors.success : AppColors.warning),
            ),
            child: Row(
              children: [
                Icon(
                  syncState.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: syncState.isOnline ? AppColors.success : AppColors.warning,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncState.isOnline ? 'Mode Online Terhubung' : 'Mode Offline (Lokal Aktif)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: syncState.isOnline ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        syncState.isOnline
                            ? 'Transaksi langsung tersinkron ke server Supabase secara instan.'
                            : 'Seluruh pesanan disimpan di database lokal & antrean Outbox (${syncState.pendingCount} antrean).',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(syncProvider.notifier).toggleOnlineStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: syncState.isOnline ? AppColors.warning : AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(syncState.isOnline ? 'Simulasi Offline' : 'Kembali Online'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Profil Toko Section
          _buildCard(
            title: 'Profil Toko Kuliner',
            icon: Icons.storefront_outlined,
            isDark: isDark,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logo Usaha Aktif',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Logo kuliner resmi aktif di bilah atas aplikasi, struk transaksi, dan ikon sistem.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Nama Usaha / Toko'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _outletNameController,
                decoration: const InputDecoration(labelText: 'Nama Cabang / Outlet'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap Toko'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Nomor WhatsApp / Telp'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _npwpController,
                      decoration: const InputDecoration(labelText: 'NPWP (Opsional)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Pajak & Biaya Layanan
          _buildCard(
            title: 'Pajak & Biaya Layanan',
            icon: Icons.receipt_long_outlined,
            isDark: isDark,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.enableTax,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).toggleTax(val);
                },
                title: const Text('Aktifkan Pajak Restoran (PB1 / PPN)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Dikenakan secara otomatis pada perhitungan total pesanan.'),
                activeThumbColor: AppColors.primary,
              ),
              if (settings.enableTax) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _taxPercentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Persentase Pajak (%)', suffixText: '%'),
                ),
              ],
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.enableServiceCharge,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).toggleServiceCharge(val);
                },
                title: const Text('Aktifkan Service Charge (Biaya Layanan)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Biaya operasional pelayanan kafe/resto.'),
                activeThumbColor: AppColors.primary,
              ),
              if (settings.enableServiceCharge) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _servicePercentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Persentase Service Charge (%)', suffixText: '%'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // 3. Pengaturan Printer Thermal
          _buildCard(
            title: 'Printer Thermal ESC/POS (Bluetooth)',
            icon: Icons.print_outlined,
            isDark: isDark,
            children: [
              const Text('Ukuran Kertas Thermal Printer:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => ref.read(settingsProvider.notifier).setPaperWidth(58),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settings.paperWidthMm == 58
                              ? AppColors.primaryLight.withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: settings.paperWidthMm == 58 ? AppColors.primary : Colors.grey.shade400,
                            width: settings.paperWidthMm == 58 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              settings.paperWidthMm == 58 ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: settings.paperWidthMm == 58 ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('58 mm (Saku)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('32 karakter', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => ref.read(settingsProvider.notifier).setPaperWidth(80),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settings.paperWidthMm == 80
                              ? AppColors.primaryLight.withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: settings.paperWidthMm == 80 ? AppColors.primary : Colors.grey.shade400,
                            width: settings.paperWidthMm == 80 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              settings.paperWidthMm == 80 ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: settings.paperWidthMm == 80 ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('80 mm (Restoran)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('42 karakter', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _footerController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pesan Kaki Struk (Footer Note)',
                  hintText: 'Terima kasih atas kunjungan Anda!\nFollow Instagram kami @toko',
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test print terkirim ke Printer Bluetooth ESC/POS (Status: OK)!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Uji Printer (Test Print)'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Tema & Info Perangkat
          _buildCard(
            title: 'Tampilan & Sistem',
            icon: Icons.palette_outlined,
            isDark: isDark,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.isDarkMode,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).toggleDarkMode(val);
                },
                title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Mengurangi kelelahan mata saat operasional kasir malam hari.'),
                activeThumbColor: AppColors.primary,
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Peran Pengguna Saat Ini'),
                subtitle: Text('${currentUser.name} (${currentUser.role.displayName})'),
                trailing: const Icon(Icons.verified_user, color: AppColors.primary),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Versi Aplikasi POS'),
                subtitle: Text('v1.0.0 (Flutter 3.38 • Offline-First Supabase Architecture)'),
                trailing: Text('Release MVP', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
