import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ascend/core/services/clock.dart';
import 'package:ascend/core/services/id_generator.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidGenerator());