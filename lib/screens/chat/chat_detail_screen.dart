import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../../models/project_pipeline.dart';
import '../../services/chat/chat_service.dart';
import '../../services/chat/business_chat_service.dart';
import '../../services/storage/file_storage_service.dart';
import '../../services/user/user_session.dart';
import '../../services/user/user_profile_service.dart';
import '../../services/project/pipeline_service.dart';
import '../../components/message_bubble.dart';
import '../profile/public_profile_screen.dart';

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
  UserAccountType? _receiverAccountType; // AccountType của người nhận (fallback nếu _chat?.receiverType == null)
  UserAccountType? _currentUserAccountType; // AccountType của người dùng hiện tại (để phân biệt Designer và Owner)
  ProjectPipeline? _pipeline; // Pipeline của dự án (nếu có)
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isUploading = false;
  double? _uploadProgress;
  bool _isPipelineExpanded = false; // Trạng thái collapse/expand của pipeline panel
  bool _isQuickActionsExpanded = false; // Trạng thái collapse/expand của quick actions panel

  @override
  void initState() {
    super.initState();
    // QUAN TRỌNG: Load chat info trước để có documentId (nếu có) trước khi load messages
    _loadChatInfo().then((_) {
      // Sau khi load chat info, load messages (để có thể truyền documentId vào getMessages)
      _loadMessages();
      // Load pipeline nếu có pipelineId
      if (_chat?.pipelineId != null) {
        _loadPipeline(_chat!.pipelineId!);
      }
    });
    _loadHeader();
  }
  
  Future<void> _loadChatInfo() async {
    try {
      print('🔍 Loading chat info for chatId: ${widget.chatId}');
      final chat = await ChatService.getChatById(widget.chatId);
      if (!mounted) return;
      
      print('🔍 Chat loaded: ${chat?.id}, isBusinessChat: ${chat?.isBusinessChat}, receiverType: ${chat?.receiverType}');
      
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
          
          // Lấy accountType của currentUser
          UserAccountType? currentUserAccountType;
          try {
            final currentUserProfile = await UserProfileService.getProfile(userId);
            if (currentUserProfile != null) {
              currentUserAccountType = currentUserProfile.accountType;
              print('📍 Current user accountType: $currentUserAccountType');
            }
          } catch (e) {
            print('⚠️ Error loading current user profile: $e');
          }
          
          // QUAN TRỌNG: Nếu chat chưa có receiverType, thử lấy từ user profile
          UserAccountType? receiverAccountType = chat.receiverType;
          if (receiverAccountType == null && otherUserId.isNotEmpty) {
            try {
              final receiverProfile = await UserProfileService.getProfile(otherUserId);
              if (receiverProfile != null) {
                receiverAccountType = receiverProfile.accountType;
                print('📍 Lấy receiverType từ user profile: $receiverAccountType');
                
                // Nếu receiverType là designer, contractor, hoặc store, cập nhật chat
                if (receiverAccountType == UserAccountType.designer ||
                    receiverAccountType == UserAccountType.contractor ||
                    receiverAccountType == UserAccountType.store) {
                  // Tạo chat mới với business context
                  final updatedChat = chat.copyWith(
                    chatType: ChatType.business,
                    receiverType: receiverAccountType,
                  );
                  setState(() {
                    _chat = updatedChat;
                    _receiverId = otherUserId;
                    _currentUserId = userId;
                    _receiverAccountType = receiverAccountType;
                    _currentUserAccountType = currentUserAccountType;
                  });
                  print('✅ Chat updated với business context: isBusinessChat=${updatedChat.isBusinessChat}, receiverType=${updatedChat.receiverType}');
                  
                  // Load pipeline nếu có pipelineId
                  if (updatedChat.pipelineId != null) {
                    await _loadPipeline(updatedChat.pipelineId!);
                  }
                } else {
                  setState(() {
                    _chat = chat;
                    _receiverId = otherUserId;
                    _currentUserId = userId;
                    _receiverAccountType = receiverAccountType;
                    _currentUserAccountType = currentUserAccountType;
                  });
                  
                  // Load pipeline nếu có pipelineId
                  if (chat.pipelineId != null) {
                    await _loadPipeline(chat.pipelineId!);
                  }
                }
              } else {
                setState(() {
                  _chat = chat;
                  _receiverId = otherUserId;
                  _currentUserId = userId;
                  _currentUserAccountType = currentUserAccountType;
                });
                
                // Load pipeline nếu có pipelineId
                if (chat.pipelineId != null) {
                  await _loadPipeline(chat.pipelineId!);
                }
              }
            } catch (e) {
              print('⚠️ Error loading receiver profile: $e');
              setState(() {
                _chat = chat;
                _receiverId = otherUserId;
                _currentUserId = userId;
                _currentUserAccountType = currentUserAccountType;
              });
              
              // Load pipeline nếu có pipelineId
              if (chat.pipelineId != null) {
                await _loadPipeline(chat.pipelineId!);
              }
            }
          } else {
            setState(() {
              _chat = chat;
              _receiverId = otherUserId;
              _currentUserId = userId;
              _receiverAccountType = receiverAccountType;
              _currentUserAccountType = currentUserAccountType;
            });
            print('✅ Chat info loaded: isBusinessChat=${chat.isBusinessChat}, receiverType=${chat.receiverType}, receiverId=$otherUserId');
            
            // Load pipeline nếu có pipelineId
            if (chat.pipelineId != null) {
              await _loadPipeline(chat.pipelineId!);
            }
          }
          // Kiểm tra Quote Request sau khi load messages
          _checkPendingQuoteRequest();
        } else {
          setState(() {
            _chat = chat;
          });
          
          // Load pipeline nếu có pipelineId
          if (chat.pipelineId != null) {
            await _loadPipeline(chat.pipelineId!);
          }
        }
      } else {
        setState(() {
          _chat = chat;
        });
        if (chat == null) {
          print('⚠️ Chat not found for chatId: ${widget.chatId}');
        } else {
          // Load pipeline nếu có pipelineId
          if (chat.pipelineId != null) {
            await _loadPipeline(chat.pipelineId!);
          }
        }
      }
    } catch (e) {
      print('❌ Error loading chat info: $e');
      if (!mounted) return;
      setState(() {
        _chat = null;
      });
    }
  }

  /// Kiểm tra có nên hiển thị Quick Actions Panel không
  bool _shouldShowQuickActions() {
    // 1. Nếu chat có business context, hiển thị
    if (_chat != null && _chat!.isBusinessChat && _chat!.receiverType != null) {
      return true;
    }
    
    // 2. Nếu có receiverType từ user profile (fallback), hiển thị
    if (_receiverAccountType != null && 
        (_receiverAccountType == UserAccountType.designer ||
         _receiverAccountType == UserAccountType.contractor ||
         _receiverAccountType == UserAccountType.store)) {
      return true;
    }
    
    // 3. Nếu có business messages, hiển thị
    if (_messages.any((msg) => 
        msg.type == MessageType.appointmentRequest ||
        msg.type == MessageType.appointmentConfirm ||
        msg.type == MessageType.quoteRequest ||
        msg.type == MessageType.quoteResponse ||
        msg.type == MessageType.portfolioShare ||
        msg.type == MessageType.materialCatalog ||
        msg.type == MessageType.projectTimeline)) {
      return true;
    }
    
    return false;
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
      // QUAN TRỌNG: Nếu chat có documentId khác với normalized ID, truyền documentId vào getMessages()
      // để query messages với cả 2 ID (fallback)
      final documentId = _chat?.documentId;
      final messages = await ChatService.getMessages(
        widget.chatId,
        documentId: documentId,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // QUAN TRỌNG: Reload chat info sau khi load messages
      // Vì getChatById() kiểm tra business messages để xác định business context
      // Nếu chat chưa có business context trong Firestore, cần reload để kiểm tra từ messages
      // HOẶC nếu có business messages nhưng chưa có receiverType, cần reload để lấy từ user profile
      final hasBusinessMessages = _messages.any((msg) => 
          msg.type == MessageType.appointmentRequest ||
          msg.type == MessageType.appointmentConfirm ||
          msg.type == MessageType.quoteRequest ||
          msg.type == MessageType.quoteResponse ||
          msg.type == MessageType.portfolioShare ||
          msg.type == MessageType.materialCatalog ||
          msg.type == MessageType.projectTimeline);
      
      if (_chat == null || 
          _chat!.chatType == ChatType.normal || 
          _chat!.receiverType == null ||
          (hasBusinessMessages && _chat!.receiverType == null)) {
        print('🔄 Reloading chat info after loading messages (checking for business context, hasBusinessMessages: $hasBusinessMessages)');
        await _loadChatInfo();
      }
      
      // Kiểm tra Quote Request sau khi load messages
      _checkPendingQuoteRequest();
      
      // Load pipeline nếu có pipelineId (sau khi reload chat info)
      if (_chat?.pipelineId != null && _pipeline == null) {
        await _loadPipeline(_chat!.pipelineId!);
      }
      
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
      print('❌ Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load pipeline từ pipelineId
  Future<void> _loadPipeline(String pipelineId) async {
    try {
      print('🔍 Loading pipeline: $pipelineId');
      final pipeline = await PipelineService.getPipeline(pipelineId);
      
      if (!mounted) return;
      
      setState(() {
        _pipeline = pipeline;
      });
      
      if (pipeline != null) {
        print('✅ Pipeline loaded: ${pipeline.projectName}, stage: ${pipeline.currentStage}');
      } else {
        print('⚠️ Pipeline not found: $pipelineId');
      }
    } catch (e) {
      print('❌ Error loading pipeline: $e');
      if (!mounted) return;
      setState(() {
        _pipeline = null;
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
          // Pipeline Status Panel (hiển thị nếu có pipeline)
          if (_pipeline != null)
            _buildPipelineStatusPanel(),
          // Quick Actions Panel (hiển thị cho business chat)
          // Hiển thị nếu:
          // 1. Chat có business context (isBusinessChat = true và receiverType != null)
          // 2. HOẶC có business messages trong chat
          // 3. HOẶC người nhận là designer, contractor, hoặc store
          if (_shouldShowQuickActions())
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
    // Lấy receiverType từ chat hoặc từ user profile (fallback)
    final receiverType = _chat?.receiverType ?? _receiverAccountType;
    
    // Nếu không có receiverType, không hiển thị panel
    if (receiverType == null) {
      // Nếu có business messages nhưng chưa có receiverType, hiển thị loading
      final hasBusinessMessages = _messages.any((msg) => 
          msg.type == MessageType.appointmentRequest ||
          msg.type == MessageType.appointmentConfirm ||
          msg.type == MessageType.quoteRequest ||
          msg.type == MessageType.quoteResponse ||
          msg.type == MessageType.portfolioShare ||
          msg.type == MessageType.materialCatalog ||
          msg.type == MessageType.projectTimeline);
      
      if (hasBusinessMessages && _receiverId != null) {
        // Đang load receiverType từ user profile
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.blue[200]!),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Đang tải thao tác nhanh...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (clickable để expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _isQuickActionsExpanded = !_isQuickActionsExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.business_center, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  Icon(
                    _isQuickActionsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Nội dung (chỉ hiển thị khi expanded)
          if (_isQuickActionsExpanded) ...[
            Divider(height: 1, color: Colors.blue[200]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildQuickActionButtons(receiverType),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(UserAccountType receiverType) {

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
    // Kiểm tra xem đã có pipeline chưa
    final hasPipeline = _pipeline != null;
    
    // Kiểm tra xem currentUser là Designer hay Owner
    // Designer: currentUserAccountType == UserAccountType.designer
    // Owner: currentUserAccountType == UserAccountType.general hoặc không phải designer/contractor/store
    final isCurrentUserDesigner = _currentUserAccountType == UserAccountType.designer;
    // Owner là người dùng thường (general) hoặc không phải business account
    final isCurrentUserOwner = _currentUserAccountType == null || 
                               _currentUserAccountType == UserAccountType.general ||
                               (_currentUserAccountType != UserAccountType.designer && 
                                _currentUserAccountType != UserAccountType.contractor && 
                                _currentUserAccountType != UserAccountType.store);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Nút "Bắt đầu hợp tác" - chỉ hiển thị khi chưa có pipeline
        if (!hasPipeline)
          _buildActionButton(
            icon: Icons.handshake,
            label: 'Bắt đầu hợp tác',
            onTap: () => _showStartCollaborationDialog(),
          ),
        // Các action khác - LUÔN hiển thị (cả khi chưa có pipeline)
        // Để trao đổi trước khi hợp tác
        _buildActionButton(
          icon: hasPendingQuoteRequest ? Icons.send : Icons.request_quote,
          label: hasPendingQuoteRequest ? 'Gửi báo giá' : 'Yêu cầu báo giá',
          onTap: hasPendingQuoteRequest
              ? () => _showQuoteResponseDialog()
              : () => _showQuoteRequestDialog(),
        ),
        // QUAN TRỌNG: Phân biệt Designer và Owner
        // - Nếu currentUser là Designer: Hiển thị "Gửi thiết kế" (chỉ khi có pipeline)
        // - Nếu currentUser là Owner (general user): Hiển thị "Xem Portfolio" (luôn hiển thị)
        if (isCurrentUserDesigner && hasPipeline)
          _buildActionButton(
            icon: Icons.upload_file,
            label: 'Gửi thiết kế',
            onTap: () => _showSendDesignDialog(),
          )
        else if (isCurrentUserOwner && _receiverId != null)
          _buildActionButton(
            icon: Icons.palette,
            label: 'Xem Portfolio',
            onTap: () => _viewPortfolio(),
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
    // Kiểm tra xem đã có pipeline chưa
    final hasPipeline = _pipeline != null;
    
    // Kiểm tra xem currentUser là Contractor hay Owner
    final isCurrentUserContractor = _currentUserAccountType == UserAccountType.contractor;
    // Owner là người dùng thường (general) hoặc không phải business account
    final isCurrentUserOwner = _currentUserAccountType == null || 
                               _currentUserAccountType == UserAccountType.general ||
                               (_currentUserAccountType != UserAccountType.designer && 
                                _currentUserAccountType != UserAccountType.contractor && 
                                _currentUserAccountType != UserAccountType.store);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Nút "Bắt đầu hợp tác" - chỉ hiển thị khi chưa có pipeline
        if (!hasPipeline)
          _buildActionButton(
            icon: Icons.handshake,
            label: 'Bắt đầu hợp tác',
            onTap: () => _showStartCollaborationDialog(),
          ),
        // Các action khác - LUÔN hiển thị (cả khi chưa có pipeline)
        // Để trao đổi trước khi hợp tác
        _buildActionButton(
          icon: hasPendingQuoteRequest ? Icons.send : Icons.request_quote,
          label: hasPendingQuoteRequest ? 'Gửi báo giá' : 'Yêu cầu báo giá',
          onTap: hasPendingQuoteRequest
              ? () => _showQuoteResponseDialog()
              : () => _showQuoteRequestDialog(),
        ),
        // QUAN TRỌNG: Phân biệt Contractor và Owner
        // - Nếu currentUser là Contractor: Hiển thị "Gửi kế hoạch thi công" (chỉ khi có pipeline)
        // - Nếu currentUser là Owner (general user): Hiển thị "Xem Portfolio" (luôn hiển thị)
        if (isCurrentUserContractor && hasPipeline)
          _buildActionButton(
            icon: Icons.upload_file,
            label: 'Gửi kế hoạch thi công',
            onTap: () => _showSendConstructionPlanDialog(),
          )
        else if (isCurrentUserOwner && _receiverId != null)
          _buildActionButton(
            icon: Icons.palette,
            label: 'Xem Portfolio',
            onTap: () => _viewPortfolio(),
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
    // Kiểm tra xem đã có pipeline chưa
    final hasPipeline = _pipeline != null;
    
    // Kiểm tra xem currentUser là Store hay Owner
    final isCurrentUserStore = _currentUserAccountType == UserAccountType.store;
    // Owner là người dùng thường (general) hoặc không phải business account
    final isCurrentUserOwner = _currentUserAccountType == null || 
                               _currentUserAccountType == UserAccountType.general ||
                               (_currentUserAccountType != UserAccountType.designer && 
                                _currentUserAccountType != UserAccountType.contractor && 
                                _currentUserAccountType != UserAccountType.store);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Nút "Bắt đầu hợp tác" - chỉ hiển thị khi chưa có pipeline
        if (!hasPipeline)
          _buildActionButton(
            icon: Icons.handshake,
            label: 'Bắt đầu hợp tác',
            onTap: () => _showStartCollaborationDialog(),
          ),
        // Các action khác - LUÔN hiển thị (cả khi chưa có pipeline)
        // Để trao đổi trước khi hợp tác
        _buildActionButton(
          icon: hasPendingQuoteRequest ? Icons.send : Icons.request_quote,
          label: hasPendingQuoteRequest ? 'Gửi báo giá' : 'Yêu cầu báo giá',
          onTap: hasPendingQuoteRequest
              ? () => _showQuoteResponseDialog()
              : () => _showQuoteRequestDialog(),
        ),
        // QUAN TRỌNG: Phân biệt Store và Owner
        // - Nếu currentUser là Store: Hiển thị "Gửi báo giá vật liệu" (chỉ khi có pipeline)
        // - Nếu currentUser là Owner (general user): Hiển thị "Xem Portfolio" (luôn hiển thị)
        if (isCurrentUserStore && hasPipeline)
          _buildActionButton(
            icon: Icons.upload_file,
            label: 'Gửi báo giá vật liệu',
            onTap: () => _showSendMaterialQuoteDialog(),
          )
        else if (isCurrentUserOwner && _receiverId != null)
          _buildActionButton(
            icon: Icons.palette,
            label: 'Xem Portfolio',
            onTap: () => _viewPortfolio(),
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
    
    // Phase 1 Enhancement: Load user projects
    List<ProjectPipeline> userProjects = [];
    String? selectedProjectId;
    bool isLoadingProjects = true;
    
    try {
      userProjects = await PipelineService.getUserPipelines();
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser != null) {
        final userId = currentUser['userId']?.toString();
        if (userId != null) {
          userProjects = userProjects.where((p) => p.ownerId == userId).toList();
        }
      }
    } catch (e) {
      print('❌ Error loading user projects: $e');
    }
    isLoadingProjects = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper function để tự động điền thông tin từ dự án đã chọn
          void _fillProjectInfo(ProjectPipeline? project) {
            if (project == null) return;
            
            // Điền projectType
            String? projectTypeText;
            switch (project.projectType) {
              case ProjectType.residential:
                projectTypeText = 'Nhà ở';
                break;
              case ProjectType.office:
                projectTypeText = 'Văn phòng';
                break;
              case ProjectType.commercial:
                projectTypeText = 'Thương mại';
                break;
              case ProjectType.industrial:
                projectTypeText = 'Công nghiệp';
                break;
              case ProjectType.other:
                projectTypeText = 'Khác';
                break;
              default:
                projectTypeText = null;
            }
            if (projectTypeText != null) {
              projectTypeController.text = projectTypeText;
            }
            
            // Điền description
            if (project.description != null && project.description!.isNotEmpty) {
              projectDescriptionController.text = project.description!;
            }
            
            // Điền budget theo loại đối tác
            final receiverType = _chat?.receiverType ?? _receiverAccountType;
            double? budget;
            if (receiverType != null) {
              budget = project.getBudgetForPartnerType(receiverType);
            }
            if (budget != null) {
              budgetController.text = budget.toStringAsFixed(0);
            }
            
            // Điền startDate
            if (project.startDate != null) {
              selectedDate = project.startDate;
            }
          }
          
          return AlertDialog(
            title: const Text('Yêu cầu báo giá'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase 1 Enhancement: Dropdown chọn dự án
                  if (isLoadingProjects)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else ...[
                    DropdownButtonFormField<String?>(
                      value: selectedProjectId,
                      isExpanded: true, // Quan trọng: Để tránh overflow
                      decoration: const InputDecoration(
                        labelText: 'Chọn dự án (tùy chọn)',
                        hintText: 'Tạo mới',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_special),
                        helperText: 'Chọn dự án để tự động điền thông tin',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Tạo mới (nhập thông tin)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ...userProjects.map((project) {
                          return DropdownMenuItem(
                            value: project.id,
                            child: Text(
                              project.projectName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedProjectId = value;
                          // Tự động điền thông tin khi chọn dự án
                          if (value != null) {
                            final project = userProjects.firstWhere(
                              (p) => p.id == value,
                              orElse: () => userProjects.first,
                            );
                            _fillProjectInfo(project);
                          } else {
                            // Xóa thông tin khi chọn "Tạo mới"
                            projectTypeController.clear();
                            projectDescriptionController.clear();
                            budgetController.clear();
                            selectedDate = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
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
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
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

                  // Sử dụng receiverType từ chat hoặc từ user profile (fallback)
                  final receiverType = _chat?.receiverType ?? _receiverAccountType;
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
                    projectId: selectedProjectId, // Phase 1: Lưu projectId
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
          );
        },
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

  // ==================== PIPELINE STATUS PANEL ====================

  /// Widget hiển thị pipeline status panel
  Widget _buildPipelineStatusPanel() {
    if (_pipeline == null) return const SizedBox.shrink();
    
    final pipeline = _pipeline!;
    final receiverType = _chat?.receiverType ?? _receiverAccountType;
    
    // Xác định collaboration status dựa trên receiverType
    CollaborationStatus currentStatus;
    String statusDescription;
    String stageName;
    
    if (receiverType == UserAccountType.designer) {
      currentStatus = pipeline.designStatus;
      statusDescription = _getStatusDescription(pipeline.designStatus, pipeline.designerName ?? 'nhà thiết kế');
      stageName = 'Thiết kế';
    } else if (receiverType == UserAccountType.contractor) {
      currentStatus = pipeline.constructionStatus;
      statusDescription = _getStatusDescription(pipeline.constructionStatus, pipeline.contractorName ?? 'chủ thầu');
      stageName = 'Thi công';
    } else if (receiverType == UserAccountType.store) {
      currentStatus = pipeline.materialsStatus;
      statusDescription = _getStatusDescription(pipeline.materialsStatus, pipeline.storeName ?? 'cửa hàng VLXD');
      stageName = 'Vật liệu';
    } else {
      // Nếu không có receiverType phù hợp, hiển thị theo currentStage
      switch (pipeline.currentStage) {
        case PipelineStage.design:
          currentStatus = pipeline.designStatus;
          statusDescription = _getStatusDescription(pipeline.designStatus, pipeline.designerName ?? 'nhà thiết kế');
          stageName = 'Thiết kế';
          break;
        case PipelineStage.construction:
          currentStatus = pipeline.constructionStatus;
          statusDescription = _getStatusDescription(pipeline.constructionStatus, pipeline.contractorName ?? 'chủ thầu');
          stageName = 'Thi công';
          break;
        case PipelineStage.materials:
          currentStatus = pipeline.materialsStatus;
          statusDescription = _getStatusDescription(pipeline.materialsStatus, pipeline.storeName ?? 'cửa hàng VLXD');
          stageName = 'Vật liệu';
          break;
      }
    }
    
    // Màu sắc dựa trên status
    Color statusColor;
    switch (currentStatus) {
      case CollaborationStatus.none:
        statusColor = Colors.grey;
        break;
      case CollaborationStatus.requested:
        statusColor = Colors.orange;
        break;
      case CollaborationStatus.accepted:
        statusColor = Colors.blue;
        break;
      case CollaborationStatus.inProgress:
        statusColor = Colors.blue[700]!;
        break;
      case CollaborationStatus.completed:
        statusColor = Colors.green;
        break;
      case CollaborationStatus.cancelled:
        statusColor = Colors.red;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (clickable để expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _isPipelineExpanded = !_isPipelineExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.account_tree, size: 18, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pipeline dự án',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Icon(
                    _isPipelineExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Nội dung (chỉ hiển thị khi expanded)
          if (_isPipelineExpanded) ...[
            Divider(height: 1, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project name
                  Text(
                    pipeline.projectName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stage và status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stageName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Progress indicator
                  const SizedBox(height: 12),
                  _buildPipelineProgress(pipeline),
                  // Action buttons (nếu cần)
                  if (_shouldShowCollaborationActions(currentStatus, receiverType)) ...[
                    const SizedBox(height: 12),
                    _buildCollaborationActions(pipeline, currentStatus, receiverType),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Widget hiển thị pipeline progress (3 stages: design, construction, materials)
  Widget _buildPipelineProgress(ProjectPipeline pipeline) {
    return Column(
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: _buildStageIndicator(
                'Thiết kế',
                pipeline.currentStage == PipelineStage.design,
                pipeline.designStatus == CollaborationStatus.completed,
                pipeline.designStatus == CollaborationStatus.inProgress || pipeline.designStatus == CollaborationStatus.accepted,
              ),
            ),
            Expanded(
              child: _buildStageIndicator(
                'Thi công',
                pipeline.currentStage == PipelineStage.construction,
                pipeline.constructionStatus == CollaborationStatus.completed,
                pipeline.constructionStatus == CollaborationStatus.inProgress || pipeline.constructionStatus == CollaborationStatus.accepted,
              ),
            ),
            Expanded(
              child: _buildStageIndicator(
                'Vật liệu',
                pipeline.currentStage == PipelineStage.materials,
                pipeline.materialsStatus == CollaborationStatus.completed,
                pipeline.materialsStatus == CollaborationStatus.inProgress || pipeline.materialsStatus == CollaborationStatus.accepted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Widget hiển thị stage indicator
  Widget _buildStageIndicator(String label, bool isCurrent, bool isCompleted, bool isActive) {
    Color color;
    IconData icon;
    
    if (isCompleted) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (isActive || isCurrent) {
      color = Colors.blue;
      icon = isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    } else {
      color = Colors.grey;
      icon = Icons.circle_outlined;
    }
    
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Kiểm tra xem có nên hiển thị collaboration actions không
  bool _shouldShowCollaborationActions(CollaborationStatus status, UserAccountType? receiverType) {
    if (_currentUserId == null || _pipeline == null) return false;
    
    // Chỉ hiển thị actions nếu người dùng hiện tại là người được mời hợp tác
    // (designer, contractor, hoặc store) và status là requested
    if (status == CollaborationStatus.requested) {
      // Kiểm tra xem người dùng hiện tại có phải là designer/contractor/store trong pipeline không
      // (không cần kiểm tra receiverType vì có thể khác nhau tùy theo người mở chat)
      if (_pipeline!.designerId == _currentUserId && _pipeline!.designStatus == CollaborationStatus.requested) {
        return true;
      }
      if (_pipeline!.contractorId == _currentUserId && _pipeline!.constructionStatus == CollaborationStatus.requested) {
        return true;
      }
      if (_pipeline!.storeId == _currentUserId && _pipeline!.materialsStatus == CollaborationStatus.requested) {
        return true;
      }
    }
    
    return false;
  }

  /// Widget hiển thị collaboration actions
  Widget _buildCollaborationActions(ProjectPipeline pipeline, CollaborationStatus status, UserAccountType? receiverType) {
    if (status != CollaborationStatus.requested) return const SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _acceptCollaboration(pipeline.id, receiverType),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Chấp nhận'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _cancelCollaboration(pipeline.id, receiverType),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Từ chối'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  /// Chấp nhận collaboration
  Future<void> _acceptCollaboration(String pipelineId, UserAccountType? receiverType) async {
    try {
      if (_pipeline == null || _currentUserId == null) {
        _showSnackBar('Lỗi: Không tìm thấy thông tin pipeline');
        return;
      }
      
      bool success = false;
      
      // Xác định loại collaboration dựa trên pipeline và currentUserId
      if (_pipeline!.designerId == _currentUserId && _pipeline!.designStatus == CollaborationStatus.requested) {
        success = await PipelineService.acceptDesignCollaboration(pipelineId);
      } else if (_pipeline!.contractorId == _currentUserId && _pipeline!.constructionStatus == CollaborationStatus.requested) {
        success = await PipelineService.acceptConstructionCollaboration(pipelineId);
      } else if (_pipeline!.storeId == _currentUserId && _pipeline!.materialsStatus == CollaborationStatus.requested) {
        success = await PipelineService.acceptMaterialsCollaboration(pipelineId);
      } else {
        _showSnackBar('Lỗi: Không thể chấp nhận hợp tác');
        return;
      }
      
      if (success && mounted) {
        _showSnackBar('Đã chấp nhận hợp tác');
        // Reload pipeline
        await _loadPipeline(pipelineId);
        // Reload chat info để cập nhật collaboration status
        await _loadChatInfo();
      } else {
        _showSnackBar('Lỗi khi chấp nhận hợp tác');
      }
    } catch (e) {
      print('❌ Error accepting collaboration: $e');
      _showSnackBar('Lỗi: $e');
    }
  }

  /// Hủy collaboration
  Future<void> _cancelCollaboration(String pipelineId, UserAccountType? receiverType) async {
    try {
      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc chắn muốn từ chối hợp tác không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      );
      
      if (confirmed == true && mounted) {
        // TODO: Implement cancel collaboration in PipelineService
        // Hiện tại chỉ hiển thị thông báo
        _showSnackBar('Chức năng từ chối hợp tác đang được phát triển');
      }
    } catch (e) {
      print('❌ Error cancelling collaboration: $e');
      _showSnackBar('Lỗi: $e');
    }
  }

  /// Lấy mô tả status
  String _getStatusDescription(CollaborationStatus status, String partnerName) {
    switch (status) {
      case CollaborationStatus.none:
        return 'Chưa hợp tác';
      case CollaborationStatus.requested:
        return 'Đã gửi yêu cầu hợp tác';
      case CollaborationStatus.accepted:
        return 'Đã chấp nhận hợp tác';
      case CollaborationStatus.inProgress:
        return 'Đang hợp tác với $partnerName';
      case CollaborationStatus.completed:
        return 'Đã hoàn thành';
      case CollaborationStatus.cancelled:
        return 'Đã hủy hợp tác';
    }
  }

  // ==================== START COLLABORATION ====================

  /// Dialog để bắt đầu hợp tác (tạo pipeline)
  Future<void> _showStartCollaborationDialog() async {
    if (_receiverId == null || _currentUserId == null) {
      _showSnackBar('Lỗi: Không tìm thấy thông tin người dùng');
      return;
    }

    final receiverType = _chat?.receiverType ?? _receiverAccountType;
    if (receiverType == null) {
      _showSnackBar('Lỗi: Không xác định được loại đối tác');
      return;
    }

    // Chỉ hỗ trợ Designer, Contractor, Store
    if (receiverType != UserAccountType.designer &&
        receiverType != UserAccountType.contractor &&
        receiverType != UserAccountType.store) {
      _showSnackBar('Tính năng hợp tác chỉ áp dụng cho Designer, Contractor hoặc Store');
      return;
    }

    // Phase 1 Enhancement: Load user projects (chỉ nếu user là owner)
    final isCurrentUserOwner = _currentUserAccountType == null || 
                               _currentUserAccountType == UserAccountType.general;
    
    List<ProjectPipeline> userProjects = [];
    String? selectedProjectId;
    
    if (isCurrentUserOwner) {
      try {
        final allProjects = await PipelineService.getUserPipelines();
        final currentUser = await UserSession.getCurrentUser();
        if (currentUser != null) {
          final userId = currentUser['userId']?.toString();
          if (userId != null) {
            // Chỉ lấy projects mà user là owner
            userProjects = allProjects.where((p) => p.ownerId == userId).toList();
          }
        }
      } catch (e) {
        print('❌ Error loading user projects: $e');
      }
    }

    final projectNameController = TextEditingController();
    String? selectedPartnerId;
    String? selectedPartnerName;
    UserProfile? partnerProfile; // Lưu profile đầy đủ để hiển thị

    // Lấy thông tin đối tác (đầy đủ)
    if (receiverType == UserAccountType.designer) {
      selectedPartnerId = _receiverId;
      try {
        partnerProfile = await UserProfileService.getProfile(_receiverId!);
        selectedPartnerName = partnerProfile?.name ?? _titleName ?? 'Designer';
      } catch (e) {
        selectedPartnerName = _titleName ?? 'Designer';
      }
    } else if (receiverType == UserAccountType.contractor) {
      selectedPartnerId = _receiverId;
      try {
        partnerProfile = await UserProfileService.getProfile(_receiverId!);
        selectedPartnerName = partnerProfile?.name ?? _titleName ?? 'Contractor';
      } catch (e) {
        selectedPartnerName = _titleName ?? 'Contractor';
      }
    } else if (receiverType == UserAccountType.store) {
      selectedPartnerId = _receiverId;
      try {
        partnerProfile = await UserProfileService.getProfile(_receiverId!);
        selectedPartnerName = partnerProfile?.name ?? _titleName ?? 'Store';
      } catch (e) {
        selectedPartnerName = _titleName ?? 'Store';
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.handshake, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('Bắt đầu hợp tác')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đang bắt đầu hợp tác với:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                // Card hiển thị đối tác - Design chuyên nghiệp
                _buildPartnerCard(
                  partnerProfile: partnerProfile,
                  partnerName: selectedPartnerName ?? 'Đối tác',
                  partnerType: receiverType,
                ),
                const SizedBox(height: 20),
                
                // Phase 1 Enhancement: Dropdown chọn dự án (chỉ nếu user là owner)
                if (isCurrentUserOwner && userProjects.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: selectedProjectId,
                    isExpanded: true, // Quan trọng: Để tránh overflow
                    decoration: const InputDecoration(
                      labelText: 'Chọn dự án (tùy chọn)',
                      hintText: 'Tạo mới',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_special),
                      helperText: 'Chọn dự án để liên kết với pipeline',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Tạo mới (nhập tên dự án)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ...userProjects.map((project) {
                        return DropdownMenuItem(
                          value: project.id,
                          child: Text(
                            project.projectName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProjectId = value;
                        // Tự động điền tên dự án khi chọn dự án
                        if (value != null) {
                          final project = userProjects.firstWhere(
                            (p) => p.id == value,
                            orElse: () => userProjects.first,
                          );
                          projectNameController.text = project.projectName;
                        } else {
                          // Xóa tên dự án khi chọn "Tạo mới"
                          projectNameController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                TextField(
                  controller: projectNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên dự án (tùy chọn)',
                    hintText: isCurrentUserOwner && userProjects.isNotEmpty
                        ? 'Tên dự án sẽ tự động điền nếu chọn ở trên'
                        : 'VD: Nhà phố 2 tầng, Biệt thự hiện đại...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.architecture),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Sau khi bắt đầu hợp tác, bạn sẽ có thể:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ..._getCollaborationBenefits(receiverType),
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
              final projectName = projectNameController.text.trim().isEmpty
                  ? null
                  : projectNameController.text.trim();

              // Tạo pipeline
              String? pipelineId;
              try {
                // Lấy search context từ chat (nếu có)
                final searchContext = _chat?.searchContext ?? '';

                // Tạo search metadata
                final searchMetadata = <String, dynamic>{
                  'searchCriteria': searchContext,
                  'searchedType': receiverType.name,
                  'chatId': widget.chatId,
                  'startedAt': DateTime.now().millisecondsSinceEpoch,
                };

                if (receiverType == UserAccountType.designer) {
                  pipelineId = await PipelineService.createPipelineFromDesignerSearch(
                    designerId: selectedPartnerId!,
                    designerName: selectedPartnerName ?? 'Designer',
                    searchMetadata: searchMetadata,
                    projectName: projectName,
                    projectId: selectedProjectId, // Phase 1: Link với dự án đã chọn
                  );
                } else if (receiverType == UserAccountType.contractor) {
                  pipelineId = await PipelineService.createPipelineFromContractorSearch(
                    contractorId: selectedPartnerId!,
                    contractorName: selectedPartnerName ?? 'Contractor',
                    searchMetadata: searchMetadata,
                    projectName: projectName,
                    projectId: selectedProjectId, // Phase 1: Link với dự án đã chọn
                  );
                } else if (receiverType == UserAccountType.store) {
                  pipelineId = await PipelineService.createPipelineFromStoreSearch(
                    storeId: selectedPartnerId!,
                    storeName: selectedPartnerName ?? 'Store',
                    searchMetadata: searchMetadata,
                    projectName: projectName,
                    projectId: selectedProjectId, // Phase 1: Link với dự án đã chọn
                  );
                }

                if (pipelineId != null && mounted) {
                  // Cập nhật chat với pipelineId
                  await ChatService.updateChatPipelineId(widget.chatId, pipelineId);

                  // Reload pipeline và chat info
                  await _loadPipeline(pipelineId);
                  await _loadChatInfo();

                  Navigator.pop(context);
                  _showSnackBar('Đã bắt đầu hợp tác thành công');
                } else {
                  _showSnackBar('Lỗi khi tạo pipeline');
                }
              } catch (e) {
                print('❌ Error starting collaboration: $e');
                if (mounted) {
                  _showSnackBar('Lỗi: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Bắt đầu hợp tác'),
          ),
        ],
      ),
        ),
    );
  }

  /// Widget hiển thị card đối tác chuyên nghiệp
  Widget _buildPartnerCard({
    UserProfile? partnerProfile,
    required String partnerName,
    required UserAccountType partnerType,
  }) {
    // Xác định màu sắc và icon theo loại đối tác
    Color primaryColor;
    Color backgroundColor;
    IconData icon;
    String typeLabel;
    
    switch (partnerType) {
      case UserAccountType.designer:
        primaryColor = Colors.purple[700]!;
        backgroundColor = Colors.purple[50]!;
        icon = Icons.palette;
        typeLabel = 'Nhà thiết kế';
        break;
      case UserAccountType.contractor:
        primaryColor = Colors.orange[700]!;
        backgroundColor = Colors.orange[50]!;
        icon = Icons.construction;
        typeLabel = 'Chủ thầu';
        break;
      case UserAccountType.store:
        primaryColor = Colors.green[700]!;
        backgroundColor = Colors.green[50]!;
        icon = Icons.store;
        typeLabel = 'Cửa hàng VLXD';
        break;
      default:
        primaryColor = Colors.blue[700]!;
        backgroundColor = Colors.blue[50]!;
        icon = Icons.person;
        typeLabel = 'Đối tác';
    }

    // Lấy avatar URL
    final avatarUrl = partnerProfile?.avatarUrl ?? partnerProfile?.pic;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar với badge
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: primaryColor.withOpacity(0.1),
                              child: Icon(
                                icon,
                                size: 32,
                                color: primaryColor,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: primaryColor.withOpacity(0.1),
                          child: Icon(
                            icon,
                            size: 32,
                            color: primaryColor,
                          ),
                        ),
                ),
              ),
              // Badge loại đối tác
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Thông tin đối tác
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên đối tác
                Text(
                  partnerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Loại đối tác
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                // Rating (nếu có)
                if (partnerProfile != null && partnerProfile.rating > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${partnerProfile.rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (partnerProfile.reviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${partnerProfile.reviewCount} đánh giá)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Icon mũi tên
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: primaryColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// Lấy danh sách lợi ích hợp tác theo loại đối tác
  List<Widget> _getCollaborationBenefits(UserAccountType receiverType) {
    switch (receiverType) {
      case UserAccountType.designer:
        return [
          _buildBenefitItem('✓ Theo dõi tiến độ thiết kế'),
          _buildBenefitItem('✓ Chia sẻ file thiết kế'),
          _buildBenefitItem('✓ Trao đổi về dự án'),
          _buildBenefitItem('✓ Yêu cầu báo giá'),
        ];
      case UserAccountType.contractor:
        return [
          _buildBenefitItem('✓ Theo dõi tiến độ thi công'),
          _buildBenefitItem('✓ Chia sẻ kế hoạch thi công'),
          _buildBenefitItem('✓ Trao đổi về dự án'),
          _buildBenefitItem('✓ Yêu cầu báo giá'),
        ];
      case UserAccountType.store:
        return [
          _buildBenefitItem('✓ Xem catalog vật liệu'),
          _buildBenefitItem('✓ Yêu cầu báo giá'),
          _buildBenefitItem('✓ Theo dõi đơn hàng'),
          _buildBenefitItem('✓ Trao đổi về sản phẩm'),
        ];
      default:
        return [];
    }
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SEND DESIGN & VIEW PORTFOLIO ====================

  /// Dialog để Designer gửi thiết kế (PDF)
  Future<void> _showSendDesignDialog() async {
    if (_currentUserId == null || _receiverId == null) {
      _showSnackBar('Lỗi: Không tìm thấy thông tin người dùng');
      return;
    }

    if (_pipeline == null) {
      _showSnackBar('Lỗi: Chưa có pipeline. Vui lòng bắt đầu hợp tác trước.');
      return;
    }

    // Kiểm tra xem currentUser có phải là Designer không
    if (_currentUserAccountType != UserAccountType.designer) {
      _showSnackBar('Lỗi: Chỉ Designer mới có thể gửi thiết kế');
      return;
    }

    // Kiểm tra xem Designer có phải là designer trong pipeline không
    if (_pipeline!.designerId != _currentUserId) {
      _showSnackBar('Lỗi: Bạn không phải là Designer của dự án này');
      return;
    }

    final designNameController = TextEditingController();
    final designDescriptionController = TextEditingController();
    File? selectedDesignFile;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('Gửi thiết kế')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn file thiết kế (PDF)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedDesignFile == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FileStorageService.pickFile();
                      if (result != null && result.files.single.path != null) {
                        final filePath = result.files.single.path!;
                        final file = File(filePath);
                        final fileName = result.files.single.name;
                        
                        // Kiểm tra file extension
                        if (!fileName.toLowerCase().endsWith('.pdf')) {
                          _showSnackBar('Vui lòng chọn file PDF');
                          return;
                        }
                        
                        setDialogState(() {
                          selectedDesignFile = file;
                          designNameController.text = fileName;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Chọn file PDF'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedDesignFile!.path.split('/').last,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF File',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              selectedDesignFile = null;
                              designNameController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: designNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thiết kế (tùy chọn)',
                    hintText: 'VD: Thiết kế nhà phố 2 tầng...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: designDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả thiết kế (tùy chọn)',
                    hintText: 'Mô tả về thiết kế...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Đang upload file...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
              onPressed: (selectedDesignFile == null || isUploading)
                  ? null
                  : () async {
                      setDialogState(() {
                        isUploading = true;
                      });

                      try {
                        // Upload file PDF lên Firebase Storage
                        final fileUrl = await FileStorageService.uploadFile(
                          file: selectedDesignFile!,
                          chatId: widget.chatId,
                          userId: _currentUserId!,
                        );

                        if (fileUrl == null) {
                          if (mounted) {
                            _showSnackBar('Lỗi khi upload file');
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                          return;
                        }

                        // Gửi message với file PDF
                        final fileName = designNameController.text.isNotEmpty
                            ? designNameController.text
                            : selectedDesignFile!.path.split('/').last;
                        final fileSize = await selectedDesignFile!.length();

                        final messageContent = designDescriptionController.text.isNotEmpty
                            ? '📐 Đã gửi thiết kế: $fileName\n\n${designDescriptionController.text}'
                            : '📐 Đã gửi thiết kế: $fileName';

                        final messageId = await ChatService.sendMessage(
                          chatId: widget.chatId,
                          content: messageContent,
                          type: MessageType.file,
                          fileUrl: fileUrl,
                          fileName: fileName,
                          fileSize: fileSize,
                        );

                        if (messageId != null) {
                          // Cập nhật pipeline với designFileUrl (nếu có pipeline)
                          if (_pipeline != null) {
                            try {
                              // Cập nhật pipeline với designFileUrl
                              // Lưu ý: Chỉ cập nhật designFileUrl, không thay đổi status
                              // Status sẽ được cập nhật khi Designer hoàn thành thiết kế (completeDesign)
                              await PipelineService.updateDesignFileUrl(
                                pipelineId: _pipeline!.id,
                                designFileUrl: fileUrl,
                              );
                              
                              // Reload pipeline để cập nhật UI
                              await _loadPipeline(_pipeline!.id);
                              
                              print('✅ Design file URL updated in pipeline: $fileUrl');
                            } catch (e) {
                              print('⚠️ Error updating pipeline with design file URL: $e');
                              // Tiếp tục dù pipeline update lỗi
                            }
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            await _loadMessages();
                            _showSnackBar('Đã gửi thiết kế thành công');
                          }
                        } else {
                          if (mounted) {
                            _showSnackBar('Lỗi khi gửi tin nhắn');
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                        }
                      } catch (e) {
                        print('❌ Error sending design: $e');
                        if (mounted) {
                          _showSnackBar('Lỗi: $e');
                          setDialogState(() {
                            isUploading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi thiết kế'),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate đến Profile Screen của Designer/Contractor/Store (cho Owner xem Portfolio)
  Future<void> _viewPortfolio() async {
    if (_receiverId == null) {
      _showSnackBar('Lỗi: Không tìm thấy thông tin người dùng');
      return;
    }

    // Navigate đến PublicProfileScreen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PublicProfileScreen(userId: _receiverId!),
        ),
      );
    }
  }

  /// Dialog để Contractor gửi kế hoạch thi công (PDF)
  Future<void> _showSendConstructionPlanDialog() async {
    if (_currentUserId == null || _receiverId == null) {
      _showSnackBar('Lỗi: Không tìm thấy thông tin người dùng');
      return;
    }

    if (_pipeline == null) {
      _showSnackBar('Lỗi: Chưa có pipeline. Vui lòng bắt đầu hợp tác trước.');
      return;
    }

    // Kiểm tra xem currentUser có phải là Contractor không
    if (_currentUserAccountType != UserAccountType.contractor) {
      _showSnackBar('Lỗi: Chỉ Contractor mới có thể gửi kế hoạch thi công');
      return;
    }

    // Kiểm tra xem Contractor có phải là contractor trong pipeline không
    if (_pipeline!.contractorId != _currentUserId) {
      _showSnackBar('Lỗi: Bạn không phải là Contractor của dự án này');
      return;
    }

    final planNameController = TextEditingController();
    final planDescriptionController = TextEditingController();
    File? selectedPlanFile;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('Gửi kế hoạch thi công')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn file kế hoạch thi công (PDF)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedPlanFile == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FileStorageService.pickFile();
                      if (result != null && result.files.single.path != null) {
                        final filePath = result.files.single.path!;
                        final file = File(filePath);
                        final fileName = result.files.single.name;
                        
                        // Kiểm tra file extension
                        if (!fileName.toLowerCase().endsWith('.pdf')) {
                          _showSnackBar('Vui lòng chọn file PDF');
                          return;
                        }
                        
                        setDialogState(() {
                          selectedPlanFile = file;
                          planNameController.text = fileName;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Chọn file PDF'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPlanFile!.path.split('/').last,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF File',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              selectedPlanFile = null;
                              planNameController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: planNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên kế hoạch (tùy chọn)',
                    hintText: 'VD: Kế hoạch thi công nhà phố...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: planDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả kế hoạch (tùy chọn)',
                    hintText: 'Mô tả về kế hoạch thi công...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Đang upload file...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
              onPressed: (selectedPlanFile == null || isUploading)
                  ? null
                  : () async {
                      setDialogState(() {
                        isUploading = true;
                      });

                      try {
                        // Upload file PDF lên Firebase Storage
                        final fileUrl = await FileStorageService.uploadFile(
                          file: selectedPlanFile!,
                          chatId: widget.chatId,
                          userId: _currentUserId!,
                        );

                        if (fileUrl == null) {
                          if (mounted) {
                            _showSnackBar('Lỗi khi upload file');
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                          return;
                        }

                        // Gửi message với file PDF
                        final fileName = planNameController.text.isNotEmpty
                            ? planNameController.text
                            : selectedPlanFile!.path.split('/').last;
                        final fileSize = await selectedPlanFile!.length();

                        final messageContent = planDescriptionController.text.isNotEmpty
                            ? '📋 Đã gửi kế hoạch thi công: $fileName\n\n${planDescriptionController.text}'
                            : '📋 Đã gửi kế hoạch thi công: $fileName';

                        final messageId = await ChatService.sendMessage(
                          chatId: widget.chatId,
                          content: messageContent,
                          type: MessageType.file,
                          fileUrl: fileUrl,
                          fileName: fileName,
                          fileSize: fileSize,
                        );

                        if (messageId != null) {
                          // Cập nhật pipeline với constructionPlanUrl (nếu có pipeline)
                          if (_pipeline != null) {
                            try {
                              // Cập nhật pipeline với constructionPlanUrl
                              await PipelineService.updateConstructionPlanUrl(
                                pipelineId: _pipeline!.id,
                                constructionPlanUrl: fileUrl,
                              );
                              
                              // Reload pipeline để cập nhật UI
                              await _loadPipeline(_pipeline!.id);
                              
                              print('✅ Construction plan URL updated in pipeline: $fileUrl');
                            } catch (e) {
                              print('⚠️ Error updating pipeline with construction plan URL: $e');
                              // Tiếp tục dù pipeline update lỗi
                            }
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            await _loadMessages();
                            _showSnackBar('Đã gửi kế hoạch thi công thành công');
                          }
                        } else {
                          if (mounted) {
                            _showSnackBar('Lỗi khi gửi tin nhắn');
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                        }
                      } catch (e) {
                        print('❌ Error sending construction plan: $e');
                        if (mounted) {
                          _showSnackBar('Lỗi: $e');
                          setDialogState(() {
                            isUploading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi kế hoạch'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog để Store gửi báo giá vật liệu (PDF)
  Future<void> _showSendMaterialQuoteDialog() async {
    if (_currentUserId == null || _receiverId == null) {
      _showSnackBar('Lỗi: Không tìm thấy thông tin người dùng');
      return;
    }

    if (_pipeline == null) {
      _showSnackBar('Lỗi: Chưa có pipeline. Vui lòng bắt đầu hợp tác trước.');
      return;
    }

    // Kiểm tra xem currentUser có phải là Store không
    if (_currentUserAccountType != UserAccountType.store) {
      _showSnackBar('Lỗi: Chỉ Store mới có thể gửi báo giá vật liệu');
      return;
    }

    // Kiểm tra xem Store có phải là store trong pipeline không
    if (_pipeline!.storeId != _currentUserId) {
      _showSnackBar('Lỗi: Bạn không phải là Store của dự án này');
      return;
    }

    final quoteNameController = TextEditingController();
    final quoteDescriptionController = TextEditingController();
    File? selectedQuoteFile;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('Gửi báo giá vật liệu')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn file báo giá vật liệu (PDF)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedQuoteFile == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FileStorageService.pickFile();
                      if (result != null && result.files.single.path != null) {
                        final filePath = result.files.single.path!;
                        final file = File(filePath);
                        final fileName = result.files.single.name;
                        
                        // Kiểm tra file extension
                        if (!fileName.toLowerCase().endsWith('.pdf')) {
                          _showSnackBar('Vui lòng chọn file PDF');
                          return;
                        }
                        
                        setDialogState(() {
                          selectedQuoteFile = file;
                          quoteNameController.text = fileName;
                        });
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Chọn file PDF'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedQuoteFile!.path.split('/').last,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF File',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              selectedQuoteFile = null;
                              quoteNameController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: quoteNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên báo giá (tùy chọn)',
                    hintText: 'VD: Báo giá vật liệu xây dựng...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quoteDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả báo giá (tùy chọn)',
                    hintText: 'Mô tả về báo giá vật liệu...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Đang upload file...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
              onPressed: (selectedQuoteFile == null || isUploading)
                  ? null
                  : () async {
                      setDialogState(() {
                        isUploading = true;
                      });

                      try {
                        // Upload file PDF lên Firebase Storage
                        final fileUrl = await FileStorageService.uploadFile(
                          file: selectedQuoteFile!,
                          chatId: widget.chatId,
                          userId: _currentUserId!,
                        );

                        if (fileUrl == null) {
                          if (mounted) {
                            _showSnackBar('Lỗi khi upload file');
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                          return;
                        }

                        // Gửi message với file PDF
                        final fileName = quoteNameController.text.isNotEmpty
                            ? quoteNameController.text
                            : selectedQuoteFile!.path.split('/').last;
                        final fileSize = await selectedQuoteFile!.length();

                        final messageContent = quoteDescriptionController.text.isNotEmpty
                            ? '💰 Đã gửi báo giá vật liệu: $fileName\n\n${quoteDescriptionController.text}'
                            : '💰 Đã gửi báo giá vật liệu: $fileName';

                        final messageId = await ChatService.sendMessage(
                          chatId: widget.chatId,
                          content: messageContent,
                          type: MessageType.file,
                          fileUrl: fileUrl,
                          fileName: fileName,
                          fileSize: fileSize,
                        );

                        if (messageId != null) {
                          // Cập nhật pipeline với materialQuoteUrl (nếu có pipeline)
                          if (_pipeline != null) {
                            try {
                              // Cập nhật pipeline với materialQuoteUrl
                              await PipelineService.updateMaterialQuoteUrl(
                                pipelineId: _pipeline!.id,
                                materialQuoteUrl: fileUrl,
                              );
                              
                              // Reload pipeline để cập nhật UI
                              await _loadPipeline(_pipeline!.id);
                              
                              print('✅ Material quote URL updated in pipeline: $fileUrl');
                            } catch (e) {
                              print('⚠️ Error updating pipeline with material quote URL: $e');
                              // Tiếp tục dù pipeline update lỗi
                            }
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            await _loadMessages();
                            _showSnackBar('Đã gửi báo giá vật liệu thành công');
                          }
                        } else {
                          if (mounted) {
                            _showSnackBar('Lỗi khi gửi tin nhắn');
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                        }
                      } catch (e) {
                        print('❌ Error sending material quote: $e');
                        if (mounted) {
                          _showSnackBar('Lỗi: $e');
                          setDialogState(() {
                            isUploading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi báo giá'),
            ),
          ],
        ),
      ),
    );
  }
}