import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/auth/auth_state.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/features/auth_placeholder/domain/usecases/login_use_case.dart';

import '../../support/fakes.dart';

void main() {
  group('LoginUseCase', () {
    late RecordingSessionTokenProvider tokens;
    late SessionService sessionService;
    late LoginUseCase useCase;

    setUp(() {
      tokens = RecordingSessionTokenProvider();
      sessionService = SessionService(tokens: tokens);
      useCase = LoginUseCase(sessionService);
    });

    tearDown(() async {
      await sessionService.dispose();
    });

    test(
      'writes exactly one demo session and authenticates without network',
      () async {
        final before = DateTime.now();

        final result = await useCase();

        expect(result, const Result<void>.ok(null));
        expect(tokens.writeCalls, 1);
        expect(tokens.writtenSession, isNotNull);
        expect(tokens.writtenSession!.accessToken, 'demo-access');
        expect(tokens.writtenSession!.refreshToken, 'demo-refresh');
        expect(tokens.writtenSession!.tokenType, 'Bearer');
        expect(
          tokens.writtenSession!.expiresAt.isAfter(before),
          isTrue,
          reason: 'The demo session must expire in the future',
        );
        expect(
          tokens.writtenSession!.expiresAt.isBefore(
            before.add(const Duration(hours: 1, minutes: 1)),
          ),
          isTrue,
        );
        expect(sessionService.currentAuthState, AuthState.authenticated);
        expect(sessionService.isRequestGateOpen, isTrue);
      },
    );

    test('surfaces local persistence failure and keeps auth locked', () async {
      tokens.writeResult = const Result.err(AppFailure.localPersistence());

      final result = await useCase();

      expect(result, const Result<void>.err(AppFailure.localPersistence()));
      expect(tokens.writeCalls, 1);
      expect(sessionService.currentAuthState, AuthState.locked);
      expect(sessionService.isRequestGateOpen, isFalse);
    });
  });
}
