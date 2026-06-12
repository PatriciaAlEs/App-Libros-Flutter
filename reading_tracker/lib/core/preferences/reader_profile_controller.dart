import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReaderGreetingPreference {
  female(label: 'Lectora'),
  male(label: 'Lector'),
  neutral(label: 'Lectore'),
  custom(label: 'Personalizado');

  const ReaderGreetingPreference({required this.label});

  final String label;

  static ReaderGreetingPreference fromName(String? name) {
    return ReaderGreetingPreference.values.firstWhere(
      (preference) => preference.name == name,
      orElse: () => ReaderGreetingPreference.female,
    );
  }
}

class ReaderProfile {
  const ReaderProfile({
    this.name = '',
    this.greetingPreference = ReaderGreetingPreference.female,
    this.customGreeting = '',
    this.currentReadingBookId,
  });

  final String name;
  final ReaderGreetingPreference greetingPreference;
  final String customGreeting;
  final String? currentReadingBookId;

  ReaderProfile copyWith({
    String? name,
    ReaderGreetingPreference? greetingPreference,
    String? customGreeting,
    String? currentReadingBookId,
    bool clearCurrentReadingBookId = false,
  }) {
    return ReaderProfile(
      name: name ?? this.name,
      greetingPreference: greetingPreference ?? this.greetingPreference,
      customGreeting: customGreeting ?? this.customGreeting,
      currentReadingBookId: clearCurrentReadingBookId
          ? null
          : currentReadingBookId ?? this.currentReadingBookId,
    );
  }

  String get displayName => name.trim();

  String get fallbackGreeting {
    if (greetingPreference == ReaderGreetingPreference.custom) {
      final cleanCustom = customGreeting.trim();
      return cleanCustom.isEmpty
          ? ReaderGreetingPreference.female.label
          : cleanCustom;
    }
    return greetingPreference.label;
  }

  String homeGreeting(DateTime now) {
    final cleanName = displayName;
    if (cleanName.isEmpty) return 'Hola, $fallbackGreeting';

    final prefix = now.hour < 12
        ? 'Buenos días'
        : now.hour < 20
        ? 'Buenas tardes'
        : 'Buenas noches';
    return '$prefix, $cleanName';
  }
}

final readerProfileControllerProvider =
    StateNotifierProvider<ReaderProfileController, ReaderProfile>(
      (ref) => ReaderProfileController()..load(),
    );

class ReaderProfileController extends StateNotifier<ReaderProfile> {
  ReaderProfileController() : super(const ReaderProfile());

  static const _nameKey = 'reader_profile_name';
  static const _greetingKey = 'reader_profile_greeting';
  static const _customGreetingKey = 'reader_profile_custom_greeting';
  static const _currentReadingBookIdKey = 'reader_profile_current_reading_id';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    state = ReaderProfile(
      name: preferences.getString(_nameKey) ?? '',
      greetingPreference: ReaderGreetingPreference.fromName(
        preferences.getString(_greetingKey),
      ),
      customGreeting: preferences.getString(_customGreetingKey) ?? '',
      currentReadingBookId: preferences.getString(_currentReadingBookIdKey),
    );
  }

  Future<void> updateName(String name) async {
    state = state.copyWith(name: name);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, name);
  }

  Future<void> updateGreetingPreference(
    ReaderGreetingPreference preference,
  ) async {
    state = state.copyWith(greetingPreference: preference);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_greetingKey, preference.name);
  }

  Future<void> updateCustomGreeting(String greeting) async {
    state = state.copyWith(customGreeting: greeting);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_customGreetingKey, greeting);
  }

  Future<void> updateCurrentReadingBookId(String bookId) async {
    state = state.copyWith(currentReadingBookId: bookId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_currentReadingBookIdKey, bookId);
  }

  Future<void> clearCurrentReadingBookId() async {
    state = state.copyWith(clearCurrentReadingBookId: true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_currentReadingBookIdKey);
  }
}
