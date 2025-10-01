import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_model.dart';
import '../notifications/notification_service.dart';
import '../user/user_session.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';

  /// Lấy danh sách chat
  static Future<List<Chat>> getChats() async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return [];

      final userId = currentUser['userId']?.toString();
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final chats = <Chat>[];
      for (var doc in snapshot.docs) {
        final chatData = doc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
        
        if (otherUserId.isNotEmpty) {
          // Lấy thông tin người dùng khác
          final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final chat = Chat(
              id: doc.id,
              name: userData['name'] ?? 'Unknown',
              avatarUrl: userData['pic'],
              lastMessage: chatData['lastMessage'] ?? '',
              lastMessageTime: DateTime.fromMillisecondsSinceEpoch(chatData['lastMessageTime'] ?? 0),
              unreadCount: chatData['unreadCounts']?[userId] ?? 0,
              isOnline: chatData['isOnline'] ?? false,
              lastMessageType: MessageType.values.firstWhere(
                (type) => type.toString().split('.').last == chatData['lastMessageType'],
                orElse: () => MessageType.text,
              ),
              lastMessageSender: chatData['lastMessageSender'],
            );
            chats.add(chat);
          }
        }
      }

      return chats;
    } catch (e) {
      print('Error getting chats: $e');
      return [];
    }
  }

  /// Lắng nghe chats realtime
  static Stream<List<Chat>> listenToChats() {
    return _firestore
        .collection(_chatsCollection)
        .snapshots()
        .asyncMap((snapshot) async {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return <Chat>[];

      final userId = currentUser['userId']?.toString();
      if (userId == null) return <Chat>[];

      final chats = <Chat>[];
      for (var doc in snapshot.docs) {
        final chatData = doc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        if (participants.contains(userId)) {
          final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
          
          if (otherUserId.isNotEmpty) {
            final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final chat = Chat(
                id: doc.id,
                name: userData['name'] ?? 'Unknown',
                avatarUrl: userData['pic'],
                lastMessage: chatData['lastMessage'] ?? '',
                lastMessageTime: DateTime.fromMillisecondsSinceEpoch(chatData['lastMessageTime'] ?? 0),
                unreadCount: chatData['unreadCounts']?[userId] ?? 0,
                isOnline: chatData['isOnline'] ?? false,
                lastMessageType: MessageType.values.firstWhere(
                  (type) => type.toString().split('.').last == chatData['lastMessageType'],
                  orElse: () => MessageType.text,
                ),
                lastMessageSender: chatData['lastMessageSender'],
              );
              chats.add(chat);
            }
          }
        }
      }

      // Sort by last message time
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  /// Tạo chat mới
  static Future<String?> createChat(String otherUserId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return null;

      // Kiểm tra xem đã có chat chưa
      final existingChat = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          return doc.id; // Chat đã tồn tại
        }
      }

      // Tạo chat mới
      final chatData = {
        'participants': [userId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageType': MessageType.text.toString().split('.').last,
        'lastMessageSender': null,
        'unreadCounts': {
          userId: 0,
          otherUserId: 0,
        },
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final docRef = await _firestore.collection(_chatsCollection).add(chatData);
      print('Chat created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  /// Gửi tin nhắn
  static Future<String?> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      final userName = currentUser['name']?.toString() ?? 'Unknown';
      if (userId == null) return null;

      final now = DateTime.now();
      final messageData = {
        'chatId': chatId,
        'senderId': userId,
        'senderName': userName,
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': now.millisecondsSinceEpoch,
        'isRead': false,
        'status': MessageStatus.sent.toString().split('.').last,
      };

      // Thêm tin nhắn
      final messageRef = await _firestore.collection(_messagesCollection).add(messageData);

      // Cập nhật chat
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': now.millisecondsSinceEpoch,
        'lastMessageType': type.toString().split('.').last,
        'lastMessageSender': userName,
      });

      // Tăng unread count cho người nhận
      final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);
        final unreadCounts = Map<String, int>.from(chatData['unreadCounts'] ?? {});

        for (String participantId in participants) {
          if (participantId != userId) {
            unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
          }
        }

        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'unreadCounts': unreadCounts,
        });

        // Tạo thông báo cho người nhận
        for (String participantId in participants) {
          if (participantId != userId) {
            await _createMessageNotification(
              receiverId: participantId,
              senderId: userId,
              senderName: userName,
              content: content,
              chatId: chatId,
            );
          }
        }
      }

      print('Message sent successfully: ${messageRef.id}');
      return messageRef.id;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Lấy tin nhắn của một chat
  static Future<List<Message>> getMessages(String chatId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      final myId = currentUser?['userId']?.toString();

      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .limit(50)
          .get();

      final items = snapshot.docs
          .map((doc) => _mapMessage(doc.data(), doc.id, myId))
          .toList();
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  /// Lắng nghe tin nhắn realtime
  static Stream<List<Message>> listenToMessages(String chatId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
          final currentUser = await UserSession.getCurrentUser();
          final myId = currentUser?['userId']?.toString();
          final list = snapshot.docs
              .map((doc) => _mapMessage(doc.data(), doc.id, myId))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  /// Lấy thông tin tiêu đề chat (tên, avatar người còn lại)
  static Future<Map<String, String?>> getChatHeader(String chatId) async {
    final currentUser = await UserSession.getCurrentUser();
    final userId = currentUser?['userId']?.toString();
    if (userId == null) return {'name': 'Chat', 'avatar': null};

    final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
    if (!chatDoc.exists) return {'name': 'Chat', 'avatar': null};

    final data = chatDoc.data()!;
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
    if (otherUserId.isEmpty) return {'name': 'Chat', 'avatar': null};

    final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
    if (!userDoc.exists) return {'name': 'Chat', 'avatar': null};

    final userData = userDoc.data() as Map<String, dynamic>;
    return {
      'name': userData['name']?.toString() ?? 'Chat',
      'avatar': userData['pic']?.toString(),
    };
  }

  static Message _mapMessage(Map<String, dynamic> data, String id, String? myId) {
    final typeStr = data['type']?.toString() ?? 'text';
    final statusStr = data['status']?.toString() ?? 'sent';
    final type = MessageType.values.firstWhere(
      (t) => t.toString().split('.').last == typeStr,
      orElse: () => MessageType.text,
    );
    final status = MessageStatus.values.firstWhere(
      (s) => s.toString().split('.').last == statusStr,
      orElse: () => MessageStatus.sent,
    );

    final fromMe = myId != null && myId == (data['senderId']?.toString());

    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      isFromMe: fromMe,
      type: type,
      status: status,
    );
  }

  /// Đánh dấu tin nhắn đã đọc
  static Future<void> markAsRead(String chatId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return;

      // Reset unread count
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'unreadCounts.$userId': 0,
      });

      // Đánh dấu tất cả tin nhắn trong chat là đã đọc (lọc ở client để tránh cần index)
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        if (data['senderId'] != userId) {
          batch.update(doc.reference, {
            'isRead': true,
            'status': MessageStatus.read.toString().split('.').last,
          });
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Tạo thông báo tin nhắn thông minh
  static Future<void> _createMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String content,
    required String chatId,
  }) async {
    try {
      // Kiểm tra xem đã có thông báo tin nhắn chưa đọc từ người này chưa
      final existingNotification = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: receiverId)
          .where('type', isEqualTo: 'message')
          .where('senderId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();

      if (existingNotification.docs.isNotEmpty) {
        // Cập nhật thông báo hiện tại
        final notificationDoc = existingNotification.docs.first;
        final notificationData = notificationDoc.data();
        final currentCount = notificationData['data']?['messageCount'] ?? 1;
        
        await notificationDoc.reference.update({
          'message': currentCount == 1 
              ? '$senderName: $content'
              : '$senderName đã gửi $currentCount tin nhắn mới',
          'data.messageCount': currentCount + 1,
          'data.lastMessage': content,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Tạo thông báo mới
        await NotificationService.createNotification(
          receiverId: receiverId,
          title: 'Tin nhắn mới',
          message: '$senderName: $content',
          type: 'message',
          senderId: senderId,
          senderName: senderName,
          data: {
            'action': 'message',
            'chatId': chatId,
            'messageCount': 1,
            'lastMessage': content,
          },
        );
      }
    } catch (e) {
      print('Error creating message notification: $e');
    }
  }
}
