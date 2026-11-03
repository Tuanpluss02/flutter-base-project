import 'package:flutter/material.dart';

import 'package:base/generated/l10n/strings.g.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: context.t.common.loading,
        excludeSemantics: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
