import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FileStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file lên Firebase Storage (PDF, ảnh, file nhẹ)
  static Future<String?> uploadFile({
    required File file,
    required String chatId,
    required String userId,
  }) async {
    try {
      // Kiểm tra kích thước file (tối đa 10MB)
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('File quá lớn. Vui lòng chọn file nhỏ hơn 10MB');
      }

      // Tạo tên file unique
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('chats/$chatId/files/$fileName');
      
      // Upload file với metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'originalName': path.basename(file.path),
          'uploadedBy': userId,
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      
      // Theo dõi tiến trình upload (có thể dùng để hiển thị progress)
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      
      print('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Chọn file từ thiết bị (PDF, ảnh, file nhẹ)
  static Future<FilePickerResult?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        // Giới hạn loại file nếu cần
        allowedExtensions: null, // Cho phép tất cả
      );

      if (result != null && result.files.single.path != null) {
        return result;
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Chọn ảnh (từ gallery hoặc camera)
  static Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Lấy content type từ extension
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  /// Xóa file từ Firebase Storage
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      print('File deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Kiểm tra loại file từ URL hoặc extension
  static String getFileType(String filePathOrUrl) {
    final extension = path.extension(filePathOrUrl).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return 'image';
    } else if (extension == '.pdf') {
      return 'pdf';
    } else {
      return 'file';
    }
  }
}

