import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/observability/app_logger.dart';
import 'package:base/src/core/observability/redactor.dart';

void main() {
  group('Redactor', () {
    test('drops sensitive keys, headers, tokens, and PII', () {
      final input = <String, Object?>{
        'Authorization': 'Bearer secret_token',
        'cookie': 'session_id=xyz',
        'access_token': 'secret_jwt',
        'password': 'my_password',
        'query': 'search=sensitive',
        'body': {'username': 'john_doe', 'email': 'john@example.com'},
        'userId': 'usr_123',
        'routeParam': 'param_id',
        'event': 'user_login',
        'operation': 'authenticate',
        'statusCode': 200,
        'durationMs': 150,
      };

      final sanitized = Redactor.redact(input);

      expect(sanitized.containsKey('Authorization'), isFalse);
      expect(sanitized.containsKey('cookie'), isFalse);
      expect(sanitized.containsKey('access_token'), isFalse);
      expect(sanitized.containsKey('password'), isFalse);
      expect(sanitized.containsKey('query'), isFalse);
      expect(sanitized.containsKey('body'), isFalse);
      expect(sanitized.containsKey('userId'), isFalse);
      expect(sanitized.containsKey('routeParam'), isFalse);

      expect(sanitized['event'], 'user_login');
      expect(sanitized['operation'], 'authenticate');
      expect(sanitized['statusCode'], 200);
      expect(sanitized['durationMs'], 150);
    });

    test('drops nested maps and lists even under allowed keys', () {
      final input = <String, Object?>{
        'event': 'test_event',
        'operation': <String, String>{'nested': 'data'},
        'stage': <String>['alpha', 'beta'],
      };

      final sanitized = Redactor.redact(input);

      expect(sanitized['event'], 'test_event');
      expect(sanitized.containsKey('operation'), isFalse);
      expect(sanitized.containsKey('stage'), isFalse);
    });

    test('truncates strings longer than 200 characters', () {
      final longString = 'a' * 250;
      final input = <String, Object?>{'event': longString};

      final sanitized = Redactor.redact(input);

      expect((sanitized['event'] as String).length, 200);
      expect(sanitized['event'], 'a' * 200);
    });

    test('retains all 14 allowed keys', () {
      final input = <String, Object?>{
        'event': 'evt',
        'operation': 'op',
        'method': 'GET',
        'routeTemplate': '/api/items',
        'statusCode': 200,
        'durationMs': 50,
        'retryCount': 1,
        'correlationId': 'cid_123',
        'dataset': 'items',
        'syncState': 'synced',
        'appVersion': '1.0.0',
        'buildNumber': 1,
        'os': 'iOS',
        'stage': 'init',
      };

      final sanitized = Redactor.redact(input);

      expect(sanitized.length, 14);
      for (final key in Redactor.allowedLogKeys) {
        expect(sanitized.containsKey(key), isTrue);
      }
    });
  });

  group('AppLogger', () {
    test(
      'in prod suppresses debug and info but logs redacted warning and error',
      () {
        final loggedEntries = <(AppLogLevel, String, Map<String, Object?>)>[];

        final logger = AppLogger(
          enableDiagnostics: false,
          sink: (level, event, fields, {error, stackTrace}) {
            loggedEntries.add((level, event, fields));
          },
        );

        logger.debug(
          'debug_evt',
          fields: <String, Object?>{'password': '123', 'operation': 'debug_op'},
        );
        logger.info(
          'info_evt',
          fields: <String, Object?>{'token': 'abc', 'operation': 'info_op'},
        );

        expect(loggedEntries, isEmpty);

        logger.warning(
          'warn_evt',
          fields: <String, Object?>{
            'cookie': 'cookie_val',
            'operation': 'warn_op',
          },
        );
        expect(loggedEntries.length, 1);
        expect(loggedEntries[0].$1, AppLogLevel.warning);
        expect(loggedEntries[0].$2, 'warn_evt');
        expect(loggedEntries[0].$3.containsKey('cookie'), isFalse);
        expect(loggedEntries[0].$3['operation'], 'warn_op');
        expect(loggedEntries[0].$3['event'], 'warn_evt');

        logger.error(
          'err_evt',
          fields: <String, Object?>{
            'Authorization': 'Bearer x',
            'statusCode': 500,
          },
        );
        expect(loggedEntries.length, 2);
        expect(loggedEntries[1].$1, AppLogLevel.error);
        expect(loggedEntries[1].$2, 'err_evt');
        expect(loggedEntries[1].$3.containsKey('Authorization'), isFalse);
        expect(loggedEntries[1].$3['statusCode'], 500);
        expect(loggedEntries[1].$3['event'], 'err_evt');
      },
    );

    test(
      'when enableDiagnostics is true dispatches redacted debug and info',
      () {
        final loggedEntries = <(AppLogLevel, String, Map<String, Object?>)>[];

        final logger = AppLogger(
          enableDiagnostics: true,
          sink: (level, event, fields, {error, stackTrace}) {
            loggedEntries.add((level, event, fields));
          },
        );

        logger.debug(
          'debug_evt',
          fields: <String, Object?>{'secret': 'val', 'operation': 'debug_op'},
        );
        expect(loggedEntries.length, 1);
        expect(loggedEntries[0].$1, AppLogLevel.debug);
        expect(loggedEntries[0].$3.containsKey('secret'), isFalse);
        expect(loggedEntries[0].$3['operation'], 'debug_op');

        logger.info(
          'info_evt',
          fields: <String, Object?>{'password': 'val', 'statusCode': 200},
        );
        expect(loggedEntries.length, 2);
        expect(loggedEntries[1].$1, AppLogLevel.info);
        expect(loggedEntries[1].$3.containsKey('password'), isFalse);
        expect(loggedEntries[1].$3['statusCode'], 200);
      },
    );
  });
}
