/// Base URL of the AUREX Laravel API. Override for local development with
/// `--dart-define=AUREX_API_BASE_URL=http://127.0.0.1:8000/api`.
const String aurexApiBaseUrl = String.fromEnvironment(
  'AUREX_API_BASE_URL',
  defaultValue: 'https://api.aurex-performance.com/api',
);
