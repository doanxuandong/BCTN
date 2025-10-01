import 'package:flutter/material.dart';
import '../services/notifications/notification_service.dart';
import '../services/user/user_session.dart';
import '../screens/notifications/notifications_screen.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  int _unreadCount = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await UserSession.getCurrentUser();
    if (userData != null && mounted) {
      setState(() {
        _currentUserId = userData['userId']?.toString();
      });
      _listenToNotifications();
    }
  }

  void _listenToNotifications() {
    if (_currentUserId != null) {
      print('Listening to notifications for user: $_currentUserId');
      NotificationService.listenToUnreadCount(_currentUserId!).listen((count) {
        print('Unread count updated: $count');
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToNotifications(),
      child: Stack(
        children: [
          const Icon(
            Icons.notifications_outlined,
            size: 24,
            color: Colors.black87,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
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
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToNotifications() {
    if (_currentUserId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(userId: _currentUserId!),
        ),
      );
    }
  }
}
