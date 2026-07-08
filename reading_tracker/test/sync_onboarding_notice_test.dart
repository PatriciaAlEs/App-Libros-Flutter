import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/analytics/readpp_analytics.dart';
import 'package:reading_tracker/features/auth/presentation/screens/account_transition_screen.dart';
import 'package:reading_tracker/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:reading_tracker/features/onboarding/presentation/providers/sync_coach_mark_controller.dart';
import 'package:reading_tracker/features/onboarding/presentation/providers/sync_onboarding_notice_controller.dart';
import 'package:reading_tracker/features/onboarding/presentation/widgets/sync_onboarding_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows sync notice once and persists dismissal', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SyncOnboardingNotice(child: Scaffold(body: Text('Inicio'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sincronizacion disponible'), findsOneWidget);
    expect(
      find.text('Tus lecturas siguen estando guardadas en este dispositivo.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('proteger y sincronizar tu biblioteca'),
      findsOneWidget,
    );
    expect(find.textContaining('opcional'), findsOneWidget);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizacion disponible'), findsNothing);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SyncOnboardingNoticeController.storageKey),
      true,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SyncOnboardingNotice(child: Scaffold(body: Text('Inicio'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sincronizacion disponible'), findsNothing);
  });

  testWidgets('primary CTA marks notice as seen and opens account transition', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const SyncOnboardingNotice(
            child: Scaffold(body: Text('Inicio')),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/account/transition') {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('Perfil sync')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver como activar sync'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil sync'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SyncOnboardingNoticeController.storageKey),
      true,
    );
    expect(preferences.getBool(SyncCoachMarkController.seenStorageKey), isNull);
  });

  testWidgets('primary CTA shows first sync coach mark once', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const SyncOnboardingNotice(
            child: Scaffold(body: Text('Inicio')),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/account/transition') {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const AccountTransitionScreen(),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver como activar sync'));
    await tester.pumpAndSettle();

    expect(find.text('Entra en Perfil'), findsOneWidget);
    expect(
      find.text('Inicia sesion para activar la sincronizacion.'),
      findsOneWidget,
    );
    expect(
      find.text('Tus lecturas seguiran guardadas en este dispositivo.'),
      findsOneWidget,
    );

    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(SyncCoachMarkController.seenStorageKey), true);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountTransitionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entra en Perfil'), findsNothing);
  });

  testWidgets('direct account transition does not show sync coach mark', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountTransitionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entra en Perfil'), findsNothing);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(SyncCoachMarkController.seenStorageKey), isNull);
  });

  test(
    'completing full onboarding marks sync notice as seen for new users',
    () async {
      SharedPreferences.setMockInitialValues({});

      final controller = OnboardingController(const ReadPpAnalytics.disabled());
      await controller.complete();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('onboarding_completed'), true);
      expect(
        preferences.getBool(SyncOnboardingNoticeController.storageKey),
        true,
      );
    },
  );
}
