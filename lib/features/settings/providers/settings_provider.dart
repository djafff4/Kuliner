import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store_settings_model.dart';

class SettingsNotifier extends Notifier<StoreSettings> {
  @override
  StoreSettings build() {
    return const StoreSettings();
  }

  void updateSettings(StoreSettings newSettings) {
    state = newSettings;
  }

  void toggleTax(bool enable) {
    state = state.copyWith(enableTax: enable);
  }

  void toggleServiceCharge(bool enable) {
    state = state.copyWith(enableServiceCharge: enable);
  }

  void setPaperWidth(int widthMm) {
    state = state.copyWith(paperWidthMm: widthMm);
  }

  void toggleDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, StoreSettings>(SettingsNotifier.new);
