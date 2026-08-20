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

  const Call({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    required this.calleeName,
    this.orderId,
    this.status = CallStatus.ringing,
  });

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
    );
  }

  @override
  List<Object?> get props => [id, status];

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
}
