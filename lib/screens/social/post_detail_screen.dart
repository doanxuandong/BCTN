import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/social/post_service.dart';
import '../../components/comment_item.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  List<Comment> _comments = [];
  Comment? _replyTo;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await PostService.getComments(_post.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi khi tải bình luận');
    }
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
          'Bài viết',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPost(),
                  _buildComments(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPost() {
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
            onTap: _toggleLike,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: '${_post.commentsCount}',
            color: Colors.grey[600]!,
            onTap: () {},
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
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

  Widget _buildComments() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Chưa có bình luận nào',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<Comment>>(
      stream: PostService.listenToComments(_post.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? _comments;
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Chưa có bình luận nào',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
        return Column(
          children: items.map((c) => CommentItem(
            comment: c,
            onReply: (cm) => setState(() => _replyTo = cm),
          )).toList(),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyTo != null) _buildReplyingTo(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Viết bình luận...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isPostingComment ? null : _postComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isPostingComment ? Colors.grey : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: _isPostingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyingTo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đang trả lời ${_replyTo!.authorName}: ${_replyTo!.content}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyTo = null),
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike() async {
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
    }
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

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      final commentId = await PostService.addComment(
        postId: _post.id,
        content: _commentController.text.trim(),
        parentId: _replyTo?.id,
      );

      if (commentId != null) {
        _commentController.clear();
        await _loadComments(); // Reload comments
        setState(() {
          _post = _post.copyWith(commentsCount: _post.commentsCount + 1);
          _replyTo = null;
        });
      } else {
        _showSnackBar('Lỗi khi đăng bình luận');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi đăng bình luận');
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
