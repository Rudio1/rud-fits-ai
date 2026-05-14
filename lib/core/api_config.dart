abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lab-rudfit-ai.e5zpsi.easypanel.host/api',
  );
}
