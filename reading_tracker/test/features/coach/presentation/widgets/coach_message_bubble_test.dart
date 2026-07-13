import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/theme/app_theme.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/presentation/widgets/coach_message_bubble.dart';

void main() {
  testWidgets('usuario y LibrerIA tienen alineacion y estilos distintos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              CoachMessageBubble(message: CoachMessage.user('Mensaje user')),
              CoachMessageBubble(
                message: CoachMessage.assistant('Mensaje assistant'),
              ),
            ],
          ),
        ),
      ),
    );

    final userText = find.text('Mensaje user');
    final assistantText = find.text('Mensaje assistant');
    final userRect = tester.getRect(userText);
    final assistantRect = tester.getRect(assistantText);
    expect(userRect.center.dx, greaterThan(assistantRect.center.dx));

    final userWidget = tester.widget<SelectableText>(userText);
    expect(userWidget.style?.color, AppTheme.light().colorScheme.onPrimary);
    expect(
      find.descendant(
        of: find.byType(CoachMessageBubble).last,
        matching: find.byIcon(Icons.auto_awesome_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
