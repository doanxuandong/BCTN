import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate tất cả user profiles cũ để thêm các trường search mới
  static Future<void> migrateAllUserProfiles() async {
    try {
      print('Bắt đầu migrate user profiles...');
      
      final usersSnapshot = await _firestore.collection('Users').get();
      int migratedCount = 0;
      
      for (final doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;
        
        // Kiểm tra xem đã có accountType chưa
        if (userData['accountType'] == null) {
          // Map từ type cũ
          final oldType = userData['type'] ?? '1';
          final accountType = _mapOldTypeToAccountType(oldType);
          
          // Cập nhật document
          await doc.reference.update({
            'accountType': accountType,
            'province': userData['province'] ?? '',
            'region': userData['region'] ?? '',
            'specialties': userData['specialties'] ?? [],
            'rating': userData['rating'] ?? 0.0,
            'reviewCount': userData['reviewCount'] ?? 0,
            'latitude': userData['latitude'] ?? 0.0,
            'longitude': userData['longitude'] ?? 0.0,
            'additionalInfo': userData['additionalInfo'] ?? {},
            'isSearchable': userData['isSearchable'] ?? true,
            'migratedAt': Timestamp.now(),
          });
          
          migratedCount++;
          print('Migrated user $userId: $oldType -> $accountType');
        }
      }
      
      print('Hoàn thành migrate $migratedCount user profiles');
    } catch (e) {
      print('Lỗi migrate user profiles: $e');
    }
  }

  /// Map type cũ sang accountType mới
  static String _mapOldTypeToAccountType(String oldType) {
    switch (oldType) {
      case '2': // Chủ thầu
        return 'UserAccountType.contractor';
      case '3': // Cửa hàng VLXD
        return 'UserAccountType.store';
      case '4': // Nhà thiết kế
        return 'UserAccountType.designer';
      default:
        return 'UserAccountType.general';
    }
  }

  /// Migrate một user cụ thể
  static Future<bool> migrateUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('User $userId không tồn tại');
        return false;
      }
      
      final userData = userDoc.data()!;
      
      // Kiểm tra xem đã có accountType chưa
      if (userData['accountType'] == null) {
        final oldType = userData['type'] ?? '1';
        final accountType = _mapOldTypeToAccountType(oldType);
        
        await userDoc.reference.update({
          'accountType': accountType,
          'province': userData['province'] ?? '',
          'region': userData['region'] ?? '',
          'specialties': userData['specialties'] ?? [],
          'rating': userData['rating'] ?? 0.0,
          'reviewCount': userData['reviewCount'] ?? 0,
          'latitude': userData['latitude'] ?? 0.0,
          'longitude': userData['longitude'] ?? 0.0,
          'additionalInfo': userData['additionalInfo'] ?? {},
          'isSearchable': userData['isSearchable'] ?? true,
          'migratedAt': Timestamp.now(),
        });
        
        print('Migrated user $userId: $oldType -> $accountType');
        return true;
      }
      
      print('User $userId đã được migrate rồi');
      return true;
    } catch (e) {
      print('Lỗi migrate user $userId: $e');
      return false;
    }
  }
}
