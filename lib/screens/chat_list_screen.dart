import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../components/chat_item.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> _chats = SampleChatData.chats;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredChats = _getFilteredChats();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
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
          _buildChatStats(),
          Expanded(
            child: filteredChats.isEmpty
                ? _buildEmptyState()
                : _buildChatList(filteredChats),
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

  Widget _buildChatStats() {
    final totalChats = _chats.length;
    final unreadCount = _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
    final onlineCount = _chats.where((chat) => chat.isOnline).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Cuộc trò chuyện',
              '$totalChats',
              Icons.chat_bubble_outline,
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              'Tin nhắn chưa đọc',
              '$unreadCount',
              Icons.mark_email_unread_outlined,
              Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              'Đang hoạt động',
              '$onlineCount',
              Icons.circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildChatList(List<Chat> chats) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatItem(
          chat: chat,
          onTap: () => _openChat(chat),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Chưa có cuộc trò chuyện nào' : 'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Bắt đầu cuộc trò chuyện đầu tiên của bạn!'
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
              icon: const Icon(Icons.chat),
              label: const Text('Bắt đầu trò chuyện'),
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

  List<Chat> _getFilteredChats() {
    if (_searchQuery.isEmpty) {
      return _chats;
    }

    return _chats.where((chat) {
      return chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chat: chat),
      ),
    ).then((_) {
      // Refresh chat list when returning
      setState(() {});
    });
  }

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
