import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_db_provider.dart';
import '../../../data/db/daos/sessions_dao.dart';

/// Ostatnie sesje (zakończone) z ostatnich 30 dni – do osi czasu na ekranie Timera.
final recentSessionsProvider =
    StreamProvider.autoDispose<List<SessionWithTask>>((ref) {
  final dao = ref.watch(sessionsDaoProvider);
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 30));
  final fromMs = from.millisecondsSinceEpoch;
  final toMs = now.millisecondsSinceEpoch + 1;
  return dao.watchSessionsWithTasksInRange(fromMs: fromMs, toMs: toMs);
});
