// Temporary in-memory session management
class UserSession {
  static Map<String, dynamic>? _currentUser;
  static bool _isLoggedIn = false;
  
  // Lưu thông tin user đã đăng nhập
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    _currentUser = userData;
    _isLoggedIn = true;
  }
  
  // Lấy thông tin user hiện tại
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return _currentUser;
  }
  
  // Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    return _isLoggedIn;
  }
  
  // Đăng xuất
  static Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
  }
  
  // Cập nhật thông tin user
  static Future<void> updateUser(Map<String, dynamic> userData) async {
    await saveUser(userData);
  }
}
