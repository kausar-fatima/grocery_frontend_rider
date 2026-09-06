import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_exception.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../data/api/notifications_api.dart';
import '../../data/models/notification.dart';

class NotificationsState extends Equatable {
  final List<AppNotification> items;
  final int unread;
  final bool loading;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.unread = 0,
    this.loading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unread,
    bool? loading,
    String? error,
  }) => NotificationsState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    loading: loading ?? this.loading,
    error: error,
  );

  @override
  List<Object?> get props => [items, unread, loading, error];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._api, this._push) : super(const NotificationsState());

  final NotificationsApi _api;
  final PushNotificationService _push;
  Timer? _poll;

  /// Called on sign-in: fetch count, start polling, set up FCM + CallKit.
  /// [onCallData] is called when a push (or CallKit accept) carries call data
  /// — wire this to CallsCubit so an incoming push can trigger the same flow
  /// as the existing poll-based discovery.
  Future<void> attach({
    required void Function(Map<String, dynamic>) onPushTap,
  }) async {
    _refreshUnread();
    _poll?.cancel();
    _poll = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _refreshUnread(),
    );

    await _push.init(
      onToken: (token) => _api.registerDeviceToken(token).catchError((_) {}),
      onTap: (data) {
        onPushTap(data);
      },
    );
  }

  void detach() {
    _poll?.cancel();
    _poll = null;
    emit(const NotificationsState());
  }

  Future<void> _refreshUnread() async {
    try {
      final unread = await _api.unread();
      emit(state.copyWith(unread: unread));
    } on ApiException {
      /* transient */
    }
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _api.getAll();
      emit(
        state.copyWith(
          loading: false,
          items: items,
          unread: items.where((n) => !n.isRead).length,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  Future<void> markRead(int id) async {
    final items = state.items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    emit(
      state.copyWith(
        items: items,
        unread: items.where((n) => !n.isRead).length,
      ),
    );
    try {
      await _api.markRead(id);
    } on ApiException {
      /* keep optimistic */
    }
  }

  Future<void> markAllRead() async {
    final items = state.items.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(items: items, unread: 0));
    try {
      await _api.markAllRead();
    } on ApiException {
      /* keep optimistic */
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
