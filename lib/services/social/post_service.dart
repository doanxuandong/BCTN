import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../notifications/notification_service.dart';
import '../user/user_session.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _postsCollection = 'posts';
  static const String _commentsCollection = 'comments';

  /// Lấy danh sách bài viết
  static Future<List<Post>> getPosts({int limit = 20}) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection(_postsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts = <Post>[];
      for (var doc in snapshot.docs) {
        final post = Post.fromMap(doc.data(), doc.id);
        // Check if current user liked this post
        final isLiked = post.likedBy.contains(currentUser['userId']?.toString());
        posts.add(post.copyWith(isLiked: isLiked));
      }

      return posts;
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  /// Lấy bài viết của một user cụ thể
  static Future<List<Post>> getPostsByUser(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: userId)
          .limit(limit)
          .get();

      final posts = snapshot.docs.map((d) => Post.fromMap(d.data(), d.id)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      print('Error getting posts by user: $e');
      return [];
    }
  }

  /// Lắng nghe bài viết realtime
  static Stream<List<Post>> listenToPosts({int limit = 20}) {
    return _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return <Post>[];

      final posts = <Post>[];
      for (var doc in snapshot.docs) {
        final post = Post.fromMap(doc.data(), doc.id);
        final isLiked = post.likedBy.contains(currentUser['userId']?.toString());
        posts.add(post.copyWith(isLiked: isLiked));
      }

      return posts;
    });
  }

  /// Tạo bài viết mới
  static Future<String?> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? location,
    List<String> tags = const [],
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      final userName = currentUser['name']?.toString() ?? 'Unknown';
      final userAvatar = currentUser['pic']?.toString();

      if (userId == null) return null;

      final now = DateTime.now();
      final postData = {
        'authorId': userId,
        'authorName': userName,
        'authorAvatar': userAvatar,
        'content': content,
        'imageUrls': imageUrls,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'likedBy': <String>[],
        'location': location,
        'tags': tags,
      };

      final docRef = await _firestore.collection(_postsCollection).add(postData);
      print('Post created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Like/Unlike bài viết
  static Future<bool> toggleLike(String postId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return false;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return false;

      final postRef = _firestore.collection(_postsCollection).doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      final likedBy = List<String>.from(postData['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        // Unlike
        likedBy.remove(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        likedBy.add(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(1),
        });

        // Tạo thông báo cho tác giả bài viết
        final authorId = postData['authorId']?.toString();
        if (authorId != null && authorId != userId) {
          final userName = currentUser['name']?.toString() ?? 'Người dùng';
          await NotificationService.createNotification(
            receiverId: authorId,
            title: 'Có người thích bài viết của bạn',
            message: '$userName đã thích bài viết của bạn',
            type: 'post_like',
            senderId: userId,
            senderName: userName,
            senderAvatar: currentUser['pic']?.toString(),
            data: {
              'action': 'post_like',
              'postId': postId,
            },
          );
        }
      }

      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  /// Thêm comment
  static Future<String?> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      final userName = currentUser['name']?.toString() ?? 'Unknown';
      final userAvatar = currentUser['pic']?.toString();

      if (userId == null) return null;

      final now = DateTime.now();
      final commentData = {
        'postId': postId,
        'parentId': parentId,
        'authorId': userId,
        'authorName': userName,
        'authorAvatar': userAvatar,
        'content': content,
        'createdAt': now.millisecondsSinceEpoch,
        'likesCount': 0,
        'likedBy': <String>[],
      };

      // Thêm comment
      final commentRef = await _firestore.collection(_commentsCollection).add(commentData);

      // Cập nhật số lượng comment của post
      if (parentId == null) {
        await _firestore.collection(_postsCollection).doc(postId).update({
          'commentsCount': FieldValue.increment(1),
        });
      }

      // Lấy thông tin tác giả bài viết để tạo thông báo
      final postDoc = await _firestore.collection(_postsCollection).doc(postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data()!;
        final authorId = postData['authorId']?.toString();
        
        if (authorId != null && authorId != userId) {
          await NotificationService.createNotification(
            receiverId: authorId,
            title: 'Có bình luận mới',
            message: '$userName đã bình luận bài viết của bạn',
            type: 'post_comment',
            senderId: userId,
            senderName: userName,
            senderAvatar: userAvatar,
            data: {
              'action': 'post_comment',
              'postId': postId,
              'commentId': commentRef.id,
            },
          );
        }
      }

      print('Comment added successfully: ${commentRef.id}');
      return commentRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Lấy comments của một bài viết
  static Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection(_commentsCollection)
          .where('postId', isEqualTo: postId)
          .get();

      final comments = snapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();

      // Sort on client to avoid composite index requirement
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  /// Lắng nghe comments realtime
  static Stream<List<Comment>> listenToComments(String postId) {
    return _firestore
        .collection(_commentsCollection)
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => Comment.fromMap(doc.data(), doc.id))
              .toList();
          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return comments;
        });
  }

  /// Xóa bài viết
  static Future<bool> deletePost(String postId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return false;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return false;

      // Kiểm tra quyền sở hữu
      final postDoc = await _firestore.collection(_postsCollection).doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      if (postData['authorId'] != userId) return false;

      // Xóa tất cả comments của bài viết
      final commentsSnapshot = await _firestore
          .collection(_commentsCollection)
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Xóa bài viết
      batch.delete(_firestore.collection(_postsCollection).doc(postId));
      await batch.commit();

      print('Post deleted successfully: $postId');
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// Chia sẻ bài viết
  static Future<bool> sharePost(String postId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'sharesCount': FieldValue.increment(1),
      });

      print('Post shared successfully: $postId');
      return true;
    } catch (e) {
      print('Error sharing post: $e');
      return false;
    }
  }
}
