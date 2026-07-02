import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/analytics/readpp_analytics.dart';
import 'sync_onboarding_notice_controller.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<bool>>(
      (ref) => OnboardingController(ref.watch(readPpAnalyticsProvider)),
    );

class OnboardingController extends StateNotifier<AsyncValue<bool>> {
  OnboardingController(this._analytics) : super(const AsyncValue.loading()) {
    _load();
  }

  static const _storageKey = 'onboarding_completed';
  final ReadPpAnalytics _analytics;

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, true);
    await SyncOnboardingNoticeController.markSeen(preferences);
    await _analytics.trackOnboardingCompleted();
    state = const AsyncValue.data(true);
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    state = AsyncValue.data(preferences.getBool(_storageKey) ?? false);
  }
}
