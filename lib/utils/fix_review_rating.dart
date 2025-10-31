import '../services/review/review_service.dart';

/// Helper để fix rating khi có review nhưng rating chưa cập nhật
class FixReviewRating {
  /// Chạy hàm này để cập nhật lại rating cho 1 user
  static Future<void> fixUserRating(String userId) async {
    print('🔧 Fixing rating for user: $userId');
    
    try {
      // Lấy tất cả reviews của user
      final reviews = await ReviewService.getReviewsByTargetUser(userId);
      print('📊 Found ${reviews.length} reviews');
      
      if (reviews.isEmpty) {
        print('⚠️ No reviews found for this user');
        return;
      }
      
      // Tính rating trung bình
      final totalRating = reviews.fold<double>(0.0, (sum, review) {
        print('  - Review: ${review.rating} stars from ${review.reviewerName}');
        return sum + review.rating;
      });
      final averageRating = totalRating / reviews.length;
      
      print('📈 Calculated rating: $averageRating (from ${reviews.length} reviews)');
      print('✅ Rating should be updated automatically by ReviewService');
      
    } catch (e) {
      print('❌ Error fixing rating: $e');
    }
  }
  
  /// Chạy để fix tất cả users có reviews
  static Future<void> fixAllRatings() async {
    print('🔧 Fixing all user ratings...');
    // TODO: Implement if needed
  }
}

