import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/user/user_profile_service.dart';
import '../../services/search/search_notification_service.dart';
import '../../components/user_profile_card.dart';
import '../../services/user/user_session.dart';

class SearchResultsScreen extends StatefulWidget {
  final UserAccountType? accountType;
  final String? province;
  final String? region;
  final List<String>? specialties;
  final double? minRating;
  final double? userLat;
  final double? userLng;
  final double? maxDistanceKm;
  final String? keyword;

  const SearchResultsScreen({
    super.key,
    this.accountType,
    this.province,
    this.region,
    this.specialties,
    this.minRating,
    this.userLat,
    this.userLng,
    this.maxDistanceKm,
    this.keyword,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<UserProfile> _searchResults = [];
  bool _isLoading = true;
  String? _error;
  bool _isSendingNotifications = false;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await UserProfileService.searchProfiles(
        accountType: widget.accountType,
        province: widget.province,
        region: widget.region,
        specialties: widget.specialties,
        minRating: widget.minRating,
        userLat: widget.userLat,
        userLng: widget.userLng,
        maxDistanceKm: widget.maxDistanceKm,
        keyword: widget.keyword,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tìm kiếm: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotificationsToAll() async {
    if (_searchResults.isEmpty) return;

    setState(() {
      _isSendingNotifications = true;
    });

    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final senderId = currentUser['userId'] ?? '';
      final senderName = currentUser['name'] ?? 'Người dùng';
      final searchCriteria = _buildSearchCriteriaText();
      
      int successCount = 0;
      
      // Gửi thông báo đến từng người dùng
      for (final profile in _searchResults) {
        try {
          final success = await SearchNotificationService.sendSearchNotification(
            receiverId: profile.id,
            receiverName: profile.name,
            searchCriteria: searchCriteria,
            searchedType: widget.accountType ?? UserAccountType.general,
            senderId: senderId,
            senderName: senderName,
          );
          
          if (success) {
            successCount++;
          }
        } catch (e) {
          print('Error sending notification to ${profile.name}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi thông báo đến $successCount/${_searchResults.length} người dùng'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi thông báo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSendingNotifications = false;
      });
    }
  }

  String _buildSearchCriteriaText() {
    List<String> criteria = [];
    
    if (widget.accountType != null) {
      switch (widget.accountType!) {
        case UserAccountType.designer:
          criteria.add('Nhà thiết kế');
          break;
        case UserAccountType.contractor:
          criteria.add('Chủ thầu');
          break;
        case UserAccountType.store:
          criteria.add('Cửa hàng VLXD');
          break;
        default:
          criteria.add('Người dùng');
      }
    }

    if (widget.province != null && widget.province!.isNotEmpty) {
      criteria.add('Tại ${widget.province}');
    }

    if (widget.specialties != null && widget.specialties!.isNotEmpty) {
      criteria.add('Chuyên ngành: ${widget.specialties!.join(', ')}');
    }

    if (widget.minRating != null && widget.minRating! > 0) {
      criteria.add('Đánh giá từ ${widget.minRating!.toStringAsFixed(1)} sao');
    }

    if (widget.keyword != null && widget.keyword!.isNotEmpty) {
      criteria.add('Từ khóa: ${widget.keyword}');
    }

    return criteria.isEmpty ? 'Tìm kiếm chung' : criteria.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả tìm kiếm'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_searchResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _performSearch,
              tooltip: 'Tìm kiếm lại',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildResults()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Tìm thấy ${_searchResults.length} kết quả',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _buildSearchCriteriaText(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy kết quả phù hợp',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử điều chỉnh tiêu chí tìm kiếm',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final profile = _searchResults[index];
        return UserProfileCard(
          profile: profile,
          onTap: () => _showProfileDetails(profile),
          onSendNotification: () => _sendNotificationToUser(profile),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _isSendingNotifications ? null : _sendNotificationsToAll,
      icon: _isSendingNotifications
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.notifications),
      label: Text(_isSendingNotifications ? 'Đang gửi...' : 'Gửi thông báo cho tất cả'),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    );
  }

  void _showProfileDetails(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profile.displayAvatar != null
                              ? NetworkImage(profile.displayAvatar!)
                              : null,
                          child: profile.displayAvatar == null
                              ? Text(profile.initials)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.typeText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profile.typeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (profile.rating > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${profile.rating.toStringAsFixed(1)} (${profile.reviewCount} đánh giá)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _sendNotificationToUser(profile),
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('Kết nối', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.bio.isNotEmpty) ...[
                        _buildInfoSection('Giới thiệu', profile.bio),
                      ],
                      if (profile.position.isNotEmpty) ...[
                        _buildInfoSection('Vị trí', profile.position),
                      ],
                      if (profile.company.isNotEmpty) ...[
                        _buildInfoSection('Công ty', profile.company),
                      ],
                      if (profile.location.isNotEmpty) ...[
                        _buildInfoSection('Địa điểm', profile.location),
                      ],
                      if (profile.specialties.isNotEmpty) ...[
                        _buildInfoSection('Chuyên ngành', profile.specialties.join(', ')),
                      ],
                      if (profile.skills.isNotEmpty) ...[
                        _buildInfoSection('Kỹ năng', profile.skills.join(', ')),
                      ],
                      _buildInfoSection('Thống kê', 
                        'Dự án: ${profile.stats.projects} | Vật liệu: ${profile.stats.materials} | Giao dịch: ${profile.stats.transactions}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToUser(UserProfile profile) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final senderId = currentUser['userId'] ?? '';
      final senderName = currentUser['name'] ?? 'Người dùng';
      final searchCriteria = _buildSearchCriteriaText();
      
      final success = await SearchNotificationService.sendSearchNotification(
        receiverId: profile.id,
        receiverName: profile.name,
        searchCriteria: searchCriteria,
        searchedType: widget.accountType ?? UserAccountType.general,
        senderId: senderId,
        senderName: senderName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Đã gửi thông báo đến ${profile.name}' 
                  : 'Lỗi gửi thông báo đến ${profile.name}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
