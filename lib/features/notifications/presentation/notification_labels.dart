import 'package:ascend/core/utils/formatters.dart';

/// Варианты «за сколько минут напомнить».
const reminderPresets = <int>[0, 5, 10, 30, 60];

String reminderLabel(int minutes) =>
    minutes == 0 ? 'At start' : '${formatMinutes(minutes)} before';