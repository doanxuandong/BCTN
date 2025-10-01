class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'friend_request', 'message', 'post_like', etc.
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data for specific actions

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderAvatar: map['senderAvatar'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String get iconPath {
    switch (type) {
      case 'friend_request':
        return 'assets/icons/friend_request.png';
      case 'message':
        return 'assets/icons/message.png';
      case 'post_like':
        return 'assets/icons/like.png';
      case 'post_comment':
        return 'assets/icons/comment.png';
      default:
        return 'assets/icons/notification.png';
    }
  }
}
