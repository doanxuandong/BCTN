import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(NotificationModel)? onNavigate;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) onTap!();
            if (onNavigate != null) onNavigate!(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 4),
                      _buildMessage(),
                      const SizedBox(height: 8),
                      _buildTimeAndActions(),
                    ],
                  ),
                ),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 20,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            notification.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
              color: notification.isRead ? Colors.black87 : Colors.black,
            ),
          ),
        ),
        if (!notification.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildMessage() {
    return Text(
      notification.message,
      style: TextStyle(
        fontSize: 13,
        color: notification.isRead ? Colors.grey.shade600 : Colors.grey.shade700,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTimeAndActions() {
    return Row(
      children: [
        Text(
          notification.timeAgo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        if (notification.senderName != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Từ ${notification.senderName}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete' && onDelete != null) {
          onDelete!();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Xóa'),
            ],
          ),
        ),
      ],
      child: const Icon(
        Icons.more_vert,
        color: Colors.grey,
        size: 20,
      ),
    );
  }


  Color _getTypeColor() {
    switch (notification.type) {
      case 'friend_request':
        return Colors.blue;
      case 'friend_accepted':
        return Colors.green;
      case 'message':
        return Colors.orange;
      case 'post_like':
        return Colors.red;
      case 'post_comment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.check_circle;
      case 'message':
        return Icons.message;
      case 'post_like':
        return Icons.favorite;
      case 'post_comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }
}
