import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: message.isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromMe) ...[
            _buildSenderAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isFromMe) _buildSenderName(),
                const SizedBox(height: 2),
                _buildMessageContent(),
                const SizedBox(height: 2),
                _buildMessageTime(),
              ],
            ),
          ),
          if (message.isFromMe) ...[
            const SizedBox(width: 8),
            _buildMessageStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue[100],
        child: Text(
          message.senderName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        message.senderName,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.voice:
        return _buildVoiceMessage();
      case MessageType.sticker:
        return _buildStickerMessage();
    }
  }

  Widget _buildTextMessage() {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: message.isFromMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: message.isFromMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isFromMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.content, // Assuming content is image URL
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Không thể tải hình ảnh'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFileMessage() {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              color: message.isFromMe ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.isFromMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage() {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: message.isFromMe ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '0:15',
              style: TextStyle(
                color: message.isFromMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        '😊',
        style: const TextStyle(fontSize: 48),
      ),
    );
  }

  Widget _buildMessageTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        message.timeFormatted,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }
}
