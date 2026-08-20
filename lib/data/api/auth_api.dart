import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/app_user.dart';
import 'api_helpers.dart';

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult({required this.token, required this.user});
}

/// Result of a forgot-password request. [code] is the demo reset code the
/// backend returns when no email server is configured (null in production).
class ForgotPasswordResult {
  final String message;
  final String? code;
  final String email;
  const ForgotPasswordResult({
    required this.message,
    required this.email,
    this.code,
  });
}

class AuthApi {
  AuthApi(this._client);
  final DioClient _client;

  Future<ForgotPasswordResult> forgotPassword(String email) async {
    try {
      final res = await _client.dio
          .post('/auth/forgot-password', data: {'email': email});
      ensureOk(res);
      final data = res.data as Map<String, dynamic>;
      return ForgotPasswordResult(
        message: (data['message'] ?? 'Reset code sent.').toString(),
        email: (data['email'] ?? email).toString(),
        code: data['code']?.toString(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'password': password,
      });
      ensureOk(res);
      return (res.data['message'] ?? 'Password updated.').toString();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      ensureOk(res);
      final data = res.data as Map<String, dynamic>;
      return AuthResult(
        token: data['access_token'] as String,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final res = await _client.dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'RIDER',
      });
      ensureOk(res);
      return (res.data['message'] ?? 'Registration submitted.').toString();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> profile() async {
    try {
      final res = await _client.dio.get('/auth/profile');
      ensureOk(res);
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> updateProfile({
    String? username,
    String? phone,
    String? password,
  }) async {
    try {
      final res = await _client.dio.patch('/auth/profile', data: {
        'username': ?username,
        'phone': ?phone,
        'password': ?password,
      });
      ensureOk(res);
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
