import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/api/auth_api.dart';
import '../../data/models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final String? info;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.info,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    String? info,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        info: info,
      );

  @override
  List<Object?> get props => [status, user, error, info];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authApi, this._tokenStorage) : super(const AuthState());

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  int? get userId => state.user?.id;

  /// This app is only for riders.
  static const _role = 'RIDER';

  Future<void> loadSession() async {
    try {
      final token = await _tokenStorage.load();
      if (token == null || token.isEmpty) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      final user = await _authApi.profile();
      if (user.role != _role) {
        await _tokenStorage.clear();
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      await _tokenStorage.clear();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null, info: null));
    try {
      final result = await _authApi.login(email: email, password: password);
      if (result.user.role != _role) {
        await _tokenStorage.clear();
        emit(const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'This account is not a rider.',
        ));
        return false;
      }
      await _tokenStorage.save(result.token);
      emit(AuthState(status: AuthStatus.authenticated, user: result.user));
      return true;
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, error: e.message));
      return false;
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null, info: null));
    try {
      final message = await _authApi.register(
        username: username,
        email: email,
        password: password,
        phone: phone,
      );
      emit(AuthState(status: AuthStatus.unauthenticated, info: message));
      return message;
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, error: e.message));
      return null;
    }
  }

  Future<ForgotPasswordResult?> forgotPassword(String email) async {
    try {
      return await _authApi.forgotPassword(email);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return null;
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      return await _authApi.resetPassword(
        email: email,
        code: code,
        password: password,
      );
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return null;
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String phone,
    String? password,
  }) async {
    try {
      final user = await _authApi.updateProfile(
        username: username,
        phone: phone,
        password: (password == null || password.isEmpty) ? null : password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
