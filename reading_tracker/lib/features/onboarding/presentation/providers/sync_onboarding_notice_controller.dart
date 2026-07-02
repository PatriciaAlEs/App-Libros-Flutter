import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final syncOnboardingNoticeControllerProvider =
    StateNotifierProvider<SyncOnboardingNoticeController, AsyncValue<bool>>(
      (ref) => SyncOnboardingNoticeController(),
    );

class SyncOnboardingNoticeController extends StateNotifier<AsyncValue<bool>> {
  SyncOnboardingNoticeController() : super(const AsyncValue.loading()) {
    _load();
  }

  static const storageKey = 'sync_onboarding_notice_seen_v1';

  static Future<void> markSeen(SharedPreferences preferences) {
    return preferences.setBool(storageKey, true);
  }

  Future<void> dismiss() async {
    final preferences = await SharedPreferences.getInstance();
    await markSeen(preferences);
    state = const AsyncValue.data(false);
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    state = AsyncValue.data(!(preferences.getBool(storageKey) ?? false));
  }
}
