import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../components/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late List<Message> _messages;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = SampleChatData.getMessages(widget.chat.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.chat.isOnline)
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  )
                else
                  Text(
                    'Hoạt động ${widget.chat.timeAgo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _makeVoiceCall,
          icon: const Icon(Icons.phone),
        ),
        IconButton(
          onPressed: _makeVideoCall,
          icon: const Icon(Icons.videocam),
        ),
        IconButton(
          onPressed: _showMoreOptions,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: widget.chat.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  widget.chat.avatarUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                ),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      widget.chat.initials,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _showAttachmentOptions,
            icon: const Icon(Icons.add),
            color: Colors.grey[600],
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: Colors.blue[700],
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chat.id,
      senderId: 'me',
      senderName: 'Tôi',
      content: text,
      timestamp: DateTime.now(),
      isFromMe: true,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate receiving a reply after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final reply = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: widget.chat.id,
          senderId: 'other',
          senderName: widget.chat.name,
          content: _generateAutoReply(text),
          timestamp: DateTime.now(),
          isFromMe: false,
          status: MessageStatus.read,
        );

        setState(() {
          _messages.add(reply);
        });

        _scrollToBottom();
      }
    });
  }

  String _generateAutoReply(String message) {
    final replies = [
      'Cảm ơn bạn đã chia sẻ!',
      'Tôi hiểu rồi.',
      'Thông tin rất hữu ích!',
      'Đúng vậy, tôi đồng ý.',
      'Cảm ơn bạn!',
      'Tôi sẽ xem xét.',
      'Thú vị quá!',
      'Tôi cũng nghĩ vậy.',
    ];
    return replies[DateTime.now().millisecondsSinceEpoch % replies.length];
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đính kèm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Hình ảnh',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Chức năng gửi hình ảnh đang phát triển');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Chức năng gửi video đang phát triển');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'Tệp',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Chức năng gửi tệp đang phát triển');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.mic,
                  label: 'Ghi âm',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Chức năng ghi âm đang phát triển');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Vị trí',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Chức năng chia sẻ vị trí đang phát triển');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: Colors.blue[700],
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _makeVoiceCall() {
    _showSnackBar('Chức năng gọi thoại đang phát triển');
  }

  void _makeVideoCall() {
    _showSnackBar('Chức năng gọi video đang phát triển');
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
              leading: const Icon(Icons.person),
              title: const Text('Xem hồ sơ'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng xem hồ sơ đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Tìm kiếm tin nhắn'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng tìm kiếm đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Tắt thông báo'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Đã tắt thông báo cho cuộc trò chuyện này');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Chặn người dùng', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng chặn đang phát triển');
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
