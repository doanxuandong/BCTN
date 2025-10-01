import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/social/post_service.dart';
import '../screens/social/post_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Post _post;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
          if (_post.hasImages) _buildImages(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue[100],
            backgroundImage: _post.authorAvatar != null 
                ? NetworkImage(_post.authorAvatar!)
                : null,
            child: _post.authorAvatar == null
                ? Text(
                    _post.authorInitials,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _post.timeAgo,
                  style: TextStyle(
                    color: Colors.grey[600]!,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _post.content,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildImages() {
    if (_post.imageUrls.length == 1) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        child: Image.network(
          _post.imageUrls.first,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.image,
                  color: Colors.grey,
                  size: 50,
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        height: 200,
        child: PageView.builder(
          itemCount: _post.imageUrls.length,
          itemBuilder: (context, index) {
            return Image.network(
              _post.imageUrls[index],
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildActionButton(
            icon: _post.isLiked ? Icons.favorite : Icons.favorite_border,
            label: '${_post.likesCount}',
            color: _post.isLiked ? Colors.red : Colors.grey[600]!,
            onTap: _isLiking ? null : _toggleLike,
            isLoading: _isLiking,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: '${_post.commentsCount}',
            color: Colors.grey[600]!,
            onTap: () => _openPostDetail(),
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Chia sẻ',
            color: Colors.grey[600]!,
            onTap: _sharePost,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiking = true;
    });

    try {
      final success = await PostService.toggleLike(_post.id);
      if (success) {
        setState(() {
          _post = _post.copyWith(
            isLiked: !_post.isLiked,
            likesCount: _post.isLiked ? _post.likesCount - 1 : _post.likesCount + 1,
          );
        });
      }
    } catch (e) {
      _showSnackBar('Lỗi khi thích bài viết');
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _openPostDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: _post),
      ),
    );
  }

  Future<void> _sharePost() async {
    try {
      final success = await PostService.sharePost(_post.id);
      if (success) {
        _showSnackBar('Chia sẻ bài viết thành công!');
      } else {
        _showSnackBar('Lỗi khi chia sẻ bài viết');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi chia sẻ bài viết');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
