import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/features/gamification/domain/xp_engine.dart';

final xpEngineProvider = Provider<XpEngine>((ref) => const XpEngine());