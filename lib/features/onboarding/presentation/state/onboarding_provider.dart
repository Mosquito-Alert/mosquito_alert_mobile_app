import 'package:flutter/foundation.dart';
import '../../data/onboarding_repository.dart';

class OnboardingProvider extends ChangeNotifier {
  final OnboardingRepository repository;

  bool isLoading = true;
  bool isCompleted = false;

  OnboardingProvider({required this.repository}) {
    load();
  }

  Future<void> load() async {
    isCompleted = await repository.isCompleted();
    isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await repository.setCompleted(true);
    isCompleted = true;
    notifyListeners();
  }
}
