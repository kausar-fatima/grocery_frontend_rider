import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

typedef PushTapHandler = void Function(Map<String, dynamic> data);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['type'] == 'incoming_call') {
    await _showIncomingCallStatic(message.data);
  }
  developer.log('Background push: ${message.messageId}', name: 'PushService');
}

Future<void> _showIncomingCallStatic(Map<String, dynamic> data) async {
  final params = CallKitParams(
    id: const Uuid().v4(),
    nameCaller: data['callerName']?.toString() ?? 'Unknown',
    appName: 'Healthy Mart',
    handle: data['callerName']?.toString() ?? 'Unknown',
    type: 0,
    extra: data,
    android: const AndroidParams(
      isCustomNotification: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
    ),
    ios: const IOSParams(
      handleType: 'generic',
      supportsVideo: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'default_channel',
    'General notifications',
    description: 'Order updates, delivery status, and offers.',
    importance: Importance.high,
  );

  Future<void> init({
    required void Function(String token) onToken,
    required PushTapHandler onTap,
  }) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _initLocalNotifications(onTap);

    FirebaseMessaging.onMessage.listen((message) async {
      if (message.data['type'] == 'incoming_call') {
        await _showIncomingCallStatic(message.data);
      } else {
        _showForegroundNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onTap(message.data),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) onTap(initialMessage.data);

    // This package uses a sealed class hierarchy for events (Dart 3): each
    // action (accept, decline, etc.) is its own concrete subtype, and the
    // accept event carries the CallKitParams — including `extra` — directly,
    // so no round-trip to activeCalls() is needed.
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event is CallEventActionCallAccept) {
        final extra = event.callKitParams.extra;
        if (extra != null) {
          onTap(Map<String, dynamic>.from(extra));
        }
      }
    });

    final token = await _messaging.getToken();
    if (token != null) onToken(token);
    _messaging.onTokenRefresh.listen(onToken);
  }

  Future<void> _initLocalNotifications(PushTapHandler onTap) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) onTap(_decodePayload(response.payload!));
      },
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  String _encodePayload(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('&');

  Map<String, dynamic> _decodePayload(String payload) {
    final result = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) result[parts[0]] = parts[1];
    }
    return result;
  }
}
