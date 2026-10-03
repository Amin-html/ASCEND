import 'package:uuid/uuid.dart';

abstract interface class IdGenerator {
  String newId();
}

class UuidGenerator implements IdGenerator {
  UuidGenerator();

  final Uuid _uuid = const Uuid();

  @override
  String newId() => _uuid.v4();
}