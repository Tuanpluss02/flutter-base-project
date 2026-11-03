import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/src/app/app_router.gr.dart';
import 'package:base/src/app/injection.dart';
import 'package:base/src/core/presentation/paged_state.dart';
import 'package:base/generated/l10n/strings.g.dart';
import 'package:base/src/shared/widgets/app_button.dart';
import 'package:base/src/shared/widgets/app_empty_view.dart';
import 'package:base/src/shared/widgets/app_error_view.dart';
import 'package:base/src/shared/widgets/app_loading_view.dart';

import '../../domain/entities/demo_item.dart';
import '../cubit/home_cubit.dart';
import '../cubit/offline_home_cubit.dart';
import 'offline_home_view.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (getIt.isRegistered<OfflineHomeCubit>()) {
      return BlocProvider(
        create: (_) => getIt<OfflineHomeCubit>()..load(),
        child: const OfflineHomeView(),
      );
    }
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..loadFirst(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t.home.title),
      actions: [
        IconButton(
          key: const Key('home.settings'),
          tooltip: context.t.settings.title,
          onPressed: () => context.router.push(const SettingsRoute()),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: BlocBuilder<HomeCubit, PagedState<DemoItem>>(
      builder: (context, state) {
        if (state.isLoadingFirst && state.items.isEmpty) {
          return const AppLoadingView();
        }
        if (state.loadFirstFailure != null && state.items.isEmpty) {
          return AppErrorView(
            failure: state.loadFirstFailure!,
            onRetry: context.read<HomeCubit>().loadFirst,
          );
        }
        if (state.items.isEmpty) return const AppEmptyView();
        return ListView.builder(
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index < state.items.length) {
              final item = state.items[index];
              return ListTile(
                key: ValueKey(item.id),
                title: Text(context.t.home.item(id: item.id)),
              );
            }
            if (state.loadMoreFailure != null) {
              return AppErrorView(
                failure: state.loadMoreFailure!,
                onRetry: context.read<HomeCubit>().loadMore,
              );
            }
            if (state.loadFirstFailure != null) {
              return AppErrorView(
                failure: state.loadFirstFailure!,
                onRetry: context.read<HomeCubit>().refresh,
              );
            }
            if (!state.hasMore) return const SizedBox.shrink();
            return Center(
              child: AppButton(
                key: const Key('home.loadMore'),
                label: context.t.home.loadMore,
                isLoading: state.isLoadingMore,
                onPressed: context.read<HomeCubit>().loadMore,
              ),
            );
          },
        );
      },
    ),
  );
}
