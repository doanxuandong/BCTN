import '../../models/user_profile.dart';

class SearchNotification {
  final String id;
  final String receiverId;
  final String receiverName;
  final String senderId;
  final String senderName;
  final UserAccountType searchedType;
  final String searchCriteria;
  final String status; // 'pending', 'accepted', 'rejected'
  final bool read;
  final DateTime createdAt;
  final DateTime? respondedAt;

  SearchNotification({
    required this.id,
    required this.receiverId,
    required this.receiverName,
    required this.senderId,
    required this.senderName,
    required this.searchedType,
    required this.searchCriteria,
    required this.status,
    required this.read,
    required this.createdAt,
    this.respondedAt,
  });

  factory SearchNotification.fromMap(Map<String, dynamic> map) {
    return SearchNotification(
      id: map['id'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      searchedType: _parseUserAccountType(map['searchedType']),
      searchCriteria: map['searchCriteria'] ?? '',
      status: map['status'] ?? 'pending',
      read: map['read'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      respondedAt: map['respondedAt'] != null ? _parseDateTime(map['respondedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'senderId': senderId,
      'senderName': senderName,
      'searchedType': searchedType.name,
      'searchCriteria': searchCriteria,
      'status': status,
      'read': read,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  SearchNotification copyWith({
    String? id,
    String? receiverId,
    String? receiverName,
    String? senderId,
    String? senderName,
    UserAccountType? searchedType,
    String? searchCriteria,
    String? status,
    bool? read,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return SearchNotification(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      searchedType: searchedType ?? this.searchedType,
      searchCriteria: searchCriteria ?? this.searchCriteria,
      status: status ?? this.status,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  /// Lấy text hiển thị cho loại tài khoản được tìm kiếm
  String get searchedTypeText {
    switch (searchedType) {
      case UserAccountType.designer:
        return 'Nhà thiết kế';
      case UserAccountType.contractor:
        return 'Chủ thầu';
      case UserAccountType.store:
        return 'Cửa hàng VLXD';
      default:
        return 'Người dùng';
    }
  }

  /// Lấy màu sắc cho loại tài khoản
  String get searchedTypeColor {
    switch (searchedType) {
      case UserAccountType.designer:
        return '#FF6B6B'; // Đỏ
      case UserAccountType.contractor:
        return '#4ECDC4'; // Xanh lá
      case UserAccountType.store:
        return '#45B7D1'; // Xanh dương
      default:
        return '#95A5A6'; // Xám
    }
  }

  /// Lấy text hiển thị cho trạng thái
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ phản hồi';
      case 'accepted':
        return 'Đã quan tâm';
      case 'rejected':
        return 'Không quan tâm';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy màu sắc cho trạng thái
  String get statusColor {
    switch (status) {
      case 'pending':
        return '#F39C12'; // Cam
      case 'accepted':
        return '#27AE60'; // Xanh lá
      case 'rejected':
        return '#E74C3C'; // Đỏ
      default:
        return '#95A5A6'; // Xám
    }
  }

  /// Kiểm tra xem thông báo có thể phản hồi không
  bool get canRespond => status == 'pending';

  /// Kiểm tra xem đã phản hồi chưa
  bool get hasResponded => status != 'pending';

  /// Lấy thời gian hiển thị
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

  static UserAccountType _parseUserAccountType(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'designer':
          return UserAccountType.designer;
        case 'contractor':
          return UserAccountType.contractor;
        case 'store':
          return UserAccountType.store;
        default:
          return UserAccountType.general;
      }
    }
    return UserAccountType.general;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
