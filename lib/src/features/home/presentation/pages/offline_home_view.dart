import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pristie/src/core/offline/sync/sync_dataset.dart';
import 'package:pristie/generated/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_empty_view.dart';
import 'package:pristie/src/shared/widgets/app_error_view.dart';
import 'package:pristie/src/shared/widgets/app_loading_view.dart';

import '../cubit/offline_home_cubit.dart';
import '../cubit/offline_home_state.dart';

/// Read-only home surface backed by the local cache and sync status.
class OfflineHomeView extends StatelessWidget {
  const OfflineHomeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.home.title),
      actions: [
        IconButton(
          key: const Key('home.offlineRefresh'),
          tooltip: context.t.common.retry,
          onPressed: context.read<OfflineHomeCubit>().refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: BlocBuilder<OfflineHomeCubit, OfflineHomeState>(
      builder: (context, state) {
        final banner = _OfflineBanner(status: state.status);
        return Column(
          children: [
            if (state.status != SyncStatus.online) banner,
            Expanded(child: _content(context, state)),
          ],
        );
      },
    ),
  );

  Widget _content(BuildContext context, OfflineHomeState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView();
    }
    if (state.failure != null && state.items.isEmpty) {
      return AppErrorView(
        failure: state.failure!,
        onRetry: context.read<OfflineHomeCubit>().load,
      );
    }
    if (state.items.isEmpty) return const AppEmptyView();
    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return ListTile(
          key: ValueKey(item.id),
          title: Text(context.t.home.item(id: item.id)),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('home.offlineBanner'),
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label(context),
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context) => switch (status) {
    SyncStatus.offline => context.t.offline.offline,
    SyncStatus.stale => context.t.offline.stale,
    SyncStatus.syncing => context.t.offline.syncing,
    SyncStatus.pending => context.t.offline.pending,
    SyncStatus.conflict => context.t.offline.conflict,
    SyncStatus.needsAttention => context.t.offline.needsAttention,
    SyncStatus.online => '',
  };
}
