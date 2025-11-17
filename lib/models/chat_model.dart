import 'user_profile.dart';

enum ChatType {
  normal,      // Chat thông thường
  business,    // Chat từ tìm kiếm nghiệp vụ
}

class Chat {
  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final MessageType lastMessageType;
  final String? lastMessageSender;
  
  // Business chat fields
  final ChatType chatType;
  final UserAccountType? receiverType; // Loại tài khoản của người nhận (designer/contractor/store)
  final String? searchContext; // Tiêu chí tìm kiếm đã dùng (từ Smart Search)
  final bool isAutoMessage; // Chat được tạo từ auto message
  final String? pipelineId; // ID của pipeline nếu chat thuộc về một dự án
  final String? collaborationStatus; // Trạng thái hợp tác: "none", "requested", "accepted", "inProgress", "completed"
  final String? documentId; // Firestore document ID (có thể khác với normalized id) - dùng để query messages nếu khác

  Chat({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastMessageType = MessageType.text,
    this.lastMessageSender,
    this.chatType = ChatType.normal,
    this.receiverType,
    this.searchContext,
    this.isAutoMessage = false,
    this.pipelineId,
    this.collaborationStatus,
    this.documentId,
  });

  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    MessageType? lastMessageType,
    String? lastMessageSender,
    ChatType? chatType,
    UserAccountType? receiverType,
    String? searchContext,
    bool? isAutoMessage,
    String? pipelineId,
    String? collaborationStatus,
    String? documentId,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      chatType: chatType ?? this.chatType,
      receiverType: receiverType ?? this.receiverType,
      searchContext: searchContext ?? this.searchContext,
      isAutoMessage: isAutoMessage ?? this.isAutoMessage,
      pipelineId: pipelineId ?? this.pipelineId,
      collaborationStatus: collaborationStatus ?? this.collaborationStatus,
      documentId: documentId ?? this.documentId,
    );
  }
  
  bool get isBusinessChat => chatType == ChatType.business;

  String get initials => name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase();
  String get timeAgo => _formatTimeAgo(lastMessageTime);
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final bool isFromMe;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize; // bytes
  
  // Business message fields
  final Map<String, dynamic>? businessData; // Dữ liệu nghiệp vụ (quote, portfolio, catalog, etc.)
  final bool isAutoMessage; // Tin nhắn tự động từ search

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.isFromMe,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.businessData,
    this.isAutoMessage = false,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    bool? isFromMe,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    Map<String, dynamic>? businessData,
    bool? isAutoMessage,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      isFromMe: isFromMe ?? this.isFromMe,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      businessData: businessData ?? this.businessData,
      isAutoMessage: isAutoMessage ?? this.isAutoMessage,
    );
  }

  String get timeFormatted => _formatMessageTime(timestamp);
}

