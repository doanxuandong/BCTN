import 'package:flutter/material.dart';
import '../../models/search_notification.dart';
import '../../services/search/search_notification_service.dart';

class SearchNotificationsScreen extends StatefulWidget {
  const SearchNotificationsScreen({super.key});

  @override
  State<SearchNotificationsScreen> createState() => _SearchNotificationsScreenState();
}

class _SearchNotificationsScreenState extends State<SearchNotificationsScreen> {
  List<SearchNotification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'pending', 'responded'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    print('🔍 SearchNotificationsScreen._loadNotifications() called');
    SearchNotificationService.listenUserNotifications().listen((data) {
      print('🔍 SearchNotificationsScreen - Received ${data.length} notifications');
      if (mounted) {
        setState(() {
          _notifications = data.map((item) => SearchNotification.fromMap(item)).toList();
          _isLoading = false;
        });
        print('🔍 SearchNotificationsScreen - Updated UI with ${_notifications.length} notifications');
      }
    });
  }

  List<SearchNotification> get _filteredNotifications {
    switch (_filter) {
      case 'pending':
        return _notifications.where((n) => n.status == 'pending').toList();
      case 'responded':
        return _notifications.where((n) => n.status != 'pending').toList();
      default:
        return _notifications;
    }
  }

  Future<void> _respondToNotification(SearchNotification notification, bool isAccepted) async {
    try {
      await SearchNotificationService.respondToNotification(
        notificationId: notification.id,
        isAccepted: isAccepted,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAccepted 
                ? 'Đã quan tâm! Tin nhắn đã được gửi tự động.' 
                : 'Đã từ chối thông báo.',
            ),
            backgroundColor: isAccepted ? Colors.green : Colors.orange,
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

  Future<void> _deleteNotification(SearchNotification notification) async {
    try {
      await SearchNotificationService.deleteNotification(notification.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thông báo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo tìm kiếm'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'pending', child: Text('Chờ phản hồi')),
              const PopupMenuItem(value: 'responded', child: Text('Đã phản hồi')),
            ],
            child: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await SearchNotificationService.debugSearchNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debug info printed to console')),
                );
              }
            },
            tooltip: 'Debug',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_filter) {
      case 'pending':
        message = 'Không có thông báo chờ phản hồi';
        icon = Icons.notifications_none;
        break;
      case 'responded':
        message = 'Không có thông báo đã phản hồi';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'Không có thông báo tìm kiếm nào';
        icon = Icons.search_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isLoading = true;
        });
        _loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(SearchNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với avatar và thông tin người gửi
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _parseColor(notification.searchedTypeColor),
                  child: Text(
                    notification.senderName.isNotEmpty 
                        ? notification.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _parseColor(notification.statusColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _parseColor(notification.statusColor).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    notification.statusText,
                    style: TextStyle(
                      color: _parseColor(notification.statusColor),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Nội dung thông báo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đang tìm kiếm:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.searchCriteria,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: _parseColor(notification.searchedTypeColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Loại: ${notification.searchedTypeText}',
                        style: TextStyle(
                          color: _parseColor(notification.searchedTypeColor),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Nút hành động
            if (notification.canRespond) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToNotification(notification, true),
                      icon: const Icon(Icons.favorite, size: 16),
                      label: const Text('Quan tâm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToNotification(notification, false),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Không quan tâm'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Nút xóa (chỉ hiện khi đã phản hồi)
            if (notification.hasResponded) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteNotification(notification),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

 