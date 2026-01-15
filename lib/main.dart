import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: init DB (Hive / Drift / Isar)
  // await Database.init();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
