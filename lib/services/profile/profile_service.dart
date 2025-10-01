import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Lấy thông tin profile từ Firebase
  Future<UserProfile?> getProfile(String userId, {bool isOwnProfile = false}) async {
    try {
      print('Getting profile for userId: $userId');
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();
      
      print('Document exists: ${userDoc.exists}');
      if (!userDoc.exists) {
        print('User document not found');
        return null;
      }
      
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      print('User data: $userData');
      
      // Lấy danh sách bạn bè và followers
      List<String> friends = await _getFriendsList(userId);
      List<String> followers = await _getFollowersList(userId);
      
      UserProfile profile = mapFirebaseToUserProfile(userData, isOwnProfile, friends, followers);
      print('Mapped profile: ${profile.name}, ${profile.email}');
      
      return profile;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }
  
  // Cập nhật thông tin profile
  Future<bool> updateProfile(String userId, Map<String, dynamic> updateData) async {
    try {
      print('Updating profile for userId: $userId with data: $updateData');
      await _firestore.collection('Users').doc(userId).update(updateData);
      print('Profile updated successfully');
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  // Lấy danh sách bạn bè
  Future<List<String>> _getFriendsList(String userId) async {
    try {
      DocumentSnapshot friendsDoc = await _firestore
          .collection('Friends')
          .doc(userId)
          .get();
      
      if (friendsDoc.exists) {
        Map<String, dynamic> data = friendsDoc.data() as Map<String, dynamic>;
        List<dynamic> friendsList = data['friends'] ?? [];
        return friendsList.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }
  
  // Lấy danh sách followers
  Future<List<String>> _getFollowersList(String userId) async {
    try {
      DocumentSnapshot followersDoc = await _firestore
          .collection('Followers')
          .doc(userId)
          .get();
      
      if (followersDoc.exists) {
        Map<String, dynamic> data = followersDoc.data() as Map<String, dynamic>;
        List<dynamic> followersList = data['followers'] ?? [];
        return followersList.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting followers list: $e');
      return [];
    }
  }
  
  // Chuyển đổi dữ liệu Firebase thành UserProfile
  UserProfile mapFirebaseToUserProfile(
    Map<String, dynamic> userData, 
    bool isOwnProfile, 
    List<String> friends, 
    List<String> followers
  ) {
    return UserProfile(
      id: userData['userId'] ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phone: userData['phone'] ?? '',
      bio: userData['bio'] ?? '',
      position: userData['position'] ?? '',
      company: userData['company'] ?? '',
      location: userData['location'] ?? userData['address'] ?? '',
      joinDate: userData['createdAt'] != null 
          ? (userData['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActive: userData['lastLogin'] != null 
          ? (userData['lastLogin'] as Timestamp).toDate()
          : null,
      skills: List<String>.from(userData['skills'] ?? []),
      interests: List<String>.from(userData['interests'] ?? []),
      stats: ProfileStats(
        posts: userData['posts'] ?? 0, // sẽ cập nhật động bên ngoài
        followers: followers.length,
        following: friends.length,
        projects: userData['projects'] ?? 0,
        materials: userData['materials'] ?? 0,
        transactions: userData['transactions'] ?? 0,
      ),
      privacy: PrivacySettings(
        showEmail: userData['showEmail'] ?? true,
        showPhone: userData['showPhone'] ?? false,
        showLocation: userData['showLocation'] ?? true,
        showLastActive: userData['showLastActive'] ?? true,
        allowMessages: userData['allowMessages'] ?? true,
      ),
      pic: userData['pic'],
      coverImageUrl: userData['coverImageUrl'],
      sex: userData['sex'] ?? true,
      type: userData['type'] ?? '1',
      address: userData['address'] ?? '',
      isOwnProfile: isOwnProfile,
      friends: friends,
      followers: followers,
    );
  }
  
  // Tìm kiếm người dùng
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      QuerySnapshot usersQuery = await _firestore
          .collection('Users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();
      
      List<UserProfile> users = [];
      for (var doc in usersQuery.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        UserProfile user = mapFirebaseToUserProfile(userData, false, [], []);
        users.add(user);
      }
      
      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
  
  // Lấy thông tin profile hiện tại của user đang đăng nhập
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      // Lấy userId từ session hoặc auth
      // Tạm thời sử dụng userId cố định
      final userId = "1759116138794441943";
      return await getProfile(userId, isOwnProfile: true);
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }
}
