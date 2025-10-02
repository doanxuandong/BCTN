import 'package:flutter/material.dart';
import '../services/storage/image_service.dart';

class ImageSourceDialog extends StatelessWidget {
  final String title;
  final String? currentImageUrl;

  const ImageSourceDialog({
    super.key,
    required this.title,
    this.currentImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.blue),
            title: const Text('Chọn từ thư viện'),
            onTap: () async {
              final image = await ImageService.pickImageFromGallery();
              if (context.mounted) {
                Navigator.of(context).pop(image);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.green),
            title: const Text('Chụp ảnh mới'),
            onTap: () async {
              final image = await ImageService.pickImageFromCamera();
              if (context.mounted) {
                Navigator.of(context).pop(image);
              }
            },
          ),
          if (currentImageUrl != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa ảnh hiện tại'),
              onTap: () {
                Navigator.of(context).pop('delete');
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ],
    );
  }

  /// Hiển thị dialog chọn nguồn ảnh
  static Future<dynamic> show({
    required BuildContext context,
    required String title,
    String? currentImageUrl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ImageSourceDialog(
        title: title,
        currentImageUrl: currentImageUrl,
      ),
    );
  }
}
