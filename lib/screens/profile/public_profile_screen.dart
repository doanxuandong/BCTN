import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/completed_project.dart';
import '../../services/user/user_profile_service.dart';
import '../../services/project/completed_project_service.dart';
import '../../services/social/post_service.dart';
import '../../services/review/review_service.dart';
import '../../services/user/user_session.dart';
import '../../models/post_model.dart';
import '../../models/review.dart';
import '../../components/post_card.dart';
import '../../components/completed_project_card.dart';
import '../review/add_review_screen.dart';
import '../review/reviews_list_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  List<Post> _posts = [];
  List<CompletedProject> _completedProjects = []; // Danh sách dự án đã hoàn thành
  Review? _myReview; // Review của mình (nếu đã đánh giá)
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await UserProfileService.getProfile(widget.userId);
    final posts = await PostService.getPostsByUser(widget.userId);
    
    // Load completed projects (chỉ hiển thị cho Designer, Contractor, Store)
    List<CompletedProject> completedProjects = [];
    if (p != null &&
        (p.accountType == UserAccountType.designer ||
            p.accountType == UserAccountType.contractor ||
            p.accountType == UserAccountType.store)) {
      print('📊 Loading completed projects for profile: ${p.displayName}');
      print('  - widget.userId: ${widget.userId} (type: ${widget.userId.runtimeType})');
      print('  - p.id: ${p.id} (type: ${p.id.runtimeType})');
      // Đảm bảo userId là String khi query
      final userIdString = widget.userId.toString();
      completedProjects = await CompletedProjectService.getUserCompletedProjects(userIdString);
      print('  - Loaded ${completedProjects.length} completed projects');
    }
    
    // Kiểm tra đã đánh giá chưa
    final currentUser = await UserSession.getCurrentUser();
    _currentUserId = currentUser?['userId'];
    Review? myReview;
    if (_currentUserId != null && _currentUserId != widget.userId) {
      myReview = await ReviewService.getUserReview(_currentUserId!, widget.userId);
    }
    
    // Debug: Kiểm tra rating có đúng không
    print('📊 Profile rating: ${p?.rating}, reviewCount: ${p?.reviewCount}');
    print('📊 Completed projects: ${completedProjects.length}');
    
    if (!mounted) return;
    setState(() {
      _profile = p;
      _posts = posts;
      _completedProjects = completedProjects;
      _myReview = myReview;
      _loading = false;
    });
  }

  Future<void> _openAddReview() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đánh giá'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tự đánh giá bản thân'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          targetUserId: widget.userId,
          targetUserName: _profile!.displayName,
          targetUserAvatar: _profile!.displayAvatar,
          existingReview: _myReview,
        ),
      ),
    );

    if (result == true) {
      _load(); // Reload để cập nhật rating
    }
  }

  Future<void> _openReviewsList() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsListScreen(
          targetUserId: widget.userId,
          targetUserName: _profile!.displayName,
          targetUserAvatar: _profile!.displayAvatar,
          currentRating: _profile!.rating,
          reviewCount: _profile!.reviewCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_profile == null)
              ? const Center(child: Text('Không tìm thấy hồ sơ'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: (_profile!.displayAvatar != null)
                            ? NetworkImage(_profile!.displayAvatar!)
                            : null,
                        child: _profile!.displayAvatar == null
                            ? Text(
                                _profile!.initials,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile!.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profile!.typeText,
                        style: TextStyle(color: _profile!.typeColor),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(Icons.location_on, _profile!.address.isNotEmpty ? _profile!.address : _profile!.location),
                      const SizedBox(height: 8),
                      if (_profile!.specialties.isNotEmpty)
                        _infoRow(Icons.category, _profile!.specialties.join(', ')),
                      const SizedBox(height: 8),
                      _summaryChipsWithReview(),
                      
                      // Section: Dự án đã hoàn thành (chỉ hiển thị cho Designer, Contractor, Store)
                      if (_profile!.accountType == UserAccountType.designer ||
                          _profile!.accountType == UserAccountType.contractor ||
                          _profile!.accountType == UserAccountType.store) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dự án đã hoàn thành',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_completedProjects.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Chưa có dự án nào được hoàn thành',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._completedProjects.map(
                            (project) => CompletedProjectCard(
                              project: project,
                              onTap: () {
                                // TODO: Có thể navigate đến chi tiết dự án
                              },
                            ),
                          ),
                      ],
                      
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bài đăng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_posts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('Chưa có bài đăng nào')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => PostCard(post: _posts[index]),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _summaryChipsWithReview() {
    final items = <Widget>[];
    if (_profile!.rating > 0) {
      items.add(_chip(Icons.star, '${_profile!.rating.toStringAsFixed(1)}★', onTap: _openReviewsList));
    }
    items.add(_chip(Icons.reviews, '${_profile!.reviewCount} đánh giá', onTap: _openReviewsList));
    if (_profile!.province.isNotEmpty) items.add(_chip(Icons.location_city, _profile!.province));
    
    // Thêm nút đánh giá nếu không phải profile của mình
    if (_currentUserId != null && _currentUserId != widget.userId) {
      items.add(_reviewButton());
    }
    
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: items);
  }

  Widget _reviewButton() {
    return GestureDetector(
      onTap: _openAddReview,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _myReview != null ? Icons.edit : Icons.star_rate,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              _myReview != null ? 'Sửa' : 'Đánh giá',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, {VoidCallback? onTap}) {
    final chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.blue[800])),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: chipContent,
      );
    }
    return chipContent;
  }
}


