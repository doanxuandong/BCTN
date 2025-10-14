import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Đăng ký user mới
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String phone = '',
    String address = '',
    bool sex = true, // true = nam, false = nữ
    String type = '1', // 1 = thường, 2 = chủ thầu, 3 = cửa hàng vật liệu, 4 = nhà thiết kế
  }) async {
    try {
      // Kiểm tra email đã tồn tại chưa
      QuerySnapshot existingUsers = await _firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        throw 'Email này đã được sử dụng';
      }
      
      // Tạo userId mới
      String userId = DateTime.now().millisecondsSinceEpoch.toString() + 
                     email.hashCode.abs().toString().substring(0, 6);
      
      // Map type cũ sang accountType mới
      String accountType;
      switch (type) {
        case '2': // Chủ thầu
          accountType = 'UserAccountType.contractor';
          break;
        case '3': // Cửa hàng VLXD
          accountType = 'UserAccountType.store';
          break;
        case '4': // Nhà thiết kế
          accountType = 'UserAccountType.designer';
          break;
        default:
          accountType = 'UserAccountType.general';
      }

      // Dữ liệu user mới với các trường search
      Map<String, dynamic> userData = {
        'userId': userId,
        'email': email,
        'pass': password, // Lưu password trực tiếp (không mã hóa - chỉ demo)
        'name': fullName,
        'phone': phone,
        'address': address,
        'pic': '', // URL ảnh đại diện
        'sex': sex, // true = nam, false = nữ
        'type': type, // Loại user cũ (để tương thích)
        'userName': fullName.split(' ').last, // Tên ngắn gọn
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        // Thêm các trường search mới
        'accountType': accountType,
        'province': '',
        'region': '',
        'specialties': [],
        'rating': 0.0,
        'reviewCount': 0,
        'latitude': 0.0,
        'longitude': 0.0,
        'additionalInfo': {},
        'isSearchable': true,
      };
      
      // Lưu vào Firestore
      await _firestore.collection('Users').doc(userId).set(userData);
      
      return {
        'success': true,
        'message': 'Đăng ký thành công!',
        'userData': userData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Đăng nhập
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Tìm user theo email
      QuerySnapshot userQuery = await _firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .get();
      
      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Email không tồn tại',
        };
      }
      
      // Lấy dữ liệu user
      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Kiểm tra password
      if (userData['pass'] != password) {
        return {
          'success': false,
          'message': 'Mật khẩu không đúng',
        };
      }
      
      // Cập nhật lastLogin
      await userDoc.reference.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'Đăng nhập thành công!',
        'userData': userData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }
  
  // Lấy thông tin user theo userId
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Cập nhật thông tin user
  Future<bool> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      await _firestore.collection('Users').doc(userId).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Tìm user
      QuerySnapshot userQuery = await _firestore
          .collection('Users')
          .where('email', isEqualTo: email)
          .get();
      
      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Email không tồn tại',
        };
      }
      
      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Kiểm tra mật khẩu hiện tại
      if (userData['pass'] != currentPassword) {
        return {
          'success': false,
          'message': 'Mật khẩu hiện tại không đúng',
        };
      }
      
      // Cập nhật mật khẩu mới
      await userDoc.reference.update({
        'pass': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'Đổi mật khẩu thành công!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }
}

