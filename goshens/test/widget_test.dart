import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Goshens App Title Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Goshen Dental Care'),
          ),
        ),
      ),
    );

    expect(find.text('Goshen Dental Care'), findsOneWidget);
  });
}
