import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  OnboardingRepository() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    // Migrate old onboarding format if necessary
    final oldCompleted = prefs.getBool('firstTime');
    if (oldCompleted != null) {
      await prefs.setBool('onboarding_completed', oldCompleted);
      await prefs.remove('firstTime');
    }
  }

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> setCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
  }
}
