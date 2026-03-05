class FeatureFlags {
  const FeatureFlags._();

  static const bool buildIntelligence = bool.fromEnvironment(
    'FEATURE_BUILD_INTELLIGENCE',
    defaultValue: true,
  );

  static const bool weeklyPlanner = bool.fromEnvironment(
    'FEATURE_WEEKLY_PLANNER',
    defaultValue: false,
  );

  static const bool economyAssistant = bool.fromEnvironment(
    'FEATURE_ECONOMY_ASSISTANT',
    defaultValue: false,
  );
}
