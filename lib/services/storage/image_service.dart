import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Upload ảnh lên Firebase Storage
  static Future<String?> uploadImage({
    required File imageFile,
    required String userId,
    required String type, // 'avatar' hoặc 'cover'
  }) async {
    try {
      // Tạo tên file unique
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final ref = _storage.ref().child('users/$userId/$type/$fileName');
      
      // Upload file
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('Image uploaded successfully to Storage: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Storage: $e');
      return null;
    }
  }

  /// Chọn ảnh từ gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      print('Starting to pick image from gallery...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      print('Picked image: $image');
      
      if (image != null) {
        final file = File(image.path);
        print('Created file: ${file.path}');
        print('File exists: ${await file.exists()}');
        print('File size: ${await file.length()}');
        return file;
      }
      print('No image selected');
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Chụp ảnh từ camera
  static Future<File?> pickImageFromCamera() async {
    try {
      print('Starting to take photo with camera...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      print('Captured image: $image');
      
      if (image != null) {
        final file = File(image.path);
        print('Created file: ${file.path}');
        print('File exists: ${await file.exists()}');
        print('File size: ${await file.length()}');
        return file;
      }
      print('No image captured');
      return null;
    } catch (e) {
      print('Error taking photo with camera: $e');
      return null;
    }
  }

  /// Hiển thị dialog chọn nguồn ảnh
  static Future<File?> showImageSourceDialog() async {
    // Sẽ được implement trong UI component
    return null;
  }

  /// Xóa ảnh cũ từ Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully from Storage');
      return true;
    } catch (e) {
      print('Error deleting image from Storage: $e');
      return false;
    }
  }

  /// Resize ảnh nếu cần
  static Future<File?> resizeImage(File imageFile, {int maxWidth = 1024, int maxHeight = 1024}) async {
    try {
      // Trong thực tế, bạn có thể sử dụng package image để resize
      // Ở đây tôi sẽ return file gốc
      return imageFile;
    } catch (e) {
      print('Error resizing image: $e');
      return null;
    }
  }
}
