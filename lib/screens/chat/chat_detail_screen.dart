import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/business_chat_service.dart';
import '../../services/storage/file_storage_service.dart';
import '../../services/storage/image_service.dart';
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
  Chat? _chat; // Chat info với business context
  String? _receiverId; // ID của người nhận
  String? _currentUserId; // ID của người dùng hiện tại
  Message? _pendingQuoteRequest; // Quote Request chưa được phản hồi
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isUploading = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
    _loadMessages();
    _loadHeader();
  }
  
  Future<void> _loadChatInfo() async {
    final chat = await ChatService.getChatById(widget.chatId);
    if (!mounted) return;
    
    // Lấy receiverId từ participants
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser != null && chat != null) {
      final userId = currentUser['userId']?.toString();
      if (userId != null) {
        // Parse từ chatId (format: userId1_userId2, sorted)
        final participants = widget.chatId.split('_');
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => participants.isNotEmpty ? participants.last : '',
        );
        setState(() {
          _chat = chat;
          _receiverId = otherUserId;
          _currentUserId = userId;
        });
        // Kiểm tra Quote Request sau khi load messages
        _checkPendingQuoteRequest();
      } else {
        setState(() {
          _chat = chat;
        });
      }
    } else {
      setState(() {
        _chat = chat;
      });
    }
  }

  /// Kiểm tra có Quote Request chưa được phản hồi không
  void _checkPendingQuoteRequest() {
    if (_currentUserId == null || _messages.isEmpty) {
      setState(() {
        _pendingQuoteRequest = null;
      });
      return;
    }

    // Tìm Quote Request gần nhất chưa được phản hồi
    // (không phải từ current user và chưa có Quote Response)
    // Tìm từ cuối lên (message mới nhất)
    Message? pendingRequest;
    for (var i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg.type == MessageType.quoteRequest &&
          msg.senderId != _currentUserId &&
          !_hasQuoteResponseForRequest(msg.id)) {
        pendingRequest = msg;
        break;
      }
    }

    setState(() {
      _pendingQuoteRequest = pendingRequest;
    });
  }

  /// Kiểm tra có Quote Response cho Quote Request này không
  bool _hasQuoteResponseForRequest(String quoteRequestId) {
    return _messages.any((msg) {
      if (msg.type == MessageType.quoteResponse && msg.businessData != null) {
        final responseRequestId = msg.businessData!['quoteRequestMessageId'] as String?;
        return responseRequestId == quoteRequestId;
      }
      return false;
    });
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
      
      // Kiểm tra Quote Request sau khi load messages
      _checkPendingQuoteRequest();
      
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
          // Quick Actions Panel (chỉ hiển thị cho business chat)
          if (_chat?.isBusinessChat == true && _chat?.receiverType != null)
            _buildQuickActionsPanel(),
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

  // ==================== QUICK ACTIONS PANEL ====================
  
  Widget _buildQuickActionsPanel() {
    if (_chat?.receiverType == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_center, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                'Thao tác nhanh',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    final receiverType = _chat?.receiverType;
    if (receiverType == null) return const SizedBox.shrink();

    // Kiểm tra nếu có Quote Request chưa phản hồi và người dùng hiện tại là người nhận
    final hasPendingQuoteRequest = _pendingQuoteRequest != null;
    final isReceiver = _currentUserId != null && 
                      _pendingQuoteRequest != null && 
                      _pendingQuoteRequest!.senderId != _currentUserId;

    switch (receiverType) {
      case UserAccountType.designer:
        return _buildDesignerActions(hasPendingQuoteRequest: hasPendingQuoteRequest && isReceiver);
      case UserAccountType.contractor:
        return _buildContractorActions(hasPendingQuoteRequest: hasPendingQuoteRequest && isReceiver);
      case UserAccountType.store:
        return _buildStoreActions(hasPendingQuoteRequest: hasPendingQuoteRequest && isReceiver);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDesignerActions({bool hasPendingQuoteRequest = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: hasPendingQuoteRequest ? Icons.send : Icons.request_quote,
          label: hasPendingQuoteRequest ? 'Gửi báo giá' : 'Yêu cầu báo giá',
          onTap: hasPendingQuoteRequest
              ? () => _showQuoteResponseDialog()
              : () => _showQuoteRequestDialog(),
        ),
        _buildActionButton(
          icon: Icons.palette,
          label: 'Xem Portfolio',
          onTap: () => _showPortfolioDialog(),
        ),
        _buildActionButton(
          icon: Icons.calendar_today,
          label: 'Hẹn gặp',
          onTap: () => _showAppointmentDialog(),
        ),
      ],
    );
  }

  Widget _buildContractorActions({bool hasPendingQuoteRequest = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: hasPendingQuoteRequest ? Icons.send : Icons.request_quote,
          label: hasPendingQuoteRequest ? 'Gửi báo giá' : 'Yêu cầu báo giá',
          onTap: hasPendingQuoteRequest
              ? () => _showQuoteResponseDialog()
              : () => _showQuoteRequestDialog(),
        ),
        _buildActionButton(
          icon: Icons.timeline,
          label: 'Timeline dự án',
          onTap: () => _showTimelineDialog(),
        ),
        _buildActionButton(
          icon: Icons.calendar_today,
          label: 'Hẹn gặp',
          onTap: () => _showAppointmentDialog(),
        ),
      ],
    );
  }

  Widget _buildStoreActions({bool hasPendingQuoteRequest = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: hasPendingQuoteRequest ? Icons.send : Icons.request_quote,
          label: hasPendingQuoteRequest ? 'Gửi báo giá' : 'Yêu cầu báo giá',
          onTap: hasPendingQuoteRequest
              ? () => _showQuoteResponseDialog()
              : () => _showQuoteRequestDialog(),
        ),
        _buildActionButton(
          icon: Icons.inventory,
          label: 'Xem Catalog',
          onTap: () => _showMaterialCatalogDialog(),
        ),
        _buildActionButton(
          icon: Icons.calendar_today,
          label: 'Hẹn gặp',
          onTap: () => _showAppointmentDialog(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  /// Dialog để chủ thầu gửi báo giá (phản hồi Quote Request)
  Future<void> _showQuoteResponseDialog() async {
    if (_pendingQuoteRequest == null) {
      _showSnackBar('Không tìm thấy yêu cầu báo giá');
      return;
    }

    final quoteRequest = _pendingQuoteRequest!;
    final businessData = quoteRequest.businessData ?? {};
    
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    final laborCostController = TextEditingController(); // Chi phí nhân công
    final materialCostController = TextEditingController(); // Chi phí vật liệu
    final otherCostController = TextEditingController(); // Chi phí khác
    DateTime? estimatedCompletionDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('Gửi báo giá')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị thông tin yêu cầu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu báo giá:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (businessData['projectType'] != null)
                        Text('Loại dự án: ${businessData['projectType']}'),
                      if (businessData['projectDescription'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Mô tả: ${businessData['projectDescription']}'),
                      ],
                      if (businessData['estimatedBudget'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Ngân sách dự kiến: ${businessData['estimatedBudget']} triệu VNĐ'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Bảng báo giá
                Text(
                  'Chi tiết báo giá:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                // Bảng dạng Table
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[200]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Hạng mục',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Giá trị (triệu VNĐ)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Chi phí nhân công
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Chi phí nhân công'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: laborCostController,
                            decoration: InputDecoration(
                              hintText: 'VD: 20',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              final labor = double.tryParse(laborCostController.text) ?? 0;
                              final material = double.tryParse(materialCostController.text) ?? 0;
                              final other = double.tryParse(otherCostController.text) ?? 0;
                              final total = labor + material + other;
                              priceController.text = total > 0 ? total.toStringAsFixed(0) : '';
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    // Chi phí vật liệu
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Chi phí vật liệu'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: materialCostController,
                            decoration: InputDecoration(
                              hintText: 'VD: 30',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              final labor = double.tryParse(laborCostController.text) ?? 0;
                              final material = double.tryParse(materialCostController.text) ?? 0;
                              final other = double.tryParse(otherCostController.text) ?? 0;
                              final total = labor + material + other;
                              priceController.text = total > 0 ? total.toStringAsFixed(0) : '';
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    // Chi phí khác
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Chi phí khác'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: otherCostController,
                            decoration: InputDecoration(
                              hintText: 'VD: 5',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              final labor = double.tryParse(laborCostController.text) ?? 0;
                              final material = double.tryParse(materialCostController.text) ?? 0;
                              final other = double.tryParse(otherCostController.text) ?? 0;
                              final total = labor + material + other;
                              priceController.text = total > 0 ? total.toStringAsFixed(0) : '';
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    // Tổng cộng
                    TableRow(
                      decoration: BoxDecoration(color: Colors.green[50]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'TỔNG CỘNG',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              hintText: 'Tự động tính',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.green[100],
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Ngày hoàn thành dự kiến
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        estimatedCompletionDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày hoàn thành dự kiến',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      estimatedCompletionDate != null
                          ? '${estimatedCompletionDate!.day}/${estimatedCompletionDate!.month}/${estimatedCompletionDate!.year}'
                          : 'Chọn ngày',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Ghi chú
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú bổ sung',
                    hintText: 'Thông tin thêm về báo giá...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Tính tổng
                final labor = double.tryParse(laborCostController.text) ?? 0;
                final material = double.tryParse(materialCostController.text) ?? 0;
                final other = double.tryParse(otherCostController.text) ?? 0;
                final total = labor + material + other;

                if (total <= 0) {
                  _showSnackBar('Vui lòng nhập chi phí');
                  return;
                }

                // Cập nhật giá tổng
                priceController.text = total.toStringAsFixed(0);

                final messageId = await BusinessChatService.sendQuoteResponse(
                  chatId: widget.chatId,
                  quoteRequestMessageId: quoteRequest.id,
                  price: total,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                  estimatedCompletionDate: estimatedCompletionDate,
                );

                if (messageId != null && mounted) {
                  Navigator.pop(context);
                  await _loadMessages();
                  _showSnackBar('Đã gửi báo giá thành công');
                } else {
                  _showSnackBar('Lỗi khi gửi báo giá');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi báo giá'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuoteRequestDialog() async {
    final projectDescriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final projectTypeController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu báo giá'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: projectTypeController,
                decoration: const InputDecoration(
                  labelText: 'Loại dự án',
                  hintText: 'VD: Nhà ở dân dụng, Biệt thự...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: projectDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả dự án',
                  hintText: 'Mô tả chi tiết về dự án của bạn',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Ngân sách dự kiến (triệu VNĐ)',
                  hintText: 'VD: 50',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày bắt đầu dự kiến',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Chọn ngày',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (projectDescriptionController.text.isEmpty) {
                _showSnackBar('Vui lòng nhập mô tả dự án');
                return;
              }

              final receiverType = _chat?.receiverType;
              if (receiverType == null || _receiverId == null) {
                _showSnackBar('Lỗi: Không tìm thấy thông tin người nhận');
                return;
              }

              final budget = budgetController.text.isNotEmpty
                  ? double.tryParse(budgetController.text)
                  : null;

              final messageId = await BusinessChatService.sendQuoteRequest(
                chatId: widget.chatId,
                receiverId: _receiverId!,
                receiverType: receiverType,
                projectDescription: projectDescriptionController.text,
                estimatedBudget: budget,
                projectType: projectTypeController.text.isNotEmpty
                    ? projectTypeController.text
                    : null,
                expectedStartDate: selectedDate,
              );

              if (messageId != null && mounted) {
                Navigator.pop(context);
                await _loadMessages();
                _showSnackBar('Đã gửi yêu cầu báo giá');
              } else {
                _showSnackBar('Lỗi khi gửi yêu cầu');
              }
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAppointmentDialog() async {
    final locationController = TextEditingController();
    final purposeController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu hẹn gặp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    setState(() {});
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày hẹn',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Chọn ngày',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    selectedTime = time;
                    setState(() {});
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Giờ hẹn',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    selectedTime != null
                        ? selectedTime!.format(context)
                        : 'Chọn giờ',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm',
                  hintText: 'VD: Văn phòng, Công trường...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: 'Mục đích',
                  hintText: 'VD: Trao đổi về dự án, Xem mẫu...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Thông tin bổ sung...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (locationController.text.isEmpty || selectedDate == null) {
                _showSnackBar('Vui lòng nhập đầy đủ thông tin');
                return;
              }

              final dateTime = DateTime(
                selectedDate!.year,
                selectedDate!.month,
                selectedDate!.day,
                selectedTime?.hour ?? 9,
                selectedTime?.minute ?? 0,
              );

              final messageId = await BusinessChatService.sendAppointmentRequest(
                chatId: widget.chatId,
                requestedDate: dateTime,
                location: locationController.text,
                purpose: purposeController.text.isNotEmpty
                    ? purposeController.text
                    : null,
                notes: notesController.text.isNotEmpty
                    ? notesController.text
                    : null,
              );

              if (messageId != null && mounted) {
                Navigator.pop(context);
                await _loadMessages();
                _showSnackBar('Đã gửi yêu cầu hẹn gặp');
              } else {
                _showSnackBar('Lỗi khi gửi yêu cầu');
              }
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMaterialCatalogDialog() async {
    // Load materials
    final materials = await BusinessChatService.getUserMaterials();
    
    if (!mounted) return;
    
    if (materials.isEmpty) {
      _showSnackBar('Bạn chưa có vật liệu nào');
      return;
    }

    final selectedMaterials = <String>[];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chọn vật liệu'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                final isSelected = selectedMaterials.contains(material.id);
                
                return CheckboxListTile(
                  title: Text(material.name),
                  subtitle: Text('${material.category} - ${material.currentStock} ${material.unit}'),
                  value: isSelected,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedMaterials.add(material.id);
                      } else {
                        selectedMaterials.remove(material.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: selectedMaterials.isEmpty
                  ? null
                  : () async {
                      final messageId = await BusinessChatService.shareMaterialCatalog(
                        chatId: widget.chatId,
                        materialIds: selectedMaterials,
                      );

                      if (messageId != null && mounted) {
                        Navigator.pop(context);
                        await _loadMessages();
                        _showSnackBar('Đã chia sẻ catalog vật liệu');
                      } else {
                        _showSnackBar('Lỗi khi chia sẻ catalog');
                      }
                    },
              child: const Text('Chia sẻ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPortfolioDialog() async {
    final projectTitleController = TextEditingController();
    final projectDescriptionController = TextEditingController();
    List<File> selectedImages = [];
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chia sẻ Portfolio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: projectTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên dự án',
                    hintText: 'VD: Nhà phố 2 tầng, Biệt thự hiện đại...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projectDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả dự án',
                    hintText: 'Mô tả về dự án thiết kế...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  'Hình ảnh (${selectedImages.length} ảnh)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedImages.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final images = await ImageService.pickMultipleImagesFromGallery();
                      if (images.isNotEmpty) {
                        setDialogState(() {
                          selectedImages = images;
                        });
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Chọn ảnh'),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final images = await ImageService.pickMultipleImagesFromGallery();
                              if (images.isNotEmpty) {
                                setDialogState(() {
                                  selectedImages.addAll(images);
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm ảnh'),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (isUploading) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Đang tải ảnh lên...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: (selectedImages.isEmpty || isUploading)
                  ? null
                  : () async {
                      setDialogState(() {
                        isUploading = true;
                      });

                      final messageId = await BusinessChatService.sharePortfolioFromFiles(
                        chatId: widget.chatId,
                        imageFiles: selectedImages,
                        projectTitle: projectTitleController.text.isNotEmpty
                            ? projectTitleController.text
                            : null,
                        projectDescription: projectDescriptionController.text.isNotEmpty
                            ? projectDescriptionController.text
                            : null,
                      );

                      if (messageId != null && mounted) {
                        Navigator.pop(context);
                        await _loadMessages();
                        _showSnackBar('Đã chia sẻ portfolio');
                      } else {
                        setDialogState(() {
                          isUploading = false;
                        });
                        _showSnackBar('Lỗi khi chia sẻ portfolio');
                      }
                    },
              child: const Text('Chia sẻ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimelineDialog() async {
    final projectNameController = TextEditingController();
    final List<Map<String, dynamic>> milestones = [];
    DateTime? expectedStartDate;
    DateTime? expectedEndDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Timeline dự án'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: projectNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên dự án',
                    hintText: 'VD: Xây dựng nhà phố 2 tầng...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        expectedStartDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày bắt đầu dự kiến',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      expectedStartDate != null
                          ? '${expectedStartDate!.day}/${expectedStartDate!.month}/${expectedStartDate!.year}'
                          : 'Chọn ngày',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: expectedStartDate ?? DateTime.now(),
                      firstDate: expectedStartDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        expectedEndDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày kết thúc dự kiến',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      expectedEndDate != null
                          ? '${expectedEndDate!.day}/${expectedEndDate!.month}/${expectedEndDate!.year}'
                          : 'Chọn ngày',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Các mốc thời gian',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          milestones.add({
                            'name': '',
                            'date': null,
                            'description': '',
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm mốc'),
                    ),
                  ],
                ),
                if (milestones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Chưa có mốc thời gian nào',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...milestones.asMap().entries.map((entry) {
                    final index = entry.key;
                    final milestone = entry.value;
                    final nameController = TextEditingController(text: milestone['name'] ?? '');
                    final descriptionController = TextEditingController(text: milestone['description'] ?? '');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Mốc ${index + 1}',
                                      hintText: 'VD: Khởi công, Hoàn thiện...',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      milestones[index]['name'] = value;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setDialogState(() {
                                      milestones.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: expectedStartDate ?? DateTime.now(),
                                  firstDate: expectedStartDate ?? DateTime.now(),
                                  lastDate: expectedEndDate ?? DateTime.now().add(const Duration(days: 730)),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    milestones[index]['date'] = date.millisecondsSinceEpoch;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Ngày',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                  isDense: true,
                                ),
                                child: Text(
                                  milestone['date'] != null
                                      ? _formatDate(DateTime.fromMillisecondsSinceEpoch(milestone['date']))
                                      : 'Chọn ngày',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả',
                                hintText: 'Mô tả chi tiết...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              maxLines: 2,
                              onChanged: (value) {
                                milestones[index]['description'] = value;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: projectNameController.text.isEmpty || milestones.isEmpty
                  ? null
                  : () async {
                      final messageId = await BusinessChatService.shareProjectTimeline(
                        chatId: widget.chatId,
                        projectName: projectNameController.text,
                        milestones: milestones,
                        expectedStartDate: expectedStartDate,
                        expectedEndDate: expectedEndDate,
                      );

                      if (messageId != null && mounted) {
                        Navigator.pop(context);
                        await _loadMessages();
                        _showSnackBar('Đã chia sẻ timeline dự án');
                      } else {
                        _showSnackBar('Lỗi khi chia sẻ timeline');
                      }
                    },
              child: const Text('Chia sẻ'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}