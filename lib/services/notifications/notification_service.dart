import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/user_session.dart';
import '../../models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Lấy danh sách thông báo của user hiện tại
  static Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      print('Querying notifications for userId: $userId');
      final snapshot = await _firestore
          .collection(_collection)
          .where('receiverId', isEqualTo: userId)
          .limit(50)
          .get();

      print('Query returned ${snapshot.docs.length} documents');
      
      // Debug: In ra tất cả documents
      for (var doc in snapshot.docs) {
        print('Document ID: ${doc.id}');
        print('Document data: ${doc.data()}');
      }

      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      // Sort by createdAt manually since we can't use orderBy
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Lấy số lượng thông báo chưa đọc
  static Future<int> getUnreadCount(String userId) async {
    try {
      print('Querying unread count for userId: $userId');
      final snapshot = await _firestore
          .collection(_collection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      print('Unread count query returned ${snapshot.docs.length} documents');
      
      // Debug: In ra tất cả unread documents
      for (var doc in snapshot.docs) {
        print('Unread Document ID: ${doc.id}');
        print('Unread Document data: ${doc.data()}');
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Đánh dấu thông báo là đã đọc
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Tạo thông báo mới
  static Future<void> createNotification({
    required String receiverId,
    required String title,
    required String message,
    required String type,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'receiverId': receiverId, // Thêm receiverId vào document
        'title': title,
        'message': message,
        'type': type,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'data': data,
      };

      await _firestore.collection(_collection).add(notificationData);
      print('Notification created successfully for receiver: $receiverId');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Tạo thông báo lời mời kết bạn
  static Future<void> createFriendRequestNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
  }) async {
    await createNotification(
      receiverId: receiverId,
      title: 'Lời mời kết bạn mới',
      message: '$senderName muốn kết bạn với bạn',
      type: 'friend_request',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      data: {
        'action': 'friend_request',
        'senderId': senderId,
      },
    );
  }

  /// Tạo thông báo chấp nhận lời mời kết bạn
  static Future<void> createFriendAcceptedNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
  }) async {
    await createNotification(
      receiverId: receiverId,
      title: 'Đã chấp nhận lời mời kết bạn',
      message: '$senderName đã chấp nhận lời mời kết bạn của bạn',
      type: 'friend_accepted',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      data: {
        'action': 'friend_accepted',
        'senderId': senderId,
      },
    );
  }

  /// Xóa thông báo
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Lắng nghe thông báo realtime
  static Stream<List<NotificationModel>> listenToNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList();
          
          // Sort by createdAt manually
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return notifications;
        });
  }

  /// Lắng nghe số lượng thông báo chưa đọc realtime
  static Stream<int> listenToUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
