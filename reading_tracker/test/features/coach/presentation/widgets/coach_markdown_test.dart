import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/presentation/widgets/coach_markdown.dart';

void main() {
  testWidgets('renderiza Markdown basico, lista, cita y codigo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CoachMarkdown(
              data:
                  '# Titulo\n\n- Uno\n- Dos\n\n> Cita\n\n`inline`\n\n```dart\nprint("hola");\n```',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Titulo'), findsOneWidget);
    expect(find.text('Uno'), findsOneWidget);
    expect(find.text('Cita'), findsOneWidget);
    expect(find.text('inline'), findsOneWidget);
    expect(find.textContaining('print("hola")'), findsOneWidget);
    expect(find.bySemanticsLabel('Copiar bloque de código'), findsOneWidget);
  });

  testWidgets('copia solo el contenido del bloque de codigo', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoachMarkdown(data: '```dart\nfinal value = 1;\n```'),
        ),
      ),
    );

    await tester.tap(find.text('Copiar'));
    await tester.pump();

    expect(copiedText, contains('final value = 1;'));
    expect(copiedText, isNot(contains('```')));
    expect(find.text('Copiado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
