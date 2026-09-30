class AppSecrets {
  const AppSecrets({
    required this.groqApiKey,
    required this.groqModel,
    required this.groqApiUrl,
  });

  final String groqApiKey;
  final String groqModel;
  final String groqApiUrl;

  static Future<AppSecrets> load() async => const AppSecrets(
        groqApiKey: String.fromEnvironment('GROQ_API_KEY'),
        groqModel: String.fromEnvironment('GROQ_MODEL'),
        groqApiUrl: String.fromEnvironment('GROQ_API_URL'),
      );
}
