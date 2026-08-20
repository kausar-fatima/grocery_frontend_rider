import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_exception.dart';
import '../../data/api/calls_api.dart';
import '../../data/models/call.dart';

class CallsState extends Equatable {
  final Call? active;
  final String? error;

  const CallsState({this.active, this.error});

  CallsState copyWith({Call? active, bool clearActive = false, String? error}) =>
      CallsState(active: clearActive ? null : (active ?? this.active), error: error);

  @override
  List<Object?> get props => [active, error];
}

/// Handles incoming call discovery and active-call signaling (no live audio).
class CallsCubit extends Cubit<CallsState> {
  CallsCubit(this._api) : super(const CallsState());

  final CallsApi _api;
  int myId = 0;
  Timer? _poll;

  bool get incoming => state.active != null && state.active!.calleeId == myId;

  /// Called after login: records the current user id and starts polling.
  void attach(int userId) {
    myId = userId;
    startPolling();
  }

  void detach() {
    _poll?.cancel();
    _poll = null;
    emit(const CallsState());
  }

  /// Starts background polling: discovers incoming calls and tracks the
  /// active call's status.
  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
  }

  Future<void> _tick() async {
    final active = state.active;
    if (active == null) {
      try {
        final calls = await _api.incoming();
        if (calls.isNotEmpty) emit(state.copyWith(active: calls.first));
      } on ApiException {/* transient */}
    } else {
      try {
        final call = await _api.getOne(active.id);
        if (call.status == CallStatus.ended ||
            call.status == CallStatus.declined) {
          emit(state.copyWith(clearActive: true));
        } else {
          emit(state.copyWith(active: call));
        }
      } on ApiException {/* transient */}
    }
  }

  Future<Call?> initiate({required int calleeId, int? orderId}) async {
    try {
      final call = await _api.initiate(calleeId: calleeId, orderId: orderId);
      emit(state.copyWith(active: call));
      return call;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return null;
    }
  }

  Future<void> answer() async {
    final call = state.active;
    if (call == null) return;
    try {
      final updated = await _api.answer(call.id);
      emit(state.copyWith(active: updated));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> decline() async {
    final call = state.active;
    if (call == null) return;
    try {
      await _api.decline(call.id);
    } on ApiException {/* ignore */}
    emit(state.copyWith(clearActive: true));
  }

  Future<void> end() async {
    final call = state.active;
    if (call == null) return;
    try {
      await _api.end(call.id);
    } on ApiException {/* ignore */}
    emit(state.copyWith(clearActive: true));
  }

  void dismiss() => emit(state.copyWith(clearActive: true));

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
