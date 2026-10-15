import 'package:ascend/features/profile/domain/profile_actions.dart';

class FakeProfileActions implements ProfileActions {
  final List<String> calls = [];

  @override
  Future<void> setName(String name) async => calls.add('setName:$name');
}