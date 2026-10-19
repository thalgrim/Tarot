import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tarot_scores/main.dart';

void main() {
  testWidgets('Home screen shows the app title', (WidgetTester tester) async {
    await tester.pumpWidget(const TarotApp());
    await tester.pump();

    expect(find.text('Tarot - Comptage de points'), findsWidgets);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
