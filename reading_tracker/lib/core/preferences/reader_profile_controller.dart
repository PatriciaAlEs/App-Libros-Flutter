import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reader_profile_text_validator.dart';

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

  String get displayName => ReaderProfileTextValidator.normalize(name);

  String get fallbackGreeting {
    if (greetingPreference == ReaderGreetingPreference.custom) {
      final cleanCustom = ReaderProfileTextValidator.normalize(customGreeting);
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
    final storedName = preferences.getString(_nameKey) ?? '';
    final storedCustomGreeting =
        preferences.getString(_customGreetingKey) ?? '';
    state = ReaderProfile(
      name: ReaderProfileTextValidator.normalize(storedName),
      greetingPreference: ReaderGreetingPreference.fromName(
        preferences.getString(_greetingKey),
      ),
      customGreeting: ReaderProfileTextValidator.normalize(
        storedCustomGreeting,
      ),
      currentReadingBookId: preferences.getString(_currentReadingBookIdKey),
    );
  }

  Future<String?> updateName(String name) async {
    final validation = ReaderProfileTextValidator.validate(name);
    if (!validation.isValid) return validation.error;
    state = state.copyWith(name: validation.value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, validation.value);
    return null;
  }

  Future<void> updateGreetingPreference(
    ReaderGreetingPreference preference,
  ) async {
    state = state.copyWith(greetingPreference: preference);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_greetingKey, preference.name);
  }

  Future<String?> updateCustomGreeting(String greeting) async {
    final normalized = ReaderProfileTextValidator.normalize(greeting);
    if (normalized.isNotEmpty) {
      final validation = ReaderProfileTextValidator.validate(
        normalized,
        fieldLabel: 'El saludo',
      );
      if (!validation.isValid) return validation.error;
    }
    state = state.copyWith(customGreeting: normalized);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_customGreetingKey, normalized);
    return null;
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
