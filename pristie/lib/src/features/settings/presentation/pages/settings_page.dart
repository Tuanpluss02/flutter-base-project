import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/generated/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_button.dart';
import 'package:pristie/src/shared/widgets/app_error_view.dart';

import '../cubit/settings_cubit.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: getIt<SettingsCubit>(),
    child: const _SettingsContent(),
  );
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(context.t.settings.title)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  DropdownButtonFormField<ThemeMode>(
                    key: const Key('settings.themeMode'),
                    initialValue: state.themeMode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.t.settings.theme,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(context.t.settings.themeSystem),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(context.t.settings.themeLight),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(context.t.settings.themeDark),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsCubit>().changeTheme(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AppLocale>(
                    key: const Key('settings.locale'),
                    initialValue: state.locale,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.t.settings.language,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppLocale.en,
                        child: Text(context.t.settings.english),
                      ),
                      DropdownMenuItem(
                        value: AppLocale.vi,
                        child: Text(context.t.settings.vietnamese),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SettingsCubit>().changeLocale(value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    key: const Key('settings.logout'),
                    label: context.t.settings.logout,
                    isLoading: state.isLoggingOut,
                    onPressed: () => _confirmLogout(context),
                  ),
                  if (state.failure != null)
                    AppErrorView(failure: state.failure!),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.t.settings.logout),
        content: Text(dialogContext.t.settings.logoutConfirm),
        actions: [
          TextButton(
            key: const Key('settings.logoutCancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.t.common.cancel),
          ),
          TextButton(
            key: const Key('settings.logoutConfirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.t.settings.logout),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      await context.read<SettingsCubit>().logout();
    }
  }
}
