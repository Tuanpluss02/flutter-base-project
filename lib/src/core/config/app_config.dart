enum AppEnvironment { dev, uat, prod }

final class AppConfigException implements Exception {
  const AppConfigException(this.key, this.reason);

  final String key;
  final String reason;

  @override
  String toString() => 'Invalid app config for $key: $reason';
}

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
  });

  factory AppConfig.fromEnvironment() {
    const appEnvironment = String.fromEnvironment('APP_ENV');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const appName = String.fromEnvironment('APP_NAME');
    const enableLogging = String.fromEnvironment('ENABLE_LOGGING');
    const connectTimeout = String.fromEnvironment('CONNECT_TIMEOUT_MS');
    const receiveTimeout = String.fromEnvironment('RECEIVE_TIMEOUT_MS');
    const sendTimeout = String.fromEnvironment('SEND_TIMEOUT_MS');

    return parseAppConfig({
      'APP_ENV': appEnvironment,
      'API_BASE_URL': apiBaseUrl,
      'APP_NAME': appName,
      'ENABLE_LOGGING': enableLogging,
      'CONNECT_TIMEOUT_MS': connectTimeout,
      'RECEIVE_TIMEOUT_MS': receiveTimeout,
      'SEND_TIMEOUT_MS': sendTimeout,
    });
  }

  final AppEnvironment environment;
  final Uri apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
}

AppConfig parseAppConfig(Map<String, String> values) {
  const expectedKeys = {
    'APP_ENV',
    'API_BASE_URL',
    'APP_NAME',
    'ENABLE_LOGGING',
    'CONNECT_TIMEOUT_MS',
    'RECEIVE_TIMEOUT_MS',
    'SEND_TIMEOUT_MS',
  };

  final extraKeys = values.keys.toSet().difference(expectedKeys);
  if (extraKeys.isNotEmpty) {
    final extraKey = extraKeys.first;
    throw AppConfigException(extraKey, 'unexpected key');
  }

  for (final key in expectedKeys) {
    if (!values.containsKey(key) || values[key]!.isEmpty) {
      throw AppConfigException(key, 'required');
    }
  }

  final environment = switch (values['APP_ENV']) {
    'dev' => AppEnvironment.dev,
    'uat' => AppEnvironment.uat,
    'prod' => AppEnvironment.prod,
    _ => throw const AppConfigException('APP_ENV', 'unsupported environment'),
  };

  final apiBaseUrl = Uri.tryParse(values['API_BASE_URL']!);
  if (apiBaseUrl == null ||
      apiBaseUrl.scheme != 'https' ||
      apiBaseUrl.host.isEmpty ||
      apiBaseUrl.hasQuery ||
      apiBaseUrl.hasFragment) {
    throw const AppConfigException(
      'API_BASE_URL',
      'must be an HTTPS URL with a host and no query or fragment',
    );
  }

  final appName = values['APP_NAME']!;
  if (appName.trim().isEmpty) {
    throw const AppConfigException('APP_NAME', 'required');
  }

  final enableLogging = switch (values['ENABLE_LOGGING']) {
    'true' => true,
    'false' => false,
    _ => throw const AppConfigException(
      'ENABLE_LOGGING',
      'must be true or false',
    ),
  };
  if (environment == AppEnvironment.prod && enableLogging) {
    throw const AppConfigException('ENABLE_LOGGING', 'must be false in prod');
  }

  Duration parseTimeout(String key) {
    final milliseconds = int.tryParse(values[key]!);
    if (milliseconds == null || milliseconds <= 0) {
      throw AppConfigException(key, 'must be a positive integer');
    }
    return Duration(milliseconds: milliseconds);
  }

  return AppConfig(
    environment: environment,
    apiBaseUrl: apiBaseUrl,
    appName: appName,
    enableLogging: enableLogging,
    connectTimeout: parseTimeout('CONNECT_TIMEOUT_MS'),
    receiveTimeout: parseTimeout('RECEIVE_TIMEOUT_MS'),
    sendTimeout: parseTimeout('SEND_TIMEOUT_MS'),
  );
}
