import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../profile/profile_service.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'Users';

  /// Tạo hoặc cập nhật user profile
  static Future<String?> createOrUpdateProfile(UserProfile profile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final profileData = {
        'id': profile.id,
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'avatarUrl': profile.avatarUrl,
        'coverImageUrl': profile.coverImageUrl,
        'bio': profile.bio,
        'position': profile.position,
        'company': profile.company,
        'location': profile.location,
        'joinDate': Timestamp.fromDate(profile.joinDate),
        'lastActive': profile.lastActive != null ? Timestamp.fromDate(profile.lastActive!) : null,
        'skills': profile.skills,
        'interests': profile.interests,
        'stats': {
          'posts': profile.stats.posts,
          'followers': profile.stats.followers,
          'following': profile.stats.following,
          'friends': profile.stats.friends,
          'projects': profile.stats.projects,
          'materials': profile.stats.materials,
          'transactions': profile.stats.transactions,
        },
        'privacy': {
          'showEmail': profile.privacy.showEmail,
          'showPhone': profile.privacy.showPhone,
          'showLocation': profile.privacy.showLocation,
          'showLastActive': profile.privacy.showLastActive,
          'allowMessages': profile.privacy.allowMessages,
        },
        'pic': profile.pic,
        'sex': profile.sex,
        'type': profile.type,
        'address': profile.address,
        'friends': profile.friends,
        'followers': profile.followers,
        'accountType': profile.accountType.toString(),
        'province': profile.province,
        'region': profile.region,
        'specialties': profile.specialties,
        'rating': profile.rating,
        'reviewCount': profile.reviewCount,
        'latitude': profile.latitude,
        'longitude': profile.longitude,
        'additionalInfo': profile.additionalInfo,
        'isSearchable': profile.isSearchable,
        'createdAt': Timestamp.fromDate(profile.createdAt),
        'updatedAt': Timestamp.now(),
      };

      await _firestore
          .collection(_collection)
          .doc(profile.id)
          .set(profileData, SetOptions(merge: true));

      return profile.id;
    } catch (e) {
      print('Error creating/updating user profile: $e');
      return null;
    }
  }

  /// Lấy user profile theo ID
  static Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (!doc.exists) return null;
      
      return _fromDoc(doc);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Lấy stream user profile theo ID
  static Stream<UserProfile?> listenProfile(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? _fromDoc(doc) : null);
  }

  /// Tìm kiếm user profiles theo tiêu chí
  static Future<List<UserProfile>> searchProfiles({
    UserAccountType? accountType,
    String? province,
    String? region,
    List<String>? specialties,
    double? minRating,
    double? userLat,
    double? userLng,
    double? maxDistanceKm,
    String? keyword,
    int limit = 50,
  }) async {
    try {
      print('Searching profiles with filters...');
      
      // Lấy tất cả users từ collection Users
      final snapshot = await _firestore.collection(_collection).get();
      print('Found ${snapshot.docs.length} total users');
      
      List<UserProfile> profiles = [];
      
      // Convert mỗi document thành UserProfile
      for (var doc in snapshot.docs) {
        try {
          final userData = doc.data();
          final friends = await _getFriendsList(doc.id);
          final followers = await _getFollowersList(doc.id);
          
          final profileService = ProfileService();
          final profile = profileService.mapFirebaseToUserProfile(
            userData, 
            false, // isOwnProfile
            friends, 
            followers
          );
          
          profiles.add(profile);
        } catch (e) {
          print('Error converting user ${doc.id}: $e');
        }
      }
      
      print('Converted ${profiles.length} profiles');
      
      // Apply filters
      if (accountType != null) {
        profiles = profiles.where((profile) => profile.accountType == accountType).toList();
        print('After accountType filter: ${profiles.length} profiles');
      }
      
      if (province != null && province.isNotEmpty) {
        profiles = profiles.where((profile) => 
          profile.province.toLowerCase().contains(province.toLowerCase()) ||
          province.toLowerCase().contains(profile.province.toLowerCase())
        ).toList();
        print('After province filter: ${profiles.length} profiles');
      }
      
      if (keyword != null && keyword.isNotEmpty) {
        final lowerKeyword = keyword.toLowerCase();
        profiles = profiles.where((profile) =>
          profile.name.toLowerCase().contains(lowerKeyword) ||
          profile.address.toLowerCase().contains(lowerKeyword) ||
          profile.location.toLowerCase().contains(lowerKeyword) ||
          profile.bio.toLowerCase().contains(lowerKeyword) ||
          profile.position.toLowerCase().contains(lowerKeyword) ||
          profile.company.toLowerCase().contains(lowerKeyword)
        ).toList();
        print('After keyword filter: ${profiles.length} profiles');
      }
      
      // Limit results
      profiles = profiles.take(limit).toList();
      
      return profiles;
    } catch (e) {
      print('Error searching user profiles: $e');
      return [];
    }
  }

  // Helper methods để lấy friends và followers
  static Future<List<String>> _getFriendsList(String userId) async {
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

  static Future<List<String>> _getFollowersList(String userId) async {
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

  /// Lấy tất cả user profiles có thể tìm kiếm
  static Stream<List<UserProfile>> listenSearchableProfiles() {
    return _firestore
        .collection(_collection)
        .where('isSearchable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _fromDoc(doc)).toList());
  }

  /// Cập nhật trạng thái tìm kiếm được
  static Future<bool> updateSearchableStatus(String userId, bool isSearchable) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isSearchable': isSearchable,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating searchable status: $e');
      return false;
    }
  }

  /// Cập nhật vị trí người dùng
  static Future<bool> updateLocation(String userId, double latitude, double longitude) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  /// Cập nhật đánh giá
  static Future<bool> updateRating(String userId, double newRating, int reviewCount) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'rating': newRating,
        'reviewCount': reviewCount,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating rating: $e');
      return false;
    }
  }

  /// Chuyển đổi DocumentSnapshot thành UserProfile
  static UserProfile _fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserProfile(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'],
      coverImageUrl: data['coverImageUrl'],
      bio: data['bio'] ?? '',
      position: data['position'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      joinDate: _parseDateTime(data['joinDate']) ?? DateTime.now(),
      lastActive: _parseDateTime(data['lastActive']),
      skills: List<String>.from(data['skills'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      stats: ProfileStats(
        posts: data['stats']?['posts'] ?? 0,
        followers: data['stats']?['followers'] ?? 0,
        following: data['stats']?['following'] ?? 0,
        friends: data['stats']?['friends'] ?? 0,
        projects: data['stats']?['projects'] ?? 0,
        materials: data['stats']?['materials'] ?? 0,
        transactions: data['stats']?['transactions'] ?? 0,
      ),
      privacy: PrivacySettings(
        showEmail: data['privacy']?['showEmail'] ?? true,
        showPhone: data['privacy']?['showPhone'] ?? false,
        showLocation: data['privacy']?['showLocation'] ?? true,
        showLastActive: data['privacy']?['showLastActive'] ?? true,
        allowMessages: data['privacy']?['allowMessages'] ?? true,
      ),
      pic: data['pic'],
      sex: data['sex'] ?? true,
      type: data['type'] ?? '1',
      address: data['address'] ?? '',
      friends: List<String>.from(data['friends'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      accountType: _parseAccountType(data['accountType']),
      province: data['province'] ?? '',
      region: data['region'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      isSearchable: data['isSearchable'] ?? true,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  /// Parse DateTime từ Firestore
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Parse UserAccountType từ string
  static UserAccountType _parseAccountType(String? value) {
    switch (value) {
      case 'UserAccountType.designer':
        return UserAccountType.designer;
      case 'UserAccountType.contractor':
        return UserAccountType.contractor;
      case 'UserAccountType.store':
        return UserAccountType.store;
      default:
        return UserAccountType.general;
    }
  }
}
