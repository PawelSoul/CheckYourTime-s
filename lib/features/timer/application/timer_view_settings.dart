import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyTimerViewMode = 'timer_view_mode';
const _keyAnalogHandsMode = 'analog_hands_mode';
const _keyAnalogNumbersStyle = 'analog_numbers_style';
const _keyAnalogNumbersVisible = 'analog_numbers_visible';
const _keyProgressBarVisible = 'timer_progress_bar_visible';
const _keyGlowVisible = 'timer_glow_visible';
const _keyPremiumProgressRingVisible = 'timer_premium_progress_ring_visible';
const _keyPremiumMinuteHandVisible = 'timer_premium_minute_hand_visible';

enum TimerViewMode { digital, analogClassic, analogPremium }

/// 2 = tylko min+sek, 3 = godz+min+sek.
enum AnalogHandsMode { two, three }

/// Styl cyfer na tarczy analogowej.
enum AnalogNumbersStyle { large, subtle }

extension AnalogHandsModeX on AnalogHandsMode {
  int get count => this == AnalogHandsMode.two ? 2 : 3;
}

final timerViewSettingsProvider =
    StateNotifierProvider<TimerViewSettingsNotifier, TimerViewSettings>((ref) {
  return TimerViewSettingsNotifier();
});

class TimerViewSettings {
  const TimerViewSettings({
    this.viewMode = TimerViewMode.digital,
    this.analogHandsMode = AnalogHandsMode.three,
    this.analogNumbersStyle = AnalogNumbersStyle.large,
    this.analogNumbersVisible = true,
    this.progressBarVisible = false,
    this.glowVisible = false,
    this.premiumProgressRingVisible = true,
    this.premiumMinuteHandVisible = true,
  });

  final TimerViewMode viewMode;
  final AnalogHandsMode analogHandsMode;
  final AnalogNumbersStyle analogNumbersStyle;
  final bool analogNumbersVisible;
  final bool progressBarVisible;
  final bool glowVisible;
  final bool premiumProgressRingVisible;
  final bool premiumMinuteHandVisible;

  TimerViewSettings copyWith({
    TimerViewMode? viewMode,
    AnalogHandsMode? analogHandsMode,
    AnalogNumbersStyle? analogNumbersStyle,
    bool? analogNumbersVisible,
    bool? progressBarVisible,
    bool? glowVisible,
    bool? premiumProgressRingVisible,
    bool? premiumMinuteHandVisible,
  }) {
    return TimerViewSettings(
      viewMode: viewMode ?? this.viewMode,
      analogHandsMode: analogHandsMode ?? this.analogHandsMode,
      analogNumbersStyle: analogNumbersStyle ?? this.analogNumbersStyle,
      analogNumbersVisible: analogNumbersVisible ?? this.analogNumbersVisible,
      progressBarVisible: progressBarVisible ?? this.progressBarVisible,
      glowVisible: glowVisible ?? this.glowVisible,
      premiumProgressRingVisible: premiumProgressRingVisible ?? this.premiumProgressRingVisible,
      premiumMinuteHandVisible: premiumMinuteHandVisible ?? this.premiumMinuteHandVisible,
    );
  }
}

class TimerViewSettingsNotifier extends StateNotifier<TimerViewSettings> {
  TimerViewSettingsNotifier() : super(const TimerViewSettings()) {
    _load();
  }

  static SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final modeStr = _prefs!.getString(_keyTimerViewMode);
    final viewMode = TimerViewSettingsNotifier._viewModeFromString(modeStr);
    final handsInt = _prefs!.getInt(_keyAnalogHandsMode);
    final analogHandsMode =
        handsInt == 2 ? AnalogHandsMode.two : AnalogHandsMode.three;
    final numbersStr = _prefs!.getString(_keyAnalogNumbersStyle);
    final analogNumbersStyle =
        numbersStr == 'subtle' ? AnalogNumbersStyle.subtle : AnalogNumbersStyle.large;
    final numbersVisible = _prefs!.getBool(_keyAnalogNumbersVisible) ?? true;
    final progressBarVisible = _prefs!.getBool(_keyProgressBarVisible) ?? false;
    final glowVisible = _prefs!.getBool(_keyGlowVisible) ?? false;
    final premiumProgressRingVisible = _prefs!.getBool(_keyPremiumProgressRingVisible) ?? true;
    final premiumMinuteHandVisible = _prefs!.getBool(_keyPremiumMinuteHandVisible) ?? true;
    state = TimerViewSettings(
      viewMode: viewMode,
      analogHandsMode: analogHandsMode,
      analogNumbersStyle: analogNumbersStyle,
      analogNumbersVisible: numbersVisible,
      progressBarVisible: progressBarVisible,
      glowVisible: glowVisible,
      premiumProgressRingVisible: premiumProgressRingVisible,
      premiumMinuteHandVisible: premiumMinuteHandVisible,
    );
  }

  static TimerViewMode _viewModeFromString(String? s) {
    switch (s) {
      case 'analog_classic':
        return TimerViewMode.analogClassic;
      case 'analog_premium':
      case 'analog': // legacy
        return TimerViewMode.analogPremium;
      default:
        return TimerViewMode.digital;
    }
  }

  static String _viewModeToString(TimerViewMode mode) {
    switch (mode) {
      case TimerViewMode.digital:
        return 'digital';
      case TimerViewMode.analogClassic:
        return 'analog_classic';
      case TimerViewMode.analogPremium:
        return 'analog_premium';
    }
  }

  Future<void> setViewMode(TimerViewMode mode) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyTimerViewMode, _viewModeToString(mode));
    state = state.copyWith(viewMode: mode);
  }

  Future<void> setAnalogHandsMode(AnalogHandsMode mode) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_keyAnalogHandsMode, mode.count);
    state = state.copyWith(analogHandsMode: mode);
  }

  Future<void> setAnalogNumbersStyle(AnalogNumbersStyle style) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _keyAnalogNumbersStyle,
      style == AnalogNumbersStyle.subtle ? 'subtle' : 'large',
    );
    state = state.copyWith(analogNumbersStyle: style);
  }

  Future<void> setAnalogNumbersVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyAnalogNumbersVisible, visible);
    state = state.copyWith(analogNumbersVisible: visible);
  }

  Future<void> setProgressBarVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyProgressBarVisible, visible);
    state = state.copyWith(progressBarVisible: visible);
  }

  Future<void> setGlowVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyGlowVisible, visible);
    state = state.copyWith(glowVisible: visible);
  }

  Future<void> setPremiumProgressRingVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyPremiumProgressRingVisible, visible);
    state = state.copyWith(premiumProgressRingVisible: visible);
  }

  Future<void> setPremiumMinuteHandVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyPremiumMinuteHandVisible, visible);
    state = state.copyWith(premiumMinuteHandVisible: visible);
  }
}
