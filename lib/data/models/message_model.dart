import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
}

class MessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final GeoPoint? location;
  final DateTime createdAt;
  final List<ReadReceipt> readBy;

  MessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.location,
    required this.createdAt,
    required this.readBy,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      location: data['location'] as GeoPoint?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: (data['readBy'] as List<dynamic>? ?? [])
          .where((e) => e is Map<String, dynamic>)
          .map((e) => ReadReceipt.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type.name,
      'content': content,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (location != null) 'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy.map((e) => e.toMap()).toList(),
    };
  }

  bool get isRead => readBy.isNotEmpty;
}

class ReadReceipt {
  final String userId;
  final DateTime timestamp;

  ReadReceipt({
    required this.userId,
    required this.timestamp,
  });

  factory ReadReceipt.fromMap(Map<String, dynamic> map) {
    return ReadReceipt(
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
