import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildAvatar(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.isOnline) _buildOnlineIndicator(),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: _buildLastMessage(),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat.timeAgo,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (chat.unreadCount > 0) _buildUnreadBadge(),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: chat.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      chat.avatarUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        if (chat.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      chat.initials,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLastMessage() {
    return Row(
      children: [
        if (chat.lastMessageType != MessageType.text) _buildMessageTypeIcon(),
        Expanded(
          child: Text(
            chat.lastMessage,
            style: TextStyle(
              color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
              fontSize: 14,
              fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageTypeIcon() {
    IconData icon;
    Color color;

    switch (chat.lastMessageType) {
      case MessageType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case MessageType.file:
        icon = Icons.attach_file;
        color = Colors.orange;
        break;
      case MessageType.voice:
        icon = Icons.mic;
        color = Colors.purple;
        break;
      case MessageType.sticker:
        icon = Icons.emoji_emotions;
        color = Colors.pink;
        break;
      default:
        icon = Icons.message;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Text(
        chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

