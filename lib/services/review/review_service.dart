import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/review.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'Reviews';
  static const String _usersCollection = 'Users';

  /// Thêm đánh giá mới
  static Future<String?> addReview({
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatar,
    required String targetUserId,
    required double rating,
    required String comment,
  }) async {
    try {
      // Kiểm tra không tự đánh giá bản thân
      if (reviewerId == targetUserId) {
        throw Exception('Không thể tự đánh giá bản thân');
      }

      // Kiểm tra đã đánh giá chưa
      final existingReview = await getUserReview(reviewerId, targetUserId);
      if (existingReview != null) {
        throw Exception('Bạn đã đánh giá người này rồi');
      }

      // Tạo review mới
      final reviewData = {
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerAvatar': reviewerAvatar,
        'targetUserId': targetUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };

      final docRef = await _firestore.collection(_reviewsCollection).add(reviewData);

      // Cập nhật rating trung bình của user được đánh giá
      await _updateUserRating(targetUserId);

      return docRef.id;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  /// Cập nhật đánh giá
  static Future<bool> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Lấy targetUserId từ review
      final reviewDoc = await _firestore.collection(_reviewsCollection).doc(reviewId).get();
      final targetUserId = reviewDoc.data()?['targetUserId'];
      
      if (targetUserId != null) {
        await _updateUserRating(targetUserId);
      }

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  /// Xóa đánh giá
  static Future<bool> deleteReview(String reviewId) async {
    try {
      // Lấy targetUserId trước khi xóa
      final reviewDoc = await _firestore.collection(_reviewsCollection).doc(reviewId).get();
      final targetUserId = reviewDoc.data()?['targetUserId'];

      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();

      // Cập nhật lại rating
      if (targetUserId != null) {
        await _updateUserRating(targetUserId);
      }

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  /// Lấy tất cả đánh giá của 1 user (người được đánh giá)
  static Future<List<Review>> getReviewsByTargetUser(String targetUserId) async {
    try {
      print('🔍 Querying reviews for targetUserId: $targetUserId');
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('targetUserId', isEqualTo: targetUserId)
          // Tạm bỏ orderBy để tránh cần composite index
          // .orderBy('createdAt', descending: true)
          .get();

      print('🔍 Query returned ${snapshot.docs.length} documents');
      for (var doc in snapshot.docs) {
        print('  - Review ID: ${doc.id}, data: ${doc.data()}');
      }

      final reviews = snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
      
      // Sort trong Dart thay vì Firestore
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reviews;
    } catch (e) {
      print('❌ Error getting reviews: $e');
      return [];
    }
  }

  /// Lấy đánh giá của 1 reviewer cho 1 target user (kiểm tra đã đánh giá chưa)
  static Future<Review?> getUserReview(String reviewerId, String targetUserId) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('reviewerId', isEqualTo: reviewerId)
          .where('targetUserId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Review.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting user review: $e');
      return null;
    }
  }

  /// Stream lắng nghe reviews của 1 user
  static Stream<List<Review>> listenToReviews(String targetUserId) {
    return _firestore
        .collection(_reviewsCollection)
        .where('targetUserId', isEqualTo: targetUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  /// Cập nhật rating trung bình và reviewCount của user
  static Future<void> _updateUserRating(String userId) async {
    try {
      final reviews = await getReviewsByTargetUser(userId);
      
      if (reviews.isEmpty) {
        // Không có review nào
        await _firestore.collection(_usersCollection).doc(userId).update({
          'rating': 0.0,
          'reviewCount': 0,
        });
        return;
      }

      // Tính rating trung bình
      final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      await _firestore.collection(_usersCollection).doc(userId).update({
        'rating': averageRating,
        'reviewCount': reviews.length,
      });
    } catch (e) {
      print('Error updating user rating: $e');
    }
  }

  /// Lấy thống kê rating (số lượng mỗi loại sao)
  static Future<Map<int, int>> getRatingStats(String targetUserId) async {
    try {
      final reviews = await getReviewsByTargetUser(targetUserId);
      final stats = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var review in reviews) {
        final star = review.rating.round();
        stats[star] = (stats[star] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting rating stats: $e');
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
  }
}

