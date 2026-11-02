import 'package:flutter/material.dart';

import '../../core/error/app_failure.dart';

import 'package:pristie/generated/l10n/strings.g.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      CancelledFailure() => null,
      NetworkFailure() => context.t.error.network,
      TimeoutFailure() => context.t.error.timeout,
      UnauthorizedFailure() => context.t.error.unauthorized,
      ForbiddenFailure() => context.t.error.forbidden,
      NotFoundFailure() => context.t.error.notFound,
      ConflictFailure() => context.t.error.conflict,
      ValidationFailure() => context.t.error.validation,
      RateLimitFailure() => context.t.error.rateLimit,
      ServerFailure() => context.t.error.server,
      PayloadTooLargeFailure() => context.t.error.payloadTooLarge,
      ParseFailure() => context.t.error.parse,
      LocalPersistenceFailure() => context.t.error.localPersistence,
      UnknownFailure() => context.t.error.unknown,
    };

    if (message == null) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(Theme.of(context));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: colors.danger),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: message,
            excludeSemantics: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppButton(label: context.t.common.retry, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
