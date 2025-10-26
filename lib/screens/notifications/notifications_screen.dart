import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notifications/notification_service.dart';
import '../../components/notification_item.dart';
import '../../services/chat/chat_service.dart';
import '../friends/friend_requests_screen.dart';
import '../chat/chat_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading notifications for user: ${widget.userId}');
      final notifications = await NotificationService.getNotifications(widget.userId);
      print('Found ${notifications.length} notifications');
      for (var notification in notifications) {
        print('Notification: ${notification.title} - ${notification.message}');
      }
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead(widget.userId);
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    await NotificationService.deleteNotification(notification.id);
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Đánh dấu là đã đọc
    _markAsRead(notification);
    
    // Navigate dựa trên loại thông báo
    switch (notification.type) {
      case 'friend_request':
      case 'friend_accepted':
        _navigateToFriendRequests();
        break;
      case 'message':
        _navigateToChat(notification);
        break;
      case 'post_like':
      case 'post_comment':
        // TODO: Navigate to post detail
        _showComingSoon('Tính năng bài viết đang phát triển');
        break;
      default:
        // Không có action cụ thể
        break;
    }
  }

  void _navigateToFriendRequests() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendRequestsScreen(userId: widget.userId),
      ),
    );
  }

  void _navigateToChat(NotificationModel notification) async {
    print('🔍 Navigating to chat from notification');
    print('🔍 Notification data: ${notification.data}');
    
    final chatId = notification.data?['chatId']?.toString();
    print('🔍 ChatId from notification: $chatId');
    
    if (chatId != null && chatId.isNotEmpty) {
      print('✅ Using chatId from notification: $chatId');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(chatId: chatId),
        ),
      );
    } else if (notification.senderId != null) {
      print('⚠️ No chatId found, creating new chat with senderId: ${notification.senderId}');
      // Tạo chat mới nếu không có chatId trong notification
      final createdChatId = await ChatService.createChat(notification.senderId!);
      if (createdChatId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chatId: createdChatId),
          ),
        );
      } else {
        print('❌ Failed to create chat');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ No chatId and no senderId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thông báo mới sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () => _markAsRead(notification),
            onDelete: () => _deleteNotification(notification),
            onNavigate: _handleNotificationTap,
          );
        },
      ),
    );
  }
}
