import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/config/app_config.dart';

void main() {
  group('parseAppConfig', () {
    test('reports a missing key by name', () {
      final values = _validValues()..remove('APP_ENV');

      expect(
        () => parseAppConfig(values),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.key,
            'key',
            'APP_ENV',
          ),
        ),
      );
    });

    test('rejects unsupported environments', () {
      final values = _validValues()..['APP_ENV'] = 'qa';
      expect(() => parseAppConfig(values), throwsA(isA<AppConfigException>()));
    });

    test('requires HTTPS and a valid API origin', () {
      final values = _validValues()..['API_BASE_URL'] = 'http://localhost';
      expect(() => parseAppConfig(values), throwsA(isA<AppConfigException>()));
    });

    test('disallows logging in production', () {
      final values = _validValues()
        ..['APP_ENV'] = 'prod'
        ..['ENABLE_LOGGING'] = 'true';
      expect(() => parseAppConfig(values), throwsA(isA<AppConfigException>()));
    });

    for (final timeout in ['0', 'abc']) {
      test('rejects CONNECT_TIMEOUT_MS=$timeout', () {
        final values = _validValues()..['CONNECT_TIMEOUT_MS'] = timeout;
        expect(
          () => parseAppConfig(values),
          throwsA(isA<AppConfigException>()),
        );
      });
    }

    test('rejects unknown keys without echoing values', () {
      final values = _validValues()..['EXTRA'] = 'secret-token-fixture';
      try {
        parseAppConfig(values);
        fail('Expected config parsing to fail');
      } on AppConfigException catch (error) {
        expect(error.key, 'EXTRA');
        expect(error.toString(), isNot(contains('secret-token-fixture')));
      }
    });

    test('parses valid development config', () {
      final config = parseAppConfig(_validValues());

      expect(config.environment, AppEnvironment.dev);
      expect(config.apiBaseUrl, Uri.parse('https://api.dev.base.example'));
      expect(config.enableLogging, isTrue);
      expect(config.connectTimeout, const Duration(milliseconds: 15000));
      expect(config.receiveTimeout, const Duration(milliseconds: 30000));
      expect(config.sendTimeout, const Duration(milliseconds: 30000));
    });

    test('parses UAT config', () {
      final values = _validValues()..['APP_ENV'] = 'uat';

      expect(parseAppConfig(values).environment, AppEnvironment.uat);
    });
  });
}

Map<String, String> _validValues() => {
  'APP_ENV': 'dev',
  'API_BASE_URL': 'https://api.dev.base.example',
  'APP_NAME': 'Base Dev',
  'ENABLE_LOGGING': 'true',
  'CONNECT_TIMEOUT_MS': '15000',
  'RECEIVE_TIMEOUT_MS': '30000',
  'SEND_TIMEOUT_MS': '30000',
};
