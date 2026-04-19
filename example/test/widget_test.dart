import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Verify Platform version', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Text('Platform Version: test')),
    );

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            widget.data?.startsWith('Platform Version:') == true,
      ),
      findsOneWidget,
    );
  });
}
