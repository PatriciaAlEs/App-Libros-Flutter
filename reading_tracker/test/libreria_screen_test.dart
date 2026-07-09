import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/libreria/presentation/models/libreria_route_arguments.dart';
import 'package:reading_tracker/features/libreria/presentation/models/libreria_view_state.dart';
import 'package:reading_tracker/features/libreria/presentation/providers/libreria_provider.dart';
import 'package:reading_tracker/features/libreria/presentation/screens/libreria_screen.dart';
import 'package:reading_tracker/features/libreria/presentation/widgets/libreria_entry_card.dart';
import 'package:reading_tracker/features/navigation/presentation/screens/main_navigation_screen.dart';

void main() {
  testWidgets('shows the honest initial LibrerIA experience', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('LibrerIA'), findsOneWidget);
    expect(find.text('Tu lectura, con más claridad'), findsOneWidget);
    expect(find.text('Tus próximos insights vivirán aquí'), findsOneWidget);
    expect(find.text('¿Qué estoy leyendo?'), findsOneWidget);

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.enabled, isFalse);
  });

  testWidgets('renders unavailable state without claiming data changed', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      state: const LibreriaViewState(status: LibreriaViewStatus.unavailable),
    );

    expect(find.text('LibrerIA no está disponible'), findsOneWidget);
    expect(
      find.text('Tus libros y sesiones siguen disponibles en ReadPp.'),
      findsOneWidget,
    );
  });

  testWidgets('renders error state', (tester) async {
    await _pumpScreen(
      tester,
      state: const LibreriaViewState(
        status: LibreriaViewStatus.error,
        message: 'Error de prueba seguro.',
      ),
    );

    expect(find.text('No pudimos preparar LibrerIA'), findsOneWidget);
    expect(find.text('Error de prueba seguro.'), findsOneWidget);
  });

  testWidgets('supports large text without throwing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: LibreriaScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tu lectura, con más claridad'), findsOneWidget);
  });

  testWidgets('opens LibrerIA as a contextual shell route', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(
            initialRoute: '/libreria',
            initialArguments: LibreriaRouteArguments(origin: 'Inicio'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibreriaScreen), findsOneWidget);
    expect(find.text('Volver a Inicio'), findsOneWidget);
  });

  testWidgets('entry card invokes navigation callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LibreriaEntryCard(onTap: () => tapped = true)),
      ),
    );

    await tester.tap(find.byType(LibreriaEntryCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  LibreriaViewState state = const LibreriaViewState(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [libreriaViewStateProvider.overrideWithValue(state)],
      child: const MaterialApp(home: LibreriaScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
