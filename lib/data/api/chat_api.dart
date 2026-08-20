import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/message.dart';
import 'api_helpers.dart';

class ChatApi {
  ChatApi(this._client);
  final DioClient _client;

  Future<List<Message>> forOrder(int orderId) async {
    try {
      final res = await _client.dio.get('/messages/order/$orderId');
      ensureOk(res);
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(Message.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Message> send(int orderId, String text) async {
    try {
      final res = await _client.dio
          .post('/messages', data: {'orderId': orderId, 'text': text});
      ensureOk(res);
      return Message.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(int orderId) async {
    try {
      final res = await _client.dio.patch('/messages/order/$orderId/read');
      ensureOk(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
