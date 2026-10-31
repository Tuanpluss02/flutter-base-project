import 'package:flutter/material.dart';

import '../../l10n/strings.g.dart';
import '../theme/app_text_styles.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message ?? context.t.common.empty;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Semantics(
        container: true,
        label: text,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
