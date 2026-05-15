import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reading_tracker/app.dart';

void main() {
  testWidgets('shows the books screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );
    await tester.pump();

    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('No books yet.'), findsOneWidget);
  });
}
