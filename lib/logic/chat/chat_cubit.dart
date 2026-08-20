import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_exception.dart';
import '../../data/api/chat_api.dart';
import '../../data/models/message.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final bool loading;
  final bool sending;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? loading,
    bool? sending,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: error,
      );

  @override
  List<Object?> get props => [messages, loading, sending, error];
}

/// Per-order chat. Polls the backend every few seconds for new messages.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._api, this.orderId) : super(const ChatState());

  final ChatApi _api;
  final int orderId;
  Timer? _poll;

  Future<void> start() async {
    emit(state.copyWith(loading: true));
    await _refresh();
    emit(state.copyWith(loading: false));
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final messages = await _api.forOrder(orderId);
      if (messages.length != state.messages.length) {
        emit(state.copyWith(messages: messages));
        await _api.markRead(orderId);
      }
    } on ApiException {
      // transient
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    emit(state.copyWith(sending: true));
    try {
      await _api.send(orderId, text.trim());
      await _refresh();
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    } finally {
      emit(state.copyWith(sending: false));
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
