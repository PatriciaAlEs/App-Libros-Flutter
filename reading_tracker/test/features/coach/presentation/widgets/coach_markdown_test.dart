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

  testWidgets('Markdown largo no desborda un ancho de 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: CoachMarkdown(
              data:
                  '## Plan de lectura\n\n'
                  '1. Empieza con diez minutos y una explicacion larga que deba ajustarse.\n'
                  '2. Continua con **constancia**, una palabra_muy_larga_sin_espacios_para_probar_el_viewport y una nota.\n'
                  '3. Revisa el habito cada semana.\n\n'
                  '```dart\nfinal tituloMuyLargo = "lectura";\n```',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Plan de lectura'), findsOneWidget);
    expect(find.bySemanticsLabel('Copiar bloque de cÃ³digo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
