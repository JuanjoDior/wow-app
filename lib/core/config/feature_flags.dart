class FeatureFlags {
  const FeatureFlags._();

  static const bool buildIntelligence = bool.fromEnvironment(
    'FEATURE_BUILD_INTELLIGENCE',
    defaultValue: true,
  );
}
