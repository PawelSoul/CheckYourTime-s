import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Czas (DateTime), o którym ma zadzwonić alarm, lub null gdy brak alarmu.
final alarmTargetProvider = StateProvider<DateTime?>((ref) => null);
