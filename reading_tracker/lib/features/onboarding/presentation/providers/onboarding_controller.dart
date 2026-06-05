import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<bool>>(
      (ref) => OnboardingController(),
    );

class OnboardingController extends StateNotifier<AsyncValue<bool>> {
  OnboardingController() : super(const AsyncValue.loading()) {
    _load();
  }

  static const _storageKey = 'onboarding_completed';

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, true);
    state = const AsyncValue.data(true);
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    state = AsyncValue.data(preferences.getBool(_storageKey) ?? false);
  }
}
