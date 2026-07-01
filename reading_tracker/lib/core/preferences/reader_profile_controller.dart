import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/sync/data/repositories/local_sync_tracker_provider.dart';
import '../../features/sync/domain/services/local_sync_tracker.dart';
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

class ReaderProfilePreferences {
  const ReaderProfilePreferences._();

  static const nameKey = 'reader_profile_name';
  static const greetingKey = 'reader_profile_greeting';
  static const customGreetingKey = 'reader_profile_custom_greeting';
  static const currentReadingBookIdKey = 'reader_profile_current_reading_id';

  static Future<ReaderProfile> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedName = preferences.getString(nameKey) ?? '';
    final storedCustomGreeting = preferences.getString(customGreetingKey) ?? '';
    return ReaderProfile(
      name: ReaderProfileTextValidator.normalize(storedName),
      greetingPreference: ReaderGreetingPreference.fromName(
        preferences.getString(greetingKey),
      ),
      customGreeting: ReaderProfileTextValidator.normalize(
        storedCustomGreeting,
      ),
      currentReadingBookId: preferences.getString(currentReadingBookIdKey),
    );
  }
}

final readerProfileControllerProvider =
    StateNotifierProvider<ReaderProfileController, ReaderProfile>(
      (ref) => ReaderProfileController(
        syncTracker: ref.watch(localSyncTrackerProvider),
      )..load(),
    );

class ReaderProfileController extends StateNotifier<ReaderProfile> {
  ReaderProfileController({LocalSyncTracker? syncTracker})
    : _syncTracker = syncTracker,
      super(const ReaderProfile());

  final LocalSyncTracker? _syncTracker;

  Future<void> load() async {
    state = await ReaderProfilePreferences.load();
  }

  Future<String?> updateName(String name) async {
    final validation = ReaderProfileTextValidator.validate(name);
    if (!validation.isValid) return validation.error;
    state = state.copyWith(name: validation.value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      ReaderProfilePreferences.nameKey,
      validation.value,
    );
    await _syncTracker?.trackProfileUpdated();
    return null;
  }

  Future<void> updateGreetingPreference(
    ReaderGreetingPreference preference,
  ) async {
    state = state.copyWith(greetingPreference: preference);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      ReaderProfilePreferences.greetingKey,
      preference.name,
    );
    await _syncTracker?.trackProfileUpdated();
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
    await preferences.setString(
      ReaderProfilePreferences.customGreetingKey,
      normalized,
    );
    await _syncTracker?.trackProfileUpdated();
    return null;
  }

  Future<void> updateCurrentReadingBookId(String bookId) async {
    state = state.copyWith(currentReadingBookId: bookId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      ReaderProfilePreferences.currentReadingBookIdKey,
      bookId,
    );
    await _syncTracker?.trackProfileUpdated();
  }

  Future<void> clearCurrentReadingBookId() async {
    state = state.copyWith(clearCurrentReadingBookId: true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(ReaderProfilePreferences.currentReadingBookIdKey);
    await _syncTracker?.trackProfileUpdated();
  }
}
