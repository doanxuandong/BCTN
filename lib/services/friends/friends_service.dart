import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../profile/profile_service.dart';
import '../notifications/notification_service.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProfileService _profileService = ProfileService();
  
  // Gửi yêu cầu kết bạn
  Future<bool> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      // Kiểm tra xem đã có yêu cầu chưa
      DocumentSnapshot requestDoc = await _firestore
          .collection('FriendRequests')
          .doc('${fromUserId}_$toUserId')
          .get();
      
      if (requestDoc.exists) {
        return false; // Đã gửi yêu cầu rồi
      }
      
      // Tạo yêu cầu kết bạn
      await _firestore.collection('FriendRequests').doc('${fromUserId}_$toUserId').set({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Lấy thông tin người gửi để tạo thông báo
      final senderProfile = await _profileService.getProfile(fromUserId, isOwnProfile: false);
      if (senderProfile != null) {
        // Tạo thông báo cho người nhận
        await NotificationService.createFriendRequestNotification(
          receiverId: toUserId,
          senderId: fromUserId,
          senderName: senderProfile.name,
          senderAvatar: senderProfile.displayAvatar,
        );
      }
      
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }
  
  // Chấp nhận yêu cầu kết bạn
  Future<bool> acceptFriendRequest(String fromUserId, String toUserId) async {
    try {
      print('Accepting friend request from $fromUserId to $toUserId');
      
      // Cập nhật trạng thái yêu cầu
      await _firestore.collection('FriendRequests').doc('${fromUserId}_$toUserId').update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      
      // Thêm vào danh sách bạn bè của cả hai người
      print('Adding $toUserId to $fromUserId friends list');
      await _addToFriendsList(fromUserId, toUserId);
      
      print('Adding $fromUserId to $toUserId friends list');
      await _addToFriendsList(toUserId, fromUserId);
      
      // Lấy thông tin người chấp nhận để tạo thông báo
      final accepterProfile = await _profileService.getProfile(toUserId, isOwnProfile: false);
      if (accepterProfile != null) {
        // Tạo thông báo cho người gửi yêu cầu
        await NotificationService.createFriendAcceptedNotification(
          receiverId: fromUserId,
          senderId: toUserId,
          senderName: accepterProfile.name,
          senderAvatar: accepterProfile.displayAvatar,
        );
      }
      
      print('Friend request accepted successfully');
      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }
  
  // Từ chối yêu cầu kết bạn
  Future<bool> rejectFriendRequest(String fromUserId, String toUserId) async {
    try {
      await _firestore.collection('FriendRequests').doc('${fromUserId}_$toUserId').update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }
  
  // Hủy lời mời kết bạn đã gửi
  Future<bool> cancelFriendRequest(String fromUserId, String toUserId) async {
    try {
      await _firestore.collection('FriendRequests').doc('${fromUserId}_$toUserId').delete();
      return true;
    } catch (e) {
      print('Error cancelling friend request: $e');
      return false;
    }
  }
  
  // Hủy kết bạn
  Future<bool> removeFriend(String userId1, String userId2) async {
    try {
      // Xóa khỏi danh sách bạn bè của cả hai người
      await _removeFromFriendsList(userId1, userId2);
      await _removeFromFriendsList(userId2, userId1);
      
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }
  
  // Lấy danh sách bạn bè
  Future<List<UserProfile>> getFriends(String userId) async {
    try {
      print('Getting friends for userId: $userId');
      DocumentSnapshot friendsDoc = await _firestore
          .collection('Friends')
          .doc(userId)
          .get();
      
      print('Friends document exists: ${friendsDoc.exists}');
      if (!friendsDoc.exists) {
        print('No friends document found for user: $userId');
        return [];
      }
      
      Map<String, dynamic> data = friendsDoc.data() as Map<String, dynamic>;
      print('Friends data: $data');
      List<String> friendIds = List<String>.from(data['friends'] ?? []);
      print('Friend IDs: $friendIds');
      
      List<UserProfile> friends = [];
      for (String friendId in friendIds) {
        UserProfile? friend = await _profileService.getProfile(friendId);
        if (friend != null) {
          friends.add(friend);
        }
      }
      
      print('Found ${friends.length} friends');
      return friends;
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }
  
  // Lấy danh sách yêu cầu kết bạn đến
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests(String userId) async {
    try {
      QuerySnapshot requestsQuery = await _firestore
          .collection('FriendRequests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      List<Map<String, dynamic>> requests = [];
      for (var doc in requestsQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        UserProfile? fromUser = await _profileService.getProfile(data['fromUserId']);
        if (fromUser != null) {
          requests.add({
            'id': doc.id,
            'fromUser': fromUser,
            'createdAt': data['createdAt'],
          });
        }
      }
      
      return requests;
    } catch (e) {
      print('Error getting incoming friend requests: $e');
      return [];
    }
  }
  
  // Lấy danh sách yêu cầu kết bạn đã gửi
  Future<List<Map<String, dynamic>>> getOutgoingFriendRequests(String userId) async {
    try {
      QuerySnapshot requestsQuery = await _firestore
          .collection('FriendRequests')
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      List<Map<String, dynamic>> requests = [];
      for (var doc in requestsQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        UserProfile? toUser = await _profileService.getProfile(data['toUserId']);
        if (toUser != null) {
          requests.add({
            'id': doc.id,
            'toUser': toUser,
            'createdAt': data['createdAt'],
          });
        }
      }
      
      return requests;
    } catch (e) {
      print('Error getting outgoing friend requests: $e');
      return [];
    }
  }
  
  // Kiểm tra trạng thái kết bạn
  Future<String> getFriendshipStatus(String userId1, String userId2) async {
    try {
      // Kiểm tra xem có phải bạn bè không
      DocumentSnapshot friendsDoc = await _firestore
          .collection('Friends')
          .doc(userId1)
          .get();
      
      if (friendsDoc.exists) {
        Map<String, dynamic> data = friendsDoc.data() as Map<String, dynamic>;
        List<String> friends = List<String>.from(data['friends'] ?? []);
        if (friends.contains(userId2)) {
          return 'friends';
        }
      }
      
      // Kiểm tra yêu cầu kết bạn
      DocumentSnapshot requestDoc = await _firestore
          .collection('FriendRequests')
          .doc('${userId1}_$userId2')
          .get();
      
      if (requestDoc.exists) {
        Map<String, dynamic> data = requestDoc.data() as Map<String, dynamic>;
        return data['status'] ?? 'none';
      }
      
      return 'none';
    } catch (e) {
      print('Error getting friendship status: $e');
      return 'none';
    }
  }
  
  // Kiểm tra xem đã gửi lời mời kết bạn chưa
  Future<bool> hasSentFriendRequest(String fromUserId, String toUserId) async {
    try {
      DocumentSnapshot requestDoc = await _firestore
          .collection('FriendRequests')
          .doc('${fromUserId}_$toUserId')
          .get();
      
      if (requestDoc.exists) {
        Map<String, dynamic> data = requestDoc.data() as Map<String, dynamic>;
        return data['status'] == 'pending';
      }
      
      return false;
    } catch (e) {
      print('Error checking friend request status: $e');
      return false;
    }
  }
  
  // Thêm vào danh sách bạn bè
  Future<void> _addToFriendsList(String userId, String friendId) async {
    try {
      // Kiểm tra xem document đã tồn tại chưa
      DocumentSnapshot doc = await _firestore.collection('Friends').doc(userId).get();
      
      if (doc.exists) {
        // Document đã tồn tại, sử dụng update
        await _firestore.collection('Friends').doc(userId).update({
          'friends': FieldValue.arrayUnion([friendId]),
        });
      } else {
        // Document chưa tồn tại, tạo mới
        await _firestore.collection('Friends').doc(userId).set({
          'friends': [friendId],
        });
      }
    } catch (e) {
      print('Error adding to friends list: $e');
    }
  }
  
  // Xóa khỏi danh sách bạn bè
  Future<void> _removeFromFriendsList(String userId, String friendId) async {
    await _firestore.collection('Friends').doc(userId).update({
      'friends': FieldValue.arrayRemove([friendId]),
    });
  }
  
  // Lấy danh sách gợi ý kết bạn
  Future<List<UserProfile>> getFriendSuggestions(String userId) async {
    try {
      // Lấy danh sách bạn bè hiện tại
      List<UserProfile> currentFriends = await getFriends(userId);
      Set<String> friendIds = currentFriends.map((f) => f.id).toSet();
      friendIds.add(userId); // Thêm chính mình
      
      // Lấy tất cả người dùng khác
      QuerySnapshot usersQuery = await _firestore
          .collection('Users')
          .limit(50)
          .get();
      
      List<UserProfile> suggestions = [];
      for (var doc in usersQuery.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String docUserId = userData['userId'] ?? doc.id;
        
        if (!friendIds.contains(docUserId)) {
          UserProfile user = _profileService.mapFirebaseToUserProfile(userData, false, [], []);
          suggestions.add(user);
        }
      }
      
      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting friend suggestions: $e');
      return [];
    }
  }
}
