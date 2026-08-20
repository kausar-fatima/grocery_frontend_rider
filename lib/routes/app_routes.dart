class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const available = '/available';
  static const deliveries = '/deliveries';
  static const history = '/history';
  static const profile = '/profile';

  static const delivery = '/delivery'; // /delivery/:id
  static const chat = '/chat'; // /chat/:orderId?name=
  static const call = '/call';
  static const editProfile = '/edit-profile';
  static const notifications = '/notifications';
}
