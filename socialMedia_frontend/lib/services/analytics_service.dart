class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    // In a real application, this would send data to Firebase Analytics, Mixpanel, etc.
    print('📊 [ANALYTICS] Event: $eventName | Params: $parameters');
  }

  void logOnboardingStep(int stepIndex, String stepName) {
    logEvent('onboarding_step_viewed', parameters: {
      'step_index': stepIndex,
      'step_name': stepName,
    });
  }

  void logOnboardingCompleted() {
    logEvent('onboarding_completed');
  }
  
  void logOnboardingSkipped(int atStep) {
    logEvent('onboarding_skipped', parameters: {
      'step_index': atStep,
    });
  }
}
