import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.tap(find.text('Mas tarde'));
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
}
