import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_service.dart';
import '../../core/network/api_exception.dart';
import '../../data/api/delivery_api.dart';
import '../../data/models/order.dart';

enum LoadStatus { initial, loading, loaded, error }

class DeliveryState extends Equatable {
  final LoadStatus availableStatus;
  final List<Order> available;
  final LoadStatus mineStatus;
  final List<Order> mine;
  final Order? active;
  final bool sharing;
  final double progress; // route progress 0..1
  final List<LatLng> route;
  final String? error;

  const DeliveryState({
    this.availableStatus = LoadStatus.initial,
    this.available = const [],
    this.mineStatus = LoadStatus.initial,
    this.mine = const [],
    this.active,
    this.sharing = false,
    this.progress = 0,
    this.route = const [],
    this.error,
  });

  List<Order> get activeMine => mine
      .where((o) =>
          o.status == OrderStatus.pickedUp ||
          o.status == OrderStatus.onTheWay)
      .toList();

  double get todayEarnings => mine
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0.0, (s, o) => s + o.earning);

  int get completedCount =>
      mine.where((o) => o.status == OrderStatus.delivered).length;

  DeliveryState copyWith({
    LoadStatus? availableStatus,
    List<Order>? available,
    LoadStatus? mineStatus,
    List<Order>? mine,
    Order? active,
    bool? sharing,
    double? progress,
    List<LatLng>? route,
    String? error,
  }) =>
      DeliveryState(
        availableStatus: availableStatus ?? this.availableStatus,
        available: available ?? this.available,
        mineStatus: mineStatus ?? this.mineStatus,
        mine: mine ?? this.mine,
        active: active ?? this.active,
        sharing: sharing ?? this.sharing,
        progress: progress ?? this.progress,
        route: route ?? this.route,
        error: error,
      );

  @override
  List<Object?> get props => [
        availableStatus,
        available,
        mineStatus,
        mine,
        active,
        sharing,
        progress,
        route,
        error,
      ];
}

/// Manages the rider's available jobs, active deliveries and simulated live
/// location sharing (posts GPS to the backend so the customer sees movement).
class DeliveryCubit extends Cubit<DeliveryState> {
  DeliveryCubit(this._api, this._location) : super(const DeliveryState());

  final DeliveryApi _api;
  final LocationService _location;
  Timer? _pollTimer;
  UserLocation? _riderLoc;

  Future<UserLocation> _ensureLocation() async {
    _riderLoc ??= await _location.getLocation();
    return _riderLoc!;
  }

  /// Re-resolves the rider's device location (e.g. on pull-to-refresh).
  Future<void> refreshLocation() async {
    _riderLoc = await _location.getLocation();
  }

  Future<void> loadAvailable() async {
    emit(state.copyWith(availableStatus: LoadStatus.loading, error: null));
    try {
      final loc = await _ensureLocation();
      final orders =
          await _api.available(lat: loc.latitude, lng: loc.longitude);
      emit(state.copyWith(
          availableStatus: LoadStatus.loaded, available: orders));
    } on ApiException catch (e) {
      emit(state.copyWith(availableStatus: LoadStatus.error, error: e.message));
    }
  }

  Future<void> loadMine() async {
    emit(state.copyWith(mineStatus: LoadStatus.loading, error: null));
    try {
      final orders = await _api.myDeliveries();
      emit(state.copyWith(mineStatus: LoadStatus.loaded, mine: orders));
    } on ApiException catch (e) {
      emit(state.copyWith(mineStatus: LoadStatus.error, error: e.message));
    }
  }

  Future<Order?> accept(int orderId) async {
    try {
      final order = await _api.accept(orderId);
      await loadAvailable();
      await loadMine();
      emit(state.copyWith(active: order));
      return order;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return null;
    }
  }

  void setActive(Order order) =>
      emit(state.copyWith(active: order, progress: _progressFor(order.status)));

  Future<void> refreshActive(int orderId) async {
    try {
      final order = await _api.getOne(orderId);
      emit(state.copyWith(active: order));
    } on ApiException {
      // keep last known
    }
  }

  Future<bool> advanceStatus(int orderId, OrderStatus status) async {
    try {
      final order = await _api.updateStatus(orderId, status);
      emit(state.copyWith(
        active: order,
        mine: state.mine.map((o) => o.id == orderId ? order : o).toList(),
        progress: _progressFor(order.status),
      ));
      if (status == OrderStatus.delivered) stopSharing();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return false;
    }
  }

  /// While out for delivery, the backend advances the rider along the route.
  /// Here we fetch that route (for the map) and poll the order so the rider
  /// app sees itself move in real time.
  void startSharing(int orderId) {
    _pollTimer?.cancel();
    emit(state.copyWith(sharing: true));
    _fetchRoute(orderId);
    refreshActive(orderId); // immediate refresh
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refreshActive(orderId),
    );
  }

  Future<void> _fetchRoute(int orderId) async {
    try {
      final route = await _api.getRoute(orderId);
      emit(state.copyWith(route: route));
    } on ApiException {
      // Fallback: the map draws a direct line.
    }
  }

  void stopSharing() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (state.sharing) emit(state.copyWith(sharing: false));
  }

  static double _progressFor(OrderStatus s) => switch (s) {
        OrderStatus.pickedUp => 0.1,
        OrderStatus.onTheWay => 0.5,
        OrderStatus.delivered => 1.0,
        _ => 0.0,
      };

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
