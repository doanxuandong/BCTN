import 'package:flutter/material.dart';
// import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
// import '../../components/chat_item.dart';
import '../../services/chat/chat_service.dart';
import '../../services/friends/friends_service.dart';
import '../../services/user/user_session.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In friends view, we don't need to load chats list
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showNewChatOptions,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFriendsHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildFriendsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm cuộc trò chuyện...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFriendsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Icon(Icons.group, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            'Danh sách bạn bè',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // removed old stat item

  Widget _buildFriendsList() {
    return FutureBuilder<List<UserProfile>>(
      future: _loadFriends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data!;
        if (friends.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                backgroundImage: friend.pic != null ? NetworkImage(friend.pic!) : null,
                child: friend.pic == null ? Text(friend.name[0].toUpperCase()) : null,
              ),
              title: Text(friend.name),
              subtitle: friend.position != null ? Text(friend.position!) : null,
              onTap: () => _startChatWith(friend.id),
            );
          },
        );
      },
    );
  }

  Future<List<UserProfile>> _loadFriends() async {
    final current = await UserSession.getCurrentUser();
    if (current == null) return [];
    final service = FriendsService();
    return service.getFriends(current['userId']?.toString() ?? '');
  }

  Future<void> _startChatWith(String otherUserId) async {
    final chatId = await ChatService.createChat(otherUserId);
    if (!mounted || chatId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatId: chatId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Chưa có bạn bè nào' : 'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Hãy kết bạn để bắt đầu trò chuyện!'
                : 'Thử thay đổi từ khóa tìm kiếm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm bạn bè'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Legacy chat filter no longer used in friends view

  void _startNewChat() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bắt đầu cuộc trò chuyện mới',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Thêm người dùng mới'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng thêm người dùng đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Tạo nhóm chat'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng tạo nhóm đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Quét mã QR'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng quét QR đang phát triển');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatOptions() {
    _startNewChat();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tùy chọn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Cuộc trò chuyện đã lưu trữ'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng lưu trữ đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Người dùng bị chặn'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng chặn đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt chat'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng cài đặt đang phát triển');
              },
            ),
          ],
        ),
      ),
    );
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
