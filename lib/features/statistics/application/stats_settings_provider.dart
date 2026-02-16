import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stats_widget_key.dart';

const _prefix = 'stats_widget_';

/// Ustawienia widoczności widgetów statystyk.
class StatsSettings {
  const StatsSettings({
    this.widgetsEnabled = const {},
  });

  final Map<StatsWidgetKey, bool> widgetsEnabled;

  bool isEnabled(StatsWidgetKey key) {
    return widgetsEnabled[key] ?? true; // domyślnie wszystkie włączone
  }

  StatsSettings copyWith({
    Map<StatsWidgetKey, bool>? widgetsEnabled,
  }) {
    return StatsSettings(
      widgetsEnabled: widgetsEnabled ?? this.widgetsEnabled,
    );
  }
}

final statsSettingsProvider =
    StateNotifierProvider<StatsSettingsNotifier, StatsSettings>((ref) {
  return StatsSettingsNotifier();
});

class StatsSettingsNotifier extends StateNotifier<StatsSettings> {
  StatsSettingsNotifier() : super(const StatsSettings()) {
    _load();
  }

  static SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final enabled = <StatsWidgetKey, bool>{};

    for (final key in StatsWidgetKey.values) {
      final prefKey = '$_prefix${key.name}';
      enabled[key] = _prefs!.getBool(prefKey) ?? true; // domyślnie włączone
    }

    state = StatsSettings(widgetsEnabled: enabled);
  }

  Future<void> setWidgetEnabled(StatsWidgetKey key, bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('$_prefix${key.name}', enabled);
    state = state.copyWith(
      widgetsEnabled: {...state.widgetsEnabled, key: enabled},
    );
  }
}
