import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/location/location_service.dart';
import 'core/network/dio_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/api/auth_api.dart';
import 'data/api/calls_api.dart';
import 'data/api/chat_api.dart';
import 'data/api/delivery_api.dart';
import 'data/api/notifications_api.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/calls/calls_cubit.dart';
import 'logic/delivery/delivery_cubit.dart';
import 'logic/notifications/notifications_cubit.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'core/config/api_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.overrideBaseUrl = 'http://192.168.0.100:3000';
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final tokenStorage = TokenStorage(const FlutterSecureStorage());
  final dio = DioClient(tokenStorage);

  final chatApi = ChatApi(dio);
  final callsApi = CallsApi(dio);

  final auth = AuthCubit(AuthApi(dio), tokenStorage);
  final delivery = DeliveryCubit(DeliveryApi(dio), LocationService());
  final calls = CallsCubit(callsApi);
  final notifications = NotificationsCubit(NotificationsApi(dio));

  runApp(RiderApp(
    auth: auth,
    delivery: delivery,
    calls: calls,
    notifications: notifications,
    chatApi: chatApi,
  ));
}

class RiderApp extends StatelessWidget {
  final AuthCubit auth;
  final DeliveryCubit delivery;
  final CallsCubit calls;
  final NotificationsCubit notifications;
  final ChatApi chatApi;

  const RiderApp({
    super.key,
    required this.auth,
    required this.delivery,
    required this.calls,
    required this.notifications,
    required this.chatApi,
  });

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(auth);
    return RepositoryProvider.value(
      value: chatApi,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: delivery),
          BlocProvider.value(value: calls),
          BlocProvider.value(value: notifications),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listenWhen: (a, b) => a.status != b.status,
              listener: (context, state) {
                if (state.status == AuthStatus.authenticated &&
                    state.user != null) {
                  delivery.loadAvailable();
                  delivery.loadMine();
                  calls.attach(state.user!.id);
                  notifications.attach();
                } else if (state.status == AuthStatus.unauthenticated) {
                  calls.detach();
                  notifications.detach();
                }
              },
            ),
            // Present the call screen whenever a call becomes active.
            BlocListener<CallsCubit, CallsState>(
              listenWhen: (a, b) => (a.active == null) != (b.active == null),
              listener: (context, state) {
                if (state.active != null) {
                  appRouter.router.push(AppRoutes.call);
                }
              },
            ),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Rider — Healthy Mart',
            theme: AppTheme.lightTheme,
            routerConfig: appRouter.router,
          ),
        ),
      ),
    );
  }
}
