import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book_search_result.dart';
import 'package:reading_tracker/features/stats/presentation/providers/annual_goal_cover_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('annual goal cover persists selected Open Library result', () async {
    final controller = AnnualGoalCoverController();

    await controller.selectBook(
      const BookSearchResult(
        title: 'The Left Hand of Darkness',
        author: 'Ursula K. Le Guin',
        coverUrl: 'https://covers.openlibrary.org/b/id/9255566-M.jpg',
        isbn: '9780441478125',
      ),
    );

    expect(controller.state?.title, 'The Left Hand of Darkness');
    expect(controller.state?.hasCover, true);

    final restored = AnnualGoalCoverController();
    await restored.load();

    expect(restored.state?.title, 'The Left Hand of Darkness');
    expect(restored.state?.author, 'Ursula K. Le Guin');
    expect(restored.state?.coverUrl, contains('covers.openlibrary.org'));
    expect(restored.state?.isbn, '9780441478125');
  });
}
