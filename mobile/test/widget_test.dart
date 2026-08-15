import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gametun/main.dart';

void main() {
  testWidgets('L\'app démarre sur le splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GameTunApp()));
    // Au premier frame, l'état d'auth est "inconnu" → écran splash affiché.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
