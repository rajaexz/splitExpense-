import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  
  final SharedPreferences _prefs;
  
  OnboardingService(this._prefs);
  
  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }
  
  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_onboardingCompletedKey, true);
  }
  
  /// Reset onboarding (useful for testing or if user wants to see it again)
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingCompletedKey);
  }
}

