import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final int id;
  final int orderId;
  final int senderId;
  final String senderName;
  final String text;
  final bool isRead;
  final DateTime? createdAt;

  const Message({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isRead = false,
    this.createdAt,
  });

  bool isMine(int myId) => senderId == myId;

  factory Message.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return Message(
      id: _int(json['id']),
      orderId: _int(json['orderId']),
      senderId: _int(json['senderId'] ?? sender?['id']),
      senderName: (sender?['username'] ?? 'User').toString(),
      text: (json['text'] ?? '').toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse('${json['createdAt']}')
          : null,
    );
  }

  @override
  List<Object?> get props => [id, isRead];

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
}
