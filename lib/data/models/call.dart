import 'package:equatable/equatable.dart';

enum CallStatus { ringing, accepted, declined, ended, missed, unknown }

extension CallStatusX on CallStatus {
  static CallStatus parse(String raw) => switch (raw.toUpperCase()) {
    'RINGING' => CallStatus.ringing,
    'ACCEPTED' => CallStatus.accepted,
    'DECLINED' => CallStatus.declined,
    'ENDED' => CallStatus.ended,
    'MISSED' => CallStatus.missed,
    _ => CallStatus.unknown,
  };
}

class Call extends Equatable {
  final int id;
  final int callerId;
  final int calleeId;
  final String callerName;
  final String calleeName;
  final int? orderId;
  final CallStatus status;

  /// Agora RTC channel name — present once the backend has generated it
  /// (on initiate/answer). Needed to actually join the audio call.
  final String? channelName;

  /// This device's own Agora token for [channelName]. Different for caller
  /// vs callee — each side gets their own from the backend.
  final String? token;

  const Call({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    required this.calleeName,
    this.orderId,
    this.status = CallStatus.ringing,
    this.channelName,
    this.token,
  });

  /// Parses the `{ call: {...}, channelName, token }` shape returned by
  /// POST /calls and PATCH /calls/:id/answer.
  factory Call.fromInitiateResponse(Map<String, dynamic> json) {
    final callJson = json['call'] as Map<String, dynamic>;
    return Call.fromJson(callJson).copyWith(
      channelName: json['channelName'] as String?,
      token: json['token'] as String?,
    );
  }

  /// Parses a bare call row (from GET /calls/incoming, GET /calls/:id,
  /// PATCH .../decline, PATCH .../end) — no channel/token in these.
  factory Call.fromJson(Map<String, dynamic> json) {
    final caller = json['caller'] as Map<String, dynamic>?;
    final callee = json['callee'] as Map<String, dynamic>?;
    return Call(
      id: _int(json['id']),
      callerId: _int(json['callerId'] ?? caller?['id']),
      calleeId: _int(json['calleeId'] ?? callee?['id']),
      callerName: (caller?['username'] ?? 'Caller').toString(),
      calleeName: (callee?['username'] ?? 'Callee').toString(),
      orderId: json['orderId'] == null ? null : _int(json['orderId']),
      status: CallStatusX.parse((json['status'] ?? '').toString()),
      channelName: json['channelName'] as String?,
      token: json['token'] as String?,
    );
  }

  Call copyWith({CallStatus? status, String? channelName, String? token}) =>
      Call(
        id: id,
        callerId: callerId,
        calleeId: calleeId,
        callerName: callerName,
        calleeName: calleeName,
        orderId: orderId,
        status: status ?? this.status,
        channelName: channelName ?? this.channelName,
        token: token ?? this.token,
      );

  @override
  List<Object?> get props => [id, status, channelName, token];

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
}
