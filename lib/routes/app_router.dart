import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/api/chat_api.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/chat/chat_cubit.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/call/call_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/delivery/active_delivery_screen.dart';
import '../presentation/screens/history/history_screen.dart';
import '../presentation/screens/main/main_shell.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/orders/available_orders_screen.dart';
import '../presentation/screens/orders/my_deliveries_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter(this._auth);
  final AuthCubit _auth;

  final _rootKey = GlobalKey<NavigatorState>();
  static const _public = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  };

  late final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(_auth.stream),
    redirect: _redirect,
    routes: _routes,
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = _auth.state.status;
    final loc = state.matchedLocation;
    final atSplash = loc == AppRoutes.splash;
    if (status == AuthStatus.unknown) return atSplash ? null : AppRoutes.splash;
    final loggedIn = status == AuthStatus.authenticated;
    final atPublic = _public.contains(loc);
    if (!loggedIn) return atPublic ? null : AppRoutes.login;
    if (atSplash || atPublic) return AppRoutes.available;
    return null;
  }

  List<RouteBase> get _routes => [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(
            path: AppRoutes.register,
            builder: (_, _) => const RegisterScreen()),
        GoRoute(
            path: AppRoutes.forgotPassword,
            builder: (_, _) => const ForgotPasswordScreen()),
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: _rootKey,
          builder: (_, _, shell) => MainShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.available,
                  builder: (_, _) => const AvailableOrdersScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.deliveries,
                  builder: (_, _) => const MyDeliveriesScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.history,
                  builder: (_, _) => const HistoryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.profile,
                  builder: (_, _) => const ProfileScreen()),
            ]),
          ],
        ),
        GoRoute(
          path: '${AppRoutes.delivery}/:id',
          parentNavigatorKey: _rootKey,
          builder: (_, state) => ActiveDeliveryScreen(
            orderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
        GoRoute(
          path: '${AppRoutes.chat}/:orderId',
          parentNavigatorKey: _rootKey,
          builder: (context, state) {
            final orderId =
                int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
            final name = state.uri.queryParameters['name'] ?? 'Customer';
            return BlocProvider(
              create: (_) => ChatCubit(context.read<ChatApi>(), orderId)..start(),
              child: ChatScreen(orderId: orderId, title: name),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.call,
          parentNavigatorKey: _rootKey,
          builder: (_, _) => const CallScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          parentNavigatorKey: _rootKey,
          builder: (_, _) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          parentNavigatorKey: _rootKey,
          builder: (_, _) => const NotificationsScreen(),
        ),
      ];
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
