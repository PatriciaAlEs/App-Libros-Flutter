import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final syncCoachMarkControllerProvider =
    StateNotifierProvider<SyncCoachMarkController, AsyncValue<bool>>(
      (ref) => SyncCoachMarkController(),
    );

class SyncCoachMarkController extends StateNotifier<AsyncValue<bool>> {
  SyncCoachMarkController() : super(const AsyncValue.loading()) {
    _load();
  }

  static const seenStorageKey = 'sync_coach_mark_seen_v1';
  static const _requestedStorageKey = 'sync_coach_mark_requested_v1';

  static Future<void> requestFromSyncNotice(SharedPreferences preferences) {
    return preferences.setBool(_requestedStorageKey, true);
  }

  Future<void> request() async {
    final preferences = await SharedPreferences.getInstance();
    await requestFromSyncNotice(preferences);
    state = const AsyncValue.data(true);
  }

  Future<void> markShown() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(seenStorageKey, true);
    await preferences.remove(_requestedStorageKey);
    state = const AsyncValue.data(false);
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final wasRequested = preferences.getBool(_requestedStorageKey) ?? false;
    final wasSeen = preferences.getBool(seenStorageKey) ?? false;
    state = AsyncValue.data(wasRequested && !wasSeen);
  }
}
