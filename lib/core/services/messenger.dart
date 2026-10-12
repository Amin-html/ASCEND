import 'package:flutter/material.dart';

/// Ключ для показа сообщений из мест без BuildContext
/// (например, уведомление о разблокированном достижении).
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
GlobalKey<ScaffoldMessengerState>();