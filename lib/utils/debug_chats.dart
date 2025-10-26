import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user/user_session.dart';

/// Debug script để kiểm tra chats và messages trong Firestore
class DebugChats {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug tất cả chats
  static Future<void> debugAllChats() async {
    print('🔍 ===== DEBUG ALL CHATS =====');
    
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        print('❌ No current user');
        return;
      }
      
      final userId = currentUser['userId']?.toString();
      print('🔍 Current userId: $userId');
      
      // Lấy tất cả chats
      final chatsSnapshot = await _firestore.collection('chats').get();
      print('📊 Total chats in database: ${chatsSnapshot.docs.length}');
      
      for (var chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data();
        print('---');
        print('📄 Chat ID: ${chatDoc.id}');
        print('   Participants: ${chatData['participants']}');
        print('   Last message: ${chatData['lastMessage']}');
        print('   Contains userId $userId: ${chatData['participants']?.contains(userId)}');
        
        // Lấy messages
        final messagesSnapshot = await _firestore
            .collection('messages')
            .where('chatId', isEqualTo: chatDoc.id)
            .get();
        print('   Messages count: ${messagesSnapshot.docs.length}');
      }
      
      print('🔍 ===== END DEBUG =====');
    } catch (e) {
      print('❌ Error debugging chats: $e');
    }
  }

  /// Debug messages
  static Future<void> debugAllMessages() async {
    print('🔍 ===== DEBUG ALL MESSAGES =====');
    
    try {
      final messagesSnapshot = await _firestore.collection('messages').get();
      print('📊 Total messages: ${messagesSnapshot.docs.length}');
      
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        print('---');
        print('📄 Message ID: ${doc.id}');
        print('   ChatId: ${data['chatId']}');
        print('   From: ${data['senderName']} (${data['senderId']})');
        print('   Content: ${data['content']?.substring(0, data['content'].toString().length > 50 ? 50 : data['content'].toString().length)}...');
        print('   Auto: ${data['isAutoMessage']}');
      }
      
      print('🔍 ===== END DEBUG =====');
    } catch (e) {
      print('❌ Error debugging messages: $e');
    }
  }
}

