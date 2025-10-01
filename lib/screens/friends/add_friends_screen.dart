import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/friends/friends_service.dart';
import '../../components/friend_card.dart';

class AddFriendsScreen extends StatefulWidget {
  final String userId;
  
  const AddFriendsScreen({super.key, required this.userId});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserProfile> _suggestions = [];
  List<UserProfile> _searchResults = [];
  Map<String, bool> _requestStatus = {}; // userId -> hasSentRequest
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _friendsService.getFriendSuggestions(widget.userId);
      
      // Load trạng thái lời mời cho từng user
      Map<String, bool> requestStatus = {};
      for (var user in suggestions) {
        bool hasSent = await _friendsService.hasSentFriendRequest(widget.userId, user.id);
        requestStatus[user.id] = hasSent;
      }
      
      setState(() {
        _suggestions = suggestions;
        _requestStatus = requestStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi tải gợi ý: ${e.toString()}');
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // TODO: Implement searchUsers method in FriendsService
      // For now, return empty results
      final results = <UserProfile>[];
      
      // Load trạng thái lời mời cho kết quả tìm kiếm
      Map<String, bool> requestStatus = {};
      for (var user in results) {
        bool hasSent = await _friendsService.hasSentFriendRequest(widget.userId, user.id);
        requestStatus[user.id] = hasSent;
      }
      
      setState(() {
        _searchResults = results;
        _requestStatus.addAll(requestStatus);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showSnackBar('Lỗi tìm kiếm: ${e.toString()}');
    }
  }

  Future<void> _sendFriendRequest(UserProfile user) async {
    final success = await _friendsService.sendFriendRequest(widget.userId, user.id);
    if (success) {
      setState(() {
        _requestStatus[user.id] = true;
      });
      _showSnackBar('Đã gửi yêu cầu kết bạn đến ${user.name}');
    } else {
      _showSnackBar('Lỗi gửi yêu cầu kết bạn');
    }
  }
  
  Future<void> _cancelFriendRequest(UserProfile user) async {
    final success = await _friendsService.cancelFriendRequest(widget.userId, user.id);
    if (success) {
      setState(() {
        _requestStatus[user.id] = false;
      });
      _showSnackBar('Đã hủy lời mời kết bạn đến ${user.name}');
    } else {
      _showSnackBar('Lỗi hủy yêu cầu kết bạn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tìm bạn bè',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
        ),
        onChanged: _searchUsers,
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }

    return _buildSuggestions();
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return FriendListTile(
          user: user,
          onTap: () => _viewProfile(user),
        onFollow: _requestStatus[user.id] == true 
            ? () => _cancelFriendRequest(user)
            : () => _sendFriendRequest(user),
        isFollowing: _requestStatus[user.id] == true,
        );
      },
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có gợi ý nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tìm kiếm để kết bạn với mọi người',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Gợi ý kết bạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final user = _suggestions[index];
              return FriendCard(
                user: user,
                onTap: () => _viewProfile(user),
        onFollow: _requestStatus[user.id] == true 
            ? () => _cancelFriendRequest(user)
            : () => _sendFriendRequest(user),
        isFollowing: _requestStatus[user.id] == true,
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewProfile(UserProfile user) {
    // TODO: Navigate to user profile
    _showSnackBar('Xem profile của ${user.name}');
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

class FriendListTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;
  final bool isFollowing;

  const FriendListTile({
    super.key,
    required this.user,
    this.onTap,
    this.onFollow,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildAvatar(),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.typeText),
            if (user.hasPosition) Text(user.position),
          ],
        ),
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAvatar() {
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

  Widget _buildTrailing() {
    return IconButton(
      onPressed: onFollow,
      icon: Icon(
        isFollowing ? Icons.person_remove : Icons.person_add,
        color: isFollowing ? Colors.grey[700] : Colors.blue[700],
      ),
    );
  }
}
