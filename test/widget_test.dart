import 'package:flutter_test/flutter_test.dart';

import 'package:clear_ui/main.dart';

void main() {
  testWidgets('CLEAR app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ClearApp());

    expect(find.text('CLEAR'), findsOneWidget);
  });
}
