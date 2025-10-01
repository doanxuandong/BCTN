import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/friends/friends_service.dart';
import '../../components/friend_card.dart';
import 'friend_requests_screen.dart';
import 'add_friends_screen.dart';

class FriendsScreen extends StatefulWidget {
  final String userId;
  
  const FriendsScreen({super.key, required this.userId});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  late TabController _tabController;
  
  List<UserProfile> _friends = [];
  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final friends = await _friendsService.getFriends(widget.userId);
      final incomingRequests = await _friendsService.getIncomingFriendRequests(widget.userId);
      // TODO: Implement getFollowers and getFollowing methods
      // final followers = await _friendsService.getFollowers(widget.userId);
      // final following = await _friendsService.getFollowing(widget.userId);
      
      setState(() {
        _friends = friends;
        _incomingRequests = incomingRequests;
        _followers = []; // Placeholder
        _following = []; // Placeholder
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi tải dữ liệu: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bạn bè',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _navigateToAddFriends,
            icon: const Icon(Icons.person_add),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: _navigateToFriendRequests,
                icon: const Icon(Icons.notifications),
              ),
              if (_incomingRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_incomingRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bạn bè'),
            Tab(text: 'Theo dõi'),
            Tab(text: 'Người theo dõi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildFollowingTab(),
                _buildFollowersTab(),
              ],
            ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Chưa có bạn bè',
        subtitle: 'Hãy kết bạn với mọi người để bắt đầu!',
        actionText: 'Tìm bạn bè',
        onAction: _navigateToAddFriends,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return FriendCard(
            user: friend,
            onTap: () => _viewProfile(friend),
            onRemove: () => _removeFriend(friend),
            showRemoveButton: true,
          );
        },
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_following.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add,
        title: 'Chưa theo dõi ai',
        subtitle: 'Hãy theo dõi những người bạn quan tâm!',
        actionText: 'Tìm người để theo dõi',
        onAction: _navigateToAddFriends,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final user = _following[index];
          return FriendCard(
            user: user,
            onTap: () => _viewProfile(user),
            onFollow: () => _unfollowUser(user),
            isFollowing: true,
          );
        },
      ),
    );
  }

  Widget _buildFollowersTab() {
    if (_followers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'Chưa có người theo dõi',
        subtitle: 'Hãy chia sẻ profile để mọi người biết đến bạn!',
        actionText: 'Chia sẻ profile',
        onAction: _shareProfile,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final user = _followers[index];
          return FriendCard(
            user: user,
            onTap: () => _viewProfile(user),
            onFollow: () => _followUser(user),
            isFollowing: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFriendsScreen(userId: widget.userId),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToFriendRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendRequestsScreen(userId: widget.userId),
      ),
    ).then((_) => _loadData());
  }

  void _viewProfile(UserProfile user) {
    // TODO: Navigate to user profile
    _showSnackBar('Xem profile của ${user.name}');
  }

  void _removeFriend(UserProfile friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Bạn có chắc chắn muốn hủy kết bạn với ${friend.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _friendsService.removeFriend(widget.userId, friend.id);
              if (success) {
                _loadData();
                _showSnackBar('Đã hủy kết bạn với ${friend.name}');
              } else {
                _showSnackBar('Lỗi khi hủy kết bạn');
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _followUser(UserProfile user) {
    // TODO: Implement follow user
    _showSnackBar('Đã theo dõi ${user.name}');
  }

  void _unfollowUser(UserProfile user) {
    // TODO: Implement unfollow user
    _showSnackBar('Đã bỏ theo dõi ${user.name}');
  }

  void _shareProfile() {
    // TODO: Implement share profile
    _showSnackBar('Đã chia sẻ profile');
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
