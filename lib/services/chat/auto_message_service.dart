import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/user_session.dart';
import '../../models/user_profile.dart';
import '../notifications/notification_service.dart';

class AutoMessageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tự động gửi tin nhắn khi người dùng quan tâm
  static Future<bool> sendInterestMessage({
    required String receiverId,
    required String receiverName,
    required UserAccountType receiverType,
    required String originalSearchCriteria,
  }) async {
    try {
      print('🚀 Starting auto message sending...');
      print('Receiver: $receiverName ($receiverId)');
      print('Receiver Type: $receiverType');
      print('Search Criteria: $originalSearchCriteria');
      
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        print('❌ No current user found for auto message');
        return false;
      }

      final senderName = currentUser['name'] ?? 'Người dùng';
      final senderId = currentUser['userId'] ?? '';
      
      print('Sender: $senderName ($senderId)');

      // Tạo tin nhắn thông minh dựa trên loại người nhận
      String message = _generateInterestMessage(
        senderName,
        receiverType,
        originalSearchCriteria,
      );

      // Tạo chat ID tương thích với ChatService (SẮP XẾP TRƯỚC)
      final participants = [senderId, receiverId];
      participants.sort(); // Sắp xếp để đồng bộ
      final chatId = participants.join('_');
      
      print('💬 Chat ID: $chatId');
      print('💬 Participants sorted: $participants');

      // Lưu tin nhắn vào Firestore
      print('📂 Creating message document...');
      final messageId = _firestore.collection('messages').doc().id;
      print('📄 Message ID: $messageId');
      final messageData = {
        'id': messageId,
        'chatId': chatId, // Sử dụng chatId thay vì conversationId
        'senderId': senderId,
        'senderName': senderName,
        'content': message,
        'type': 'text',
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Sử dụng milliseconds
        'isRead': false,
        'status': 'sent',
        'isAutoMessage': true, // Đánh dấu là tin nhắn tự động
        'originalSearchCriteria': originalSearchCriteria,
        'receiverType': receiverType.toString(),
      };

      print('💬 Generated message: $message');
      print('📝 Saving message to Firestore...');
      
      // Lưu tin nhắn
      await _firestore.collection('messages').doc(messageId).set(messageData);
      print('✅ Message saved to Firestore');

      // Tạo hoặc cập nhật chat
      print('📋 Creating/updating chat...');
      await _createOrUpdateChat(
        chatId,
        senderId,
        receiverId,
        message,
        receiverType,
        originalSearchCriteria,
      );
      print('✅ Chat created/updated');

      // Tạo thông báo tin nhắn mới
      print('🔔 Creating notification...');
      await _createMessageNotification(receiverId, senderName, message, chatId);
      print('✅ Notification created');

      print('🎉 Auto message sent successfully to $receiverName');
      return true;
    } catch (e) {
      print('Error sending auto message: $e');
      return false;
    }
  }

  /// Tạo tin nhắn quan tâm thông minh
  static String _generateInterestMessage(
    String senderName,
    UserAccountType receiverType,
    String searchCriteria,
  ) {
    String greeting;
    String serviceType;
    String callToAction;

    switch (receiverType) {
      case UserAccountType.designer:
        serviceType = 'thiết kế';
        greeting = 'Chào bạn! 👋';
        callToAction = 'Tôi rất quan tâm đến dịch vụ thiết kế của bạn. Bạn có thể chia sẻ portfolio hoặc thảo luận về dự án không?';
        break;
      case UserAccountType.contractor:
        serviceType = 'thi công xây dựng';
        greeting = 'Xin chào! 🏗️';
        callToAction = 'Tôi đang tìm kiếm chủ thầu cho dự án của mình. Bạn có thể trao đổi về kinh nghiệm và khả năng thi công không?';
        break;
      case UserAccountType.store:
        serviceType = 'vật liệu xây dựng';
        greeting = 'Chào bạn! 🏪';
        callToAction = 'Tôi cần tìm nguồn vật liệu xây dựng chất lượng. Bạn có thể tư vấn về sản phẩm và giá cả không?';
        break;
      default:
        serviceType = 'dịch vụ';
        greeting = 'Chào bạn! 👋';
        callToAction = 'Tôi quan tâm đến dịch vụ của bạn. Bạn có thể chia sẻ thêm thông tin không?';
    }

    return '''$greeting

Tôi là $senderName. Tôi vừa tìm kiếm $serviceType với tiêu chí: "$searchCriteria" và thấy profile của bạn.

$callToAction

Hãy kết nối để chúng ta có thể trao đổi chi tiết hơn nhé! 

🔗 **BuilderConnect** - Kết nối xây dựng tương lai''';
  }

  /// Tạo hoặc cập nhật chat tương thích với ChatService
  static Future<void> _createOrUpdateChat(
    String chatId,
    String senderId,
    String receiverId,
    String lastMessage,
    UserAccountType receiverType,
    String originalSearchCriteria,
  ) async {
    try {
      print('📋 Creating/updating chat: $chatId');
      print('📋 Participants: $senderId, $receiverId');
      
      // Sắp xếp participants để đồng bộ với ChatService
      final participants = [senderId, receiverId];
      participants.sort(); // Sắp xếp để đồng bộ
      
      print('📋 Participants after sort: $participants');
      
      final chatData = {
        'id': chatId,
        'participants': participants, // Sắp xếp thứ tự
        'lastMessage': lastMessage,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageType': 'text',
        'lastMessageSender': senderId,
        'unreadCounts': {receiverId: FieldValue.increment(1)},
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Business chat context
        'chatType': 'business', // Đánh dấu là business chat
        'receiverType': receiverType.toString(),
        'searchContext': originalSearchCriteria,
        'isAutoMessage': true,
      };

      print('📝 Saving chat data: $chatData');
      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(chatData, SetOptions(merge: true));
      
      print('✅ Chat saved successfully');
    } catch (e) {
      print('❌ Error creating/updating chat: $e');
    }
  }

  /// Tạo thông báo tin nhắn mới
  static Future<void> _createMessageNotification(
    String receiverId,
    String senderName,
    String message,
    String chatId,
  ) async {
    try {
      await NotificationService.createNotification(
        receiverId: receiverId,
        title: 'Tin nhắn mới',
        message: '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
        type: 'message',
        data: {
          'chatId': chatId,
          'senderName': senderName,
        },
      );
    } catch (e) {
      print('Error creating message notification: $e');
    }
  }

  /// Lấy lịch sử tin nhắn tự động
  static Future<List<Map<String, dynamic>>> getAutoMessageHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .where('isAutoMessage', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting auto message history: $e');
      return [];
    }
  }

  /// Đánh dấu tin nhắn đã đọc
  static Future<bool> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }

  /// Debug method để kiểm tra tất cả tin nhắn
  static Future<void> debugAllMessages() async {
    try {
      print('🔍 DEBUG: Checking all messages in Firestore...');
      final snapshot = await _firestore.collection('messages').get();
      print('📊 Total messages found: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📄 Message ID: ${doc.id}');
        print('   From: ${data['senderName']} (${data['senderId']})');
        print('   To: ${data['receiverName']} (${data['receiverId']})');
        print('   Content: ${data['content']}');
        print('   Auto Message: ${data['isAutoMessage']}');
        print('   Timestamp: ${data['timestamp']}');
        print('---');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
}
