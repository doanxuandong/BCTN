import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review/review_service.dart';
import '../../services/user/user_session.dart';
import '../../components/review_card.dart';
import '../../components/star_rating_widget.dart';
import 'add_review_screen.dart';

class ReviewsListScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserAvatar;
  final double currentRating;
  final int reviewCount;

  const ReviewsListScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatar,
    required this.currentRating,
    required this.reviewCount,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _currentUserId;
  Map<int, int> _ratingStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await UserSession.getCurrentUser();
      _currentUserId = currentUser?['userId'];

      print('📊 Loading reviews for user: ${widget.targetUserId}');
      final reviews = await ReviewService.getReviewsByTargetUser(widget.targetUserId);
      print('📊 Found ${reviews.length} reviews');
      
      final stats = await ReviewService.getRatingStats(widget.targetUserId);

      setState(() {
        _reviews = reviews;
        _ratingStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading reviews: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ReviewService.deleteReview(reviewId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa đánh giá'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Reload
      }
    }
  }

  Future<void> _editReview(Review review) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          targetUserId: widget.targetUserId,
          targetUserName: widget.targetUserName,
          targetUserAvatar: widget.targetUserAvatar,
          existingReview: review,
        ),
      ),
    );

    if (result == true) {
      _loadData(); // Reload nếu có thay đổi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary header
                    _buildSummaryHeader(),
                    const Divider(height: 1),
                    // Reviews list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          final isOwnReview = review.reviewerId == _currentUserId;

                          return ReviewCard(
                            review: review,
                            isOwnReview: isOwnReview,
                            onEdit: () => _editReview(review),
                            onDelete: () => _deleteReview(review.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Rating overview
          Row(
            children: [
              // Left: Big rating number
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      widget.currentRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StarRatingWidget(
                      rating: widget.currentRating,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.reviewCount} đánh giá',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Rating bars
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final count = _ratingStats[star] ?? 0;
                    final percentage = widget.reviewCount > 0 ? count / widget.reviewCount : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

