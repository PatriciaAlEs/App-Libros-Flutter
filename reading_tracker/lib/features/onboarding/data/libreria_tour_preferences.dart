import 'package:shared_preferences/shared_preferences.dart';

enum LibreriaTourStatus { pending, completed, skipped }

class LibreriaTourPreferences {
  const LibreriaTourPreferences._();

  static const storageKey = 'libreria_tour_v1';

  static Future<LibreriaTourStatus> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(storageKey);
    return switch (value) {
      'completed' => LibreriaTourStatus.completed,
      'skipped' => LibreriaTourStatus.skipped,
      _ => LibreriaTourStatus.pending,
    };
  }

  static Future<void> save(LibreriaTourStatus status) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, status.name);
  }

  static Future<void> reset() => save(LibreriaTourStatus.pending);
}