enum MessageType {
  // Phase 5 Enhancement: Material usage report
  materialUsageReport, // Báo cáo sử dụng vật liệu
  text,
  image,
  file,
  voice,
  sticker,
  // Business message types
  quoteRequest,      // Yêu cầu báo giá
  quoteResponse,     // Phản hồi báo giá
  portfolioShare,    // Chia sẻ portfolio (designer)
  projectTimeline,   // Timeline dự án (contractor)
  materialCatalog,   // Catalog vật liệu (store)
  appointmentRequest, // Yêu cầu hẹn gặp
  appointmentConfirm, // Xác nhận hẹn gặp
  // Pipeline collaboration types
  collaborationRequest, // Yêu cầu hợp tác
  collaborationAccept,  // Chấp nhận hợp tác
  designHandoff,        // Gửi thiết kế cho chủ thầu
  constructionPlanShare, // Gửi kế hoạch thi công cho cửa hàng
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

// Dữ liệu mẫu
class SampleChatData {
  static List<Chat> get chats => [
    Chat(
      id: '1',
      name: 'Nguyễn Văn B',
      avatarUrl: 'https://picsum.photos/200/200?random=10',
      lastMessage: 'Cảm ơn bạn đã chia sẻ thông tin về xi măng!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      isOnline: true,
    ),
    Chat(
      id: '2',
      name: 'Trần Thị C',
      avatarUrl: 'https://picsum.photos/200/200?random=11',
      lastMessage: 'Dự án ABC đã hoàn thành 80%',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
    Chat(
      id: '3',
      name: 'Lê Văn D',
      avatarUrl: 'https://picsum.photos/200/200?random=12',
      lastMessage: 'Tôi sẽ gửi báo cáo chi tiết vào chiều nay',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 1,
      isOnline: true,
    ),
    Chat(
      id: '4',
      name: 'Phạm Thị E',
      avatarUrl: 'https://picsum.photos/200/200?random=13',
      lastMessage: 'Hẹn gặp lúc 9h sáng mai nhé!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
    Chat(
      id: '5',
      name: 'Hoàng Văn F',
      avatarUrl: 'https://picsum.photos/200/200?random=14',
      lastMessage: 'Cần thêm vật liệu gì không?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
      isOnline: true,
    ),
    Chat(
      id: '6',
      name: 'Vũ Thị G',
      avatarUrl: 'https://picsum.photos/200/200?random=15',
      lastMessage: 'Tài liệu đã được gửi qua email',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  static List<Message> getMessages(String chatId) {
    switch (chatId) {
      case '1':
        return [
          Message(
            id: '1',
            chatId: chatId,
            senderId: 'other',
            senderName: 'Nguyễn Văn B',
            content: 'Chào bạn! Tôi thấy bạn có chia sẻ về xi măng PCB40',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isFromMe: false,
            status: MessageStatus.read,
          ),
          Message(
            id: '2',
            chatId: chatId,
            senderId: 'me',
            senderName: 'Tôi',
            content: 'Chào bạn! Vâng, tôi vừa mua xi măng PCB40 chất lượng tốt',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
            isFromMe: true,
            status: MessageStatus.read,
          ),
          Message(
            id: '3',
            chatId: chatId,
            senderId: 'other',
            senderName: 'Nguyễn Văn B',
            content: 'Bạn mua ở đâu vậy? Giá cả như thế nào?',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            isFromMe: false,
            status: MessageStatus.read,
          ),
          Message(
            id: '4',
            chatId: chatId,
            senderId: 'me',
            senderName: 'Tôi',
            content: 'Tôi mua ở Công ty Xi măng Hà Tiên, giá 85.000 VNĐ/bao. Chất lượng rất tốt!',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
            isFromMe: true,
            status: MessageStatus.read,
          ),
          Message(
            id: '5',
            chatId: chatId,
            senderId: 'other',
            senderName: 'Nguyễn Văn B',
            content: 'Cảm ơn bạn đã chia sẻ thông tin về xi măng!',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isFromMe: false,
            status: MessageStatus.read,
          ),
        ];
      case '2':
        return [
          Message(
            id: '6',
            chatId: chatId,
            senderId: 'other',
            senderName: 'Trần Thị C',
            content: 'Chào bạn! Dự án ABC tiến độ như thế nào rồi?',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            isFromMe: false,
            status: MessageStatus.read,
          ),
          Message(
            id: '7',
            chatId: chatId,
            senderId: 'me',
            senderName: 'Tôi',
            content: 'Chào bạn! Dự án đang tiến triển tốt, đã hoàn thành khoảng 80%',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
            isFromMe: true,
            status: MessageStatus.read,
          ),
          Message(
            id: '8',
            chatId: chatId,
            senderId: 'other',
            senderName: 'Trần Thị C',
            content: 'Dự án ABC đã hoàn thành 80%',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isFromMe: false,
            status: MessageStatus.read,
          ),
        ];
      default:
        return [
          Message(
            id: '9',
            chatId: chatId,
            senderId: 'other',
            senderName: 'Người dùng',
            content: 'Xin chào!',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isFromMe: false,
            status: MessageStatus.read,
          ),
        ];
    }
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

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

String _formatMessageTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (messageDate == today) {
    // Hôm nay - chỉ hiển thị giờ
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    // Hôm qua
    return 'Hôm qua ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else {
    // Ngày khác
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
