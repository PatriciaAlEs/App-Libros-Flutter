import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../books/domain/entities/book_search_result.dart';

class AnnualGoalCover {
  const AnnualGoalCover({
    required this.title,
    this.author,
    this.coverUrl,
    this.isbn,
  });

  final String title;
  final String? author;
  final String? coverUrl;
  final String? isbn;

  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;
}

final annualGoalCoverControllerProvider =
    StateNotifierProvider<AnnualGoalCoverController, AnnualGoalCover?>(
      (ref) => AnnualGoalCoverController()..load(),
    );

class AnnualGoalCoverController extends StateNotifier<AnnualGoalCover?> {
  AnnualGoalCoverController() : super(null);

  static const _titleKey = 'annual_goal_cover_title';
  static const _authorKey = 'annual_goal_cover_author';
  static const _coverUrlKey = 'annual_goal_cover_url';
  static const _isbnKey = 'annual_goal_cover_isbn';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final title = preferences.getString(_titleKey)?.trim();
    if (title == null || title.isEmpty) {
      state = null;
      return;
    }

    state = AnnualGoalCover(
      title: title,
      author: preferences.getString(_authorKey),
      coverUrl: preferences.getString(_coverUrlKey),
      isbn: preferences.getString(_isbnKey),
    );
  }

  Future<void> selectBook(BookSearchResult book) async {
    final cover = AnnualGoalCover(
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
    );
    state = cover;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_titleKey, cover.title);
    await _setNullableString(preferences, _authorKey, cover.author);
    await _setNullableString(preferences, _coverUrlKey, cover.coverUrl);
    await _setNullableString(preferences, _isbnKey, cover.isbn);
  }

  Future<void> clear() async {
    state = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_titleKey);
    await preferences.remove(_authorKey);
    await preferences.remove(_coverUrlKey);
    await preferences.remove(_isbnKey);
  }

  Future<void> _setNullableString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    final cleanValue = value?.trim();
    if (cleanValue == null || cleanValue.isEmpty) {
      await preferences.remove(key);
      return;
    }
    await preferences.setString(key, cleanValue);
  }
}
