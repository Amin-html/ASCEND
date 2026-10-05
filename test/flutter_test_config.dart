import 'dart:async';

import 'package:drift/drift.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // В тестах бэкапа намеренно создаются две базы в памяти.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}