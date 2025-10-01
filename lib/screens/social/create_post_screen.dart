import 'package:flutter/material.dart';
import '../../services/social/post_service.dart';
import '../../services/storage/image_service.dart';
import '../../components/image_source_dialog.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _imageUrls = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: const Text(
          'Tạo bài viết',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishPost,
            child: Text(
              'Đăng',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfo(),
                  const SizedBox(height: 16),
                  _buildContentField(),
                  const SizedBox(height: 16),
                  if (_imageUrls.isNotEmpty) _buildImageGrid(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue[100],
          child: const Text(
            'U',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Bạn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return TextField(
      controller: _contentController,
      maxLines: null,
      decoration: const InputDecoration(
        hintText: 'Bạn đang nghĩ gì?',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_imageUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Ảnh',
            onTap: _addImage,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.location_on,
            label: 'Vị trí',
            onTap: _addLocation,
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.tag,
            label: 'Gắn thẻ',
            onTap: _addTags,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addImage() async {
    final result = await ImageSourceDialog.show(
      context: context,
      title: 'Thêm ảnh',
    );

    if (result != null && result is File) {
      setState(() {
        _isLoading = true;
      });

      try {
        final imageUrl = await ImageService.uploadImage(
          imageFile: result,
          userId: 'current_user', // Sẽ được lấy từ session
          type: 'post',
        );

        if (imageUrl != null) {
          setState(() {
            _imageUrls.add(imageUrl);
          });
        } else {
          _showSnackBar('Lỗi khi tải ảnh lên');
        }
      } catch (e) {
        _showSnackBar('Lỗi khi tải ảnh lên: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _addLocation() {
    _showSnackBar('Chức năng thêm vị trí đang phát triển');
  }

  void _addTags() {
    _showSnackBar('Chức năng gắn thẻ đang phát triển');
  }

  Future<void> _publishPost() async {
    if (_contentController.text.trim().isEmpty && _imageUrls.isEmpty) {
      _showSnackBar('Vui lòng nhập nội dung hoặc thêm ảnh');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final postId = await PostService.createPost(
        content: _contentController.text.trim(),
        imageUrls: _imageUrls,
      );

      if (postId != null) {
        _showSnackBar('Đăng bài thành công!');
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar('Lỗi khi đăng bài');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi đăng bài: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
