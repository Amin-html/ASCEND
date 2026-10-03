import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/app.dart';

void main() {
  testWidgets('App boots and shows ASCEND', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AscendApp()));
    expect(find.text('ASCEND'), findsOneWidget);
  });
}