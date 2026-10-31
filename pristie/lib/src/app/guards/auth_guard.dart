import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:pristie/src/app/app_router.gr.dart';
import 'package:pristie/src/core/auth/auth_session_controller.dart';
import 'package:pristie/src/core/auth/auth_state.dart';

/// Central route guard synchronizing navigation decisions with authentication state.
class AuthGuard extends AutoRouteGuard
    with ChangeNotifier
    implements ReevaluateListenable {
  /// Creates an [AuthGuard] monitoring authentication lifecycle through [sessionController].
  AuthGuard({required this.sessionController}) {
    _currentAuthState = sessionController.currentAuthState;
    _subscription = sessionController.authStateStream.distinct().listen((
      state,
    ) {
      _currentAuthState = state;
      notifyListeners();
    });
  }

  /// The underlying authentication session controller.
  final AuthSessionController sessionController;

  late final StreamSubscription<AuthState> _subscription;
  AuthState _currentAuthState = AuthState.unknown;

  /// Returns current observed authentication state.
  AuthState get currentAuthState => _currentAuthState;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    var state = sessionController.currentAuthState;
    if (state == AuthState.unknown) {
      state = await sessionController.authStateStream.firstWhere(
        (s) => s != AuthState.unknown,
      );
    }
    _currentAuthState = state;

    final routeName = resolver.routeName;
    if (routeName == LoginRoute.name) {
      if (state == AuthState.authenticated) {
        if (resolver.isReevaluating) {
          resolver.next(false);
          scheduleMicrotask(() {
            router.replaceAll([const HomeRoute()]);
          });
        } else {
          router.replace(const HomeRoute());
          resolver.next(false);
        }
        return;
      }
      resolver.next(true);
      return;
    }

    // Protected routes (HomeRoute, SettingsRoute, etc.)
    if (state == AuthState.authenticated) {
      resolver.next(true);
    } else {
      if (resolver.isReevaluating) {
        resolver.next(false);
        scheduleMicrotask(() {
          router.replaceAll([const LoginRoute()]);
        });
      } else {
        router.replace(const LoginRoute());
        resolver.next(false);
      }
    }
  }
}
