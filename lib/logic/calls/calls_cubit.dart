import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/calls/call_audio_service.dart';
import '../../core/network/api_exception.dart';
import '../../data/api/calls_api.dart';
import '../../data/models/call.dart';

class CallsState extends Equatable {
  final Call? active;
  final String? error;

  const CallsState({this.active, this.error});

  CallsState copyWith({
    Call? active,
    bool clearActive = false,
    String? error,
  }) => CallsState(
    active: clearActive ? null : (active ?? this.active),
    error: error,
  );

  @override
  List<Object?> get props => [active, error];
}

/// Handles incoming call discovery, call signaling, and now the live Agora
/// audio session for the active call.
class CallsCubit extends Cubit<CallsState> {
  CallsCubit(this._api, this._audio) : super(const CallsState());

  final CallsApi _api;
  final CallAudioService _audio;
  int myId = 0;
  Timer? _poll;

  bool get incoming => state.active != null && state.active!.calleeId == myId;

  void attach(int userId) {
    myId = userId;
    startPolling();
  }

  void detach() {
    _poll?.cancel();
    _poll = null;
    _audio.leaveChannel();
    emit(const CallsState());
  }

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
      } on ApiException {
        /* transient */
      }
    } else {
      try {
        final call = await _api.getOne(active.id);
        if (call.status == CallStatus.ended ||
            call.status == CallStatus.declined) {
          await _audio.leaveChannel();
          emit(state.copyWith(clearActive: true));
        } else {
          // Preserve channel/token from the original response — the polled
          // GET /calls/:id doesn't include them.
          emit(
            state.copyWith(
              active: call.copyWith(
                channelName: active.channelName,
                token: active.token,
              ),
            ),
          );
        }
      } on ApiException {
        /* transient */
      }
    }
  }

  /// Caller side: initiates the call and joins the Agora channel immediately.
  Future<Call?> initiate({required int calleeId, int? orderId}) async {
    try {
      final call = await _api.initiate(calleeId: calleeId, orderId: orderId);
      emit(state.copyWith(active: call));

      if (call.channelName != null && call.token != null) {
        await _audio.joinChannel(
          appId: const String.fromEnvironment('AGORA_APP_ID'),
          channelName: call.channelName!,
          token: call.token!,
          uid: myId,
        );
      }
      return call;
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return null;
    }
  }

  /// Callee side: accepts and joins the Agora channel with their own token.
  Future<void> answer() async {
    final call = state.active;
    if (call == null) return;
    try {
      final updated = await _api.answer(call.id);
      emit(state.copyWith(active: updated));

      if (updated.channelName != null && updated.token != null) {
        await _audio.joinChannel(
          appId: const String.fromEnvironment('AGORA_APP_ID'),
          channelName: updated.channelName!,
          token: updated.token!,
          uid: myId,
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }

  Future<void> decline() async {
    final call = state.active;
    if (call == null) return;
    try {
      await _api.decline(call.id);
    } on ApiException {
      /* ignore */
    }
    await _audio.leaveChannel();
    emit(state.copyWith(clearActive: true));
  }

  /// Called when a push notification (not polling) reveals a new incoming
  /// call — fetches it directly and sets it active immediately, rather than
  /// waiting for the next 3s poll tick.
  Future<void> fetchAndSetActive(int callId) async {
    if (state.active?.id == callId) return; // already showing it
    try {
      final call = await _api.getOne(callId);
      if (call.status == CallStatus.ringing) {
        emit(state.copyWith(active: call));
      }
    } on ApiException {
      /* will be picked up by next poll tick instead */
    }
  }

  Future<void> end() async {
    final call = state.active;
    if (call == null) return;
    try {
      await _api.end(call.id);
    } on ApiException {
      /* ignore */
    }
    await _audio.leaveChannel();
    emit(state.copyWith(clearActive: true));
  }

  void toggleMute(bool muted) => _audio.toggleMute(muted);
  void toggleSpeaker(bool on) => _audio.toggleSpeaker(on);

  void dismiss() {
    _audio.leaveChannel();
    emit(state.copyWith(clearActive: true));
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    _audio.leaveChannel();
    return super.close();
  }
}
