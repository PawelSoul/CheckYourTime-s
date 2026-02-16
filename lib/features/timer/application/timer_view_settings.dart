import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyTimerViewMode = 'timer_view_mode';
const _keyAnalogMinuteHandVisible = 'analog_minute_hand_visible';
const _keyAnalogHourHandVisible = 'analog_hour_hand_visible';
const _keyAnalogNumbersStyle = 'analog_numbers_style';
const _keyAnalogNumbersVisible = 'analog_numbers_visible';
const _keyProgressBarVisible = 'timer_progress_bar_visible';
const _keyGlowVisible = 'timer_glow_visible';
const _keyPremiumProgressRingVisible = 'timer_premium_progress_ring_visible';
const _keyDigitalMillisecondsVisible = 'digital_milliseconds_visible';

enum TimerViewMode { digital, analogClassic, analogPremium }

/// Styl cyfer na tarczy analogowej.
enum AnalogNumbersStyle { large, subtle }

final timerViewSettingsProvider =
    StateNotifierProvider<TimerViewSettingsNotifier, TimerViewSettings>((ref) {
  return TimerViewSettingsNotifier();
});

class TimerViewSettings {
  const TimerViewSettings({
    this.viewMode = TimerViewMode.digital,
    this.analogMinuteHandVisible = true,
    this.analogHourHandVisible = true,
    this.analogNumbersStyle = AnalogNumbersStyle.large,
    this.analogNumbersVisible = true,
    this.progressBarVisible = false,
    this.glowVisible = false,
    this.premiumProgressRingVisible = true,
    this.digitalMillisecondsVisible = false,
  });

  final TimerViewMode viewMode;
  final bool analogMinuteHandVisible;
  final bool analogHourHandVisible;
  final AnalogNumbersStyle analogNumbersStyle;
  final bool analogNumbersVisible;
  final bool progressBarVisible;
  final bool glowVisible;
  final bool premiumProgressRingVisible;
  final bool digitalMillisecondsVisible;

  TimerViewSettings copyWith({
    TimerViewMode? viewMode,
    bool? analogMinuteHandVisible,
    bool? analogHourHandVisible,
    AnalogNumbersStyle? analogNumbersStyle,
    bool? analogNumbersVisible,
    bool? progressBarVisible,
    bool? glowVisible,
    bool? premiumProgressRingVisible,
    bool? digitalMillisecondsVisible,
  }) {
    return TimerViewSettings(
      viewMode: viewMode ?? this.viewMode,
      analogMinuteHandVisible: analogMinuteHandVisible ?? this.analogMinuteHandVisible,
      analogHourHandVisible: analogHourHandVisible ?? this.analogHourHandVisible,
      analogNumbersStyle: analogNumbersStyle ?? this.analogNumbersStyle,
      analogNumbersVisible: analogNumbersVisible ?? this.analogNumbersVisible,
      progressBarVisible: progressBarVisible ?? this.progressBarVisible,
      glowVisible: glowVisible ?? this.glowVisible,
      premiumProgressRingVisible: premiumProgressRingVisible ?? this.premiumProgressRingVisible,
      digitalMillisecondsVisible: digitalMillisecondsVisible ?? this.digitalMillisecondsVisible,
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
    final analogMinuteHandVisible = _prefs!.getBool(_keyAnalogMinuteHandVisible) ?? true;
    final analogHourHandVisible = _prefs!.getBool(_keyAnalogHourHandVisible) ?? true;
    final numbersStr = _prefs!.getString(_keyAnalogNumbersStyle);
    final analogNumbersStyle =
        numbersStr == 'subtle' ? AnalogNumbersStyle.subtle : AnalogNumbersStyle.large;
    final numbersVisible = _prefs!.getBool(_keyAnalogNumbersVisible) ?? true;
    final progressBarVisible = _prefs!.getBool(_keyProgressBarVisible) ?? false;
    final glowVisible = _prefs!.getBool(_keyGlowVisible) ?? false;
    final premiumProgressRingVisible = _prefs!.getBool(_keyPremiumProgressRingVisible) ?? true;
    final digitalMillisecondsVisible = _prefs!.getBool(_keyDigitalMillisecondsVisible) ?? false;
    state = TimerViewSettings(
      viewMode: viewMode,
      analogMinuteHandVisible: analogMinuteHandVisible,
      analogHourHandVisible: analogHourHandVisible,
      analogNumbersStyle: analogNumbersStyle,
      analogNumbersVisible: numbersVisible,
      progressBarVisible: progressBarVisible,
      glowVisible: glowVisible,
      premiumProgressRingVisible: premiumProgressRingVisible,
      digitalMillisecondsVisible: digitalMillisecondsVisible,
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

  Future<void> setAnalogMinuteHandVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyAnalogMinuteHandVisible, visible);
    state = state.copyWith(analogMinuteHandVisible: visible);
  }

  Future<void> setAnalogHourHandVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyAnalogHourHandVisible, visible);
    state = state.copyWith(analogHourHandVisible: visible);
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

  Future<void> setDigitalMillisecondsVisible(bool visible) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyDigitalMillisecondsVisible, visible);
    state = state.copyWith(digitalMillisecondsVisible: visible);
  }
}
