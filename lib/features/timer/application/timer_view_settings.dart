import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyTimerViewMode = 'timer_view_mode';
const _keyAnalogHandsMode = 'analog_hands_mode';
const _keyAnalogNumbersStyle = 'analog_numbers_style';
const _keyAnalogNumbersVisible = 'analog_numbers_visible';

enum TimerViewMode { digital, analog }

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
  });

  final TimerViewMode viewMode;
  final AnalogHandsMode analogHandsMode;
  final AnalogNumbersStyle analogNumbersStyle;
  final bool analogNumbersVisible;

  TimerViewSettings copyWith({
    TimerViewMode? viewMode,
    AnalogHandsMode? analogHandsMode,
    AnalogNumbersStyle? analogNumbersStyle,
    bool? analogNumbersVisible,
  }) {
    return TimerViewSettings(
      viewMode: viewMode ?? this.viewMode,
      analogHandsMode: analogHandsMode ?? this.analogHandsMode,
      analogNumbersStyle: analogNumbersStyle ?? this.analogNumbersStyle,
      analogNumbersVisible: analogNumbersVisible ?? this.analogNumbersVisible,
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
    final viewMode = modeStr == 'analog' ? TimerViewMode.analog : TimerViewMode.digital;
    final handsInt = _prefs!.getInt(_keyAnalogHandsMode);
    final analogHandsMode =
        handsInt == 2 ? AnalogHandsMode.two : AnalogHandsMode.three;
    final numbersStr = _prefs!.getString(_keyAnalogNumbersStyle);
    final analogNumbersStyle =
        numbersStr == 'subtle' ? AnalogNumbersStyle.subtle : AnalogNumbersStyle.large;
    final numbersVisible = _prefs!.getBool(_keyAnalogNumbersVisible) ?? true;
    state = TimerViewSettings(
      viewMode: viewMode,
      analogHandsMode: analogHandsMode,
      analogNumbersStyle: analogNumbersStyle,
      analogNumbersVisible: numbersVisible,
    );
  }

  Future<void> setViewMode(TimerViewMode mode) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyTimerViewMode, mode == TimerViewMode.analog ? 'analog' : 'digital');
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
}
