class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8086',
  );

  static const Duration timeout = Duration(seconds: 20);
}
