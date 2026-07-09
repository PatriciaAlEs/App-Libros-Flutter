class LibreriaFeatureFlags {
  const LibreriaFeatureFlags._();

  static const bool enabled = bool.fromEnvironment(
    'LIBRERIA_ENABLED',
    defaultValue: true,
  );
}
