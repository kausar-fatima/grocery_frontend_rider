import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/order.dart';
import 'api_helpers.dart';

/// Rider delivery endpoints (available/assigned orders, status & location).
class DeliveryApi {
  DeliveryApi(this._client);
  final DioClient _client;

  Future<List<Order>> available({double? lat, double? lng}) async {
    try {
      final res = await _client.dio.get('/orders/available', queryParameters: {
        'lat': ?lat,
        'lng': ?lng,
      });
      ensureOk(res);
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Order>> myDeliveries() async {
    try {
      final res = await _client.dio.get('/orders/rider/mine');
      ensureOk(res);
      return (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> getOne(int id) async {
    try {
      final res = await _client.dio.get('/orders/$id');
      ensureOk(res);
      return Order.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// The road route (store → destination) the rider follows, for the map.
  Future<List<LatLng>> getRoute(int id) async {
    try {
      final res = await _client.dio.get('/orders/$id/route');
      ensureOk(res);
      final data = res.data;
      if (data is! List) return [];
      double d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
      return data
          .whereType<Map>()
          .map((p) => LatLng(d(p['lat']), d(p['lng'])))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> accept(int orderId) async {
    try {
      final res = await _client.dio.patch('/orders/$orderId/assign');
      ensureOk(res);
      return Order.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> updateStatus(int orderId, OrderStatus status) async {
    try {
      final res =
          await _client.dio.patch('/orders/$orderId/${status.apiValue}');
      ensureOk(res);
      return Order.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateLocation(int orderId, double lat, double lng) async {
    try {
      final res = await _client.dio
          .patch('/orders/$orderId/location', data: {'lat': lat, 'lng': lng});
      ensureOk(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
