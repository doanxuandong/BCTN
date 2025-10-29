import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../../services/chat/chat_service.dart';
import '../../services/friends/friends_service.dart';
import '../../services/user/user_session.dart';
import '../../components/friend_card.dart';
import '../../utils/debug_chats.dart';
import 'chat_detail_screen.dart';

class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({super.key});

  @override
  State<ChatConversationsScreen> createState() => _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> with TickerProviderStateMixin {
  List<Chat> _chats = [];
  bool _isLoading = true;
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();
  List<UserProfile> _friends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChats();
    _loadFriends();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chats = await ChatService.getChats();
      print('📊 Loaded ${chats.length} chats');
      
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading chats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriends() async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      final userId = currentUser?['userId']?.toString();
      if (userId == null) return;
      final friends = await _friendsService.getFriends(userId);
      if (!mounted) return;
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline)),
            Tab(icon: Icon(Icons.people_outline)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await DebugChats.debugAllChats();
              await DebugChats.debugAllMessages();
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
                  ? _buildEmptyState()
                  : _buildChatsList(),
          _buildFriendsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bắt đầu cuộc trò chuyện đầu tiên của bạn!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có bạn bè nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFriends();
      },
      child: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return FriendListTile(
            user: friend,
            onTap: () async {
              // Mở chat với bạn
              final currentUser = await UserSession.getCurrentUser();
              final myId = currentUser?['userId']?.toString();
              if (myId == null) return;
              final participants = [myId, friend.id]..sort();
              final chatId = participants.join('_');
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(chatId: chatId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatsList() {
    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                backgroundImage: chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
                child: chat.avatarUrl == null 
                    ? Text(chat.name[0].toUpperCase()) 
                    : null,
              ),
              title: Text(
                chat.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(chat.lastMessageTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(chatId: chat.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
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
}

