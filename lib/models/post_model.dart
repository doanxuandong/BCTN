class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final List<String> likedBy; // List of user IDs who liked
  final bool isLiked;
  final String? location;
  final List<String> tags;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likedBy = const [],
    this.isLiked = false,
    this.location,
    this.tags = const [],
  });

  factory Post.fromMap(Map<String, dynamic> map, String postId) {
    return Post(
      id: postId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'],
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      isLiked: map['isLiked'] ?? false,
      location: map['location'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedBy': likedBy,
      'isLiked': isLiked,
      'location': location,
      'tags': tags,
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? likedBy,
    bool? isLiked,
    String? location,
    List<String>? tags,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      likedBy: likedBy ?? this.likedBy,
      isLiked: isLiked ?? this.isLiked,
      location: location ?? this.location,
      tags: tags ?? this.tags,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String get authorInitials {
    return authorName.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase();
  }

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
}

class Comment {
  final String id;
  final String postId;
  final String? parentId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final List<String> likedBy;

  const Comment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.likedBy = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> map, String commentId) {
    return Comment(
      id: commentId,
      postId: map['postId'] ?? '',
      parentId: map['parentId'],
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'],
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'parentId': parentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likesCount': likesCount,
      'likedBy': likedBy,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String get authorInitials {
    return authorName.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase();
  }

  bool get isReply => parentId != null && parentId!.isNotEmpty;
}
