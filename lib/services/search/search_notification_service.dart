import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../user/user_session.dart';
import '../chat/auto_message_service.dart';

class SearchNotificationService {
  static const String _collection = 'search_notifications';

  /// Stream số lượng thông báo chưa đọc cho người dùng hiện tại
  static Stream<int> getUnreadCount() async* {
    print('🔍 SearchNotificationService.getUnreadCount() called');
    final userId = await _getCurrentUserId();
    print('🔍 getUnreadCount - userId: $userId');
    
    if (userId == null || userId.isEmpty) {
      print('❌ getUnreadCount - userId is null or empty, yielding 0');
      yield 0;
      return;
    }
    
    print('🔍 getUnreadCount - Querying Firestore for userId: $userId');
    yield* FirebaseFirestore.instance
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) {
          print('🔍 getUnreadCount - Firestore returned ${snap.size} unread notifications');
          return snap.size;
        })
        .handleError((error) {
          print('❌ getUnreadCount - Firestore error: $error');
          return 0;
        });
  }

  /// Lấy userId hiện tại từ UserSession
  static Future<String?> _getCurrentUserId() async {
    try {
      print('🔍 SearchNotificationService._getCurrentUserId() called');
      final currentUser = await UserSession.getCurrentUser();
      print('🔍 currentUser from UserSession: $currentUser');
      
      if (currentUser == null) {
        print('❌ currentUser is null');
        return null;
      }    
      
      final userId = currentUser['userId']?.toString();
      print('🔍 extracted userId: $userId');
      return userId;
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  /// Gửi 1 thông báo tìm kiếm tới người nhận
  static Future<bool> sendSearchNotification({
    required String receiverId,
    required String receiverName,
    required String searchCriteria,
    required UserAccountType searchedType,
    required String senderId,
    required String senderName,
  }) async {
    try {
      print('🔍 sendSearchNotification called:');
      print('🔍 receiverId: $receiverId');
      print('🔍 receiverName: $receiverName');
      print('🔍 senderId: $senderId');
      print('🔍 senderName: $senderName');
      print('🔍 searchCriteria: $searchCriteria');
      print('🔍 searchedType: $searchedType');
      
      final doc = <String, dynamic>{
        'receiverId': receiverId,
        'receiverName': receiverName,
        'senderId': senderId,
        'senderName': senderName,
        'searchedType': searchedType.name,
        'searchCriteria': searchCriteria,
        'status': 'pending',
        'read': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      print('🔍 Document to save: $doc');
      final docRef = await FirebaseFirestore.instance.collection(_collection).add(doc);
      print('✅ Search notification sent to $receiverName with ID: ${docRef.id}');
      return true;
    } catch (e) {
      print('❌ sendSearchNotification error: $e');
      return false;
    }
  }

  /// Lắng nghe thông báo tìm kiếm của người dùng hiện tại
  static Stream<List<Map<String, dynamic>>> listenUserNotifications() async* {
    print('🔍 SearchNotificationService.listenUserNotifications() called');
    final userId = await _getCurrentUserId();
    print('🔍 listenUserNotifications - userId: $userId');
    
    if (userId == null || userId.isEmpty) {
      print('❌ listenUserNotifications - userId is null or empty, yielding empty list');
      yield [];
      return;
    }
    
    print('🔍 listenUserNotifications - Querying Firestore for userId: $userId');
    yield* FirebaseFirestore.instance
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🔍 listenUserNotifications - Firestore returned ${snapshot.docs.length} notifications');
      final notifications = snapshot.docs.map((doc) {
        final data = {
          'id': doc.id,
          ...doc.data(),
        };
        print('🔍 Notification: ${doc.id} - ${data['senderName']} -> ${data['receiverName']}');
        return data;
      }).toList();
      return notifications;
    });
  }

  /// Đánh dấu thông báo là đã đọc
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(notificationId)
          .update({'read': true});
      print('✅ Notification $notificationId marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Phản hồi thông báo (Quan tâm/Không quan tâm)
  static Future<bool> respondToNotification({
    required String notificationId,
    required bool isAccepted,
  }) async {
    try {
      // Cập nhật trạng thái thông báo
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(notificationId)
          .update({
        'status': isAccepted ? 'accepted' : 'rejected',
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
        'read': true,
      });

      if (isAccepted) {
        // Lấy thông tin thông báo để gửi tin nhắn tự động
        final doc = await FirebaseFirestore.instance
            .collection(_collection)
            .doc(notificationId)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final senderId = data['senderId'] as String;
          final senderName = data['senderName'] as String;
          final searchCriteria = data['searchCriteria'] as String;
          final searchedTypeStr = data['searchedType'] as String;
          
          // Chuyển đổi searchedType string thành UserAccountType
          UserAccountType searchedType;
          switch (searchedTypeStr) {
            case 'designer':
              searchedType = UserAccountType.designer;
              break;
            case 'contractor':
              searchedType = UserAccountType.contractor;
              break;
            case 'store':
              searchedType = UserAccountType.store;
              default:
              searchedType = UserAccountType.general;
          }

          // Gửi tin nhắn tự động
          final success = await AutoMessageService.sendInterestMessage(
            receiverId: senderId,
            receiverName: senderName,
            receiverType: searchedType,
            originalSearchCriteria: searchCriteria,
          );

          if (success) {
            print('✅ Auto message sent successfully');
          } else {
            print('❌ Failed to send auto message');
          }
        }
      }

      print('✅ Notification response: ${isAccepted ? "accepted" : "rejected"}');
      return true;
    } catch (e) {
      print('❌ Error responding to notification: $e');
      return false;
    }
  }

  /// Xóa thông báo
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(notificationId)
          .delete();
      print('✅ Notification $notificationId deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// In ra console toàn bộ thông báo để debug
  static Future<void> debugSearchNotifications() async {
    final snap = await FirebaseFirestore.instance.collection(_collection).get();
    print('🔍 search_notifications count: ${snap.size}');
    for (final d in snap.docs) {
      print(' - ${d.id}: ${d.data()}');
    }
  }
}


 