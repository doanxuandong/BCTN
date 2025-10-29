import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/chat/chat_service.dart';
import '../../services/storage/file_storage_service.dart';
import '../../services/user/user_session.dart';
import '../../components/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _titleName;
  String? _titleAvatar;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isUploading = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadHeader();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await ChatService.getMessages(widget.chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Mark as read
      await ChatService.markAsRead(widget.chatId);
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHeader() async {
    final header = await ChatService.getChatHeader(widget.chatId);
    if (!mounted) return;
    setState(() {
      _titleName = header['name'];
      _titleAvatar = header['avatar'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white24,
              backgroundImage: _titleAvatar != null ? NetworkImage(_titleAvatar!) : null,
              child: _titleAvatar == null
                  ? const Icon(Icons.person, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _titleName ?? 'Chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          _buildMessageInput(),
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
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bắt đầu cuộc trò chuyện!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(
          message: message,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isUploading ? null : _showFilePicker,
            icon: _isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _uploadProgress,
                    ),
                  )
                : const Icon(Icons.attach_file, color: Colors.grey),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey : Colors.blue[700],
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final messageId = await ChatService.sendMessage(
        chatId: widget.chatId,
        content: _messageController.text.trim(),
      );

      if (messageId != null) {
        _messageController.clear();
        await _loadMessages(); // Reload messages
      }
    } catch (e) {
      _showSnackBar('Lỗi khi gửi tin nhắn');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showFilePicker() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Chọn file (PDF, DOC, ...)'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'image') {
      await _pickAndSendImage();
    } else if (choice == 'file') {
      await _pickAndSendFile();
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final result = await FileStorageService.pickImage();
      if (result == null) return;

      await _uploadAndSendFile(
        file: result,
        messageType: MessageType.image,
      );
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FileStorageService.pickFile();
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final file = File(filePath);
      
      await _uploadAndSendFile(
        file: file,
        messageType: MessageType.file,
        fileName: result.files.single.name,
        fileSize: result.files.single.size,
      );
    } catch (e) {
      _showSnackBar('Lỗi khi chọn file: $e');
    }
  }

  Future<void> _uploadAndSendFile({
    required File file,
    required MessageType messageType,
    String? fileName,
    int? fileSize,
  }) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        _showSnackBar('Vui lòng đăng nhập lại');
        return;
      }

      final userId = currentUser['userId']?.toString();
      if (userId == null) return;

      // Upload file lên Firebase Storage
      final fileUrl = await FileStorageService.uploadFile(
        file: file,
        chatId: widget.chatId,
        userId: userId,
      );

      if (fileUrl == null) {
        _showSnackBar('Lỗi khi upload file');
        return;
      }

      // Gửi tin nhắn với file
      final actualFileName = fileName ?? file.path.split('/').last;
      final actualFileSize = fileSize ?? await file.length();
      
      String messageContent = '';
      if (messageType == MessageType.image) {
        messageContent = '📷 Đã gửi hình ảnh';
      } else {
        messageContent = '📎 $actualFileName';
      }

      final messageId = await ChatService.sendMessage(
        chatId: widget.chatId,
        content: messageContent,
        type: messageType,
        fileUrl: fileUrl,
        fileName: actualFileName,
        fileSize: actualFileSize,
      );

      if (messageId != null) {
        await _loadMessages(); // Reload messages
        _showSnackBar('Đã gửi file thành công');
      } else {
        _showSnackBar('Lỗi khi gửi tin nhắn');
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
      });
    }
  }
}