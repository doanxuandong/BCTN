import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // Kiểm tra xem Firebase đã được khởi tạo chưa
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }
}
