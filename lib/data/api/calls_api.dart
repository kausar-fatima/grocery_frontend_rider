import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/call.dart';
import 'api_helpers.dart';

class CallsApi {
  CallsApi(this._client);
  final DioClient _client;

  /// Uses fromInitiateResponse — backend returns { call, channelName, token }.
  Future<Call> initiate({required int calleeId, int? orderId}) async {
    try {
      final res = await _client.dio.post(
        '/calls',
        data: {'calleeId': calleeId, 'orderId': ?orderId},
      );
      ensureOk(res);
      return Call.fromInitiateResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Call>> incoming() async {
    try {
      final res = await _client.dio.get('/calls/incoming');
      ensureOk(res);
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(Call.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Call> getOne(int id) async {
    try {
      final res = await _client.dio.get('/calls/$id');
      ensureOk(res);
      return Call.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Also uses fromInitiateResponse — backend returns { call, channelName, token }.
  Future<Call> answer(int id) async {
    try {
      final res = await _client.dio.patch('/calls/$id/answer');
      ensureOk(res);
      return Call.fromInitiateResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Call> _patch(int id, String action) async {
    try {
      final res = await _client.dio.patch('/calls/$id/$action');
      ensureOk(res);
      return Call.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Call> decline(int id) => _patch(id, 'decline');
  Future<Call> end(int id) => _patch(id, 'end');
}
