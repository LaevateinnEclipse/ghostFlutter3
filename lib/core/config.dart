/// Адрес сервера задаётся параметром сборки, а не константой в коде:
///
/// ```
/// flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
/// ```
library;

/// Базовый адрес REST API. Задаётся через `--dart-define=API_BASE_URL=...`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
const int connectTimeoutSeconds = 10;

const int receiveTimeoutSeconds = 15;

const int maxReadRetries = 3;

/// Пауза перед первым повтором, миллисекунды. Дальше пауза растёт:
/// base * 2^(номер попытки - 1).
const int retryBaseDelayMs = 400;

/// Принудительная задержка списков: `--dart-define=API_DEMO_DELAY_MS=1500`.
const apiDemoDelayMs = int.fromEnvironment('API_DEMO_DELAY_MS');

/// Принудительный код ошибки списков: `--dart-define=API_DEMO_FAIL=500`.
const apiDemoFail = int.fromEnvironment('API_DEMO_FAIL');
