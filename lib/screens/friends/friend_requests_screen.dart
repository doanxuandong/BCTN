import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../services/friends/friends_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  final String userId;
  
  const FriendRequestsScreen({super.key, required this.userId});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final incoming = await _friendsService.getIncomingFriendRequests(widget.userId);
      final outgoing = await _friendsService.getOutgoingFriendRequests(widget.userId);
      
      setState(() {
        _incomingRequests = incoming;
        _outgoingRequests = outgoing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi tải yêu cầu: ${e.toString()}');
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    final fromUser = request['fromUser'] as UserProfile;
    final success = await _friendsService.acceptFriendRequest(fromUser.id, widget.userId);
    
    if (success) {
      _showSnackBar('Đã chấp nhận yêu cầu kết bạn từ ${fromUser.name}');
      _loadRequests();
    } else {
      _showSnackBar('Lỗi chấp nhận yêu cầu kết bạn');
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final fromUser = request['fromUser'] as UserProfile;
    final success = await _friendsService.rejectFriendRequest(fromUser.id, widget.userId);
    
    if (success) {
      _showSnackBar('Đã từ chối yêu cầu kết bạn từ ${fromUser.name}');
      _loadRequests();
    } else {
      _showSnackBar('Lỗi từ chối yêu cầu kết bạn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Yêu cầu kết bạn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đến'),
                  if (_incomingRequests.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_incomingRequests.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'Đã gửi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIncomingRequests(),
                _buildOutgoingRequests(),
              ],
            ),
    );
  }

  Widget _buildIncomingRequests() {
    if (_incomingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Không có yêu cầu mới',
        subtitle: 'Khi có người gửi yêu cầu kết bạn, bạn sẽ thấy ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingRequests.length,
        itemBuilder: (context, index) {
          final request = _incomingRequests[index];
          final user = request['fromUser'] as UserProfile;
          final createdAt = request['createdAt'] as Timestamp?;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatar(user),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.typeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: user.typeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(createdAt.toDate()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectRequest(request),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[700]!),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptRequest(request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Chấp nhận'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutgoingRequests() {
    if (_outgoingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'Chưa gửi yêu cầu nào',
        subtitle: 'Các yêu cầu kết bạn bạn đã gửi sẽ hiển thị ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outgoingRequests.length,
        itemBuilder: (context, index) {
          final request = _outgoingRequests[index];
          final user = request['toUser'] as UserProfile;
          final createdAt = request['createdAt'] as Timestamp?;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: _buildAvatar(user),
              title: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.typeText),
                  if (createdAt != null)
                    Text(
                      'Gửi ${_formatTimeAgo(createdAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chờ phản hồi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onTap: () => _viewProfile(user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(UserProfile user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          child: user.displayAvatar != null
              ? ClipOval(
                  child: Image.network(
                    user.displayAvatar!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  user.initials,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
        ),
        if (user.type != '1')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: user.typeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                user.type == '2' ? Icons.star : Icons.admin_panel_settings,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfile(UserProfile user) {
    // TODO: Navigate to user profile
    _showSnackBar('Xem profile của ${user.name}');
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
      ),
    );
  }
}
