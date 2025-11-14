import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../notifications/notification_service.dart';
import '../user/user_session.dart';
import '../project/pipeline_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';

  /// Lấy danh sách chat
  static Future<List<Chat>> getChats() async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return [];

      final userId = currentUser['userId']?.toString();
      if (userId == null || userId.isEmpty) return [];

      print('🔍 Getting chats for userId: $userId');
      
      final snapshot = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .get();

      print('📊 Found ${snapshot.docs.length} chats');

      final chats = <Chat>[];
      final seenChatIds = <String>{}; // Set để tránh duplicate
      
      for (var doc in snapshot.docs) {
        final chatData = doc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        // Đảm bảo participants chứa userId
        if (!participants.contains(userId)) {
          print('⚠️ Chat ${doc.id} does not contain userId: $userId');
          continue;
        }
        
        // Tìm otherUserId (bỏ qua userId hiện tại)
        final otherUserId = participants.firstWhere(
          (id) => id != userId && id.isNotEmpty, 
          orElse: () => '',
        );
        
        if (otherUserId.isEmpty) {
          print('⚠️ Chat ${doc.id} has no valid otherUserId');
          continue;
        }
        
        // Tạo normalized chat ID để tránh duplicate
        final normalizedParticipants = [userId, otherUserId]..sort();
        final normalizedChatId = normalizedParticipants.join('_');
        
        // Kiểm tra duplicate
        if (seenChatIds.contains(normalizedChatId)) {
          print('⚠️ Duplicate chat detected: $normalizedChatId (original ID: ${doc.id})');
          // Ưu tiên chat có lastMessageTime mới hơn (đã sắp xếp sau)
          continue;
        }
        seenChatIds.add(normalizedChatId);
        
        print('🔍 Chat ID: ${doc.id}, otherUserId: $otherUserId, normalized: $normalizedChatId');
        
        // Lấy thông tin người dùng khác
        try {
          final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            // Parse business context
            final chatTypeStr = chatData['chatType']?.toString() ?? 'normal';
            final chatType = ChatType.values.firstWhere(
              (type) => type.toString().split('.').last == chatTypeStr,
              orElse: () => ChatType.normal,
            );
            
            final receiverTypeStr = chatData['receiverType']?.toString();
            UserAccountType? receiverType;
            if (receiverTypeStr != null) {
              receiverType = UserAccountType.values.firstWhere(
                (type) => type.toString().split('.').last == receiverTypeStr.split('.').last,
                orElse: () => UserAccountType.general,
              );
            }

            // Tìm pipeline liên quan đến chat này
            String? pipelineId;
            String? collaborationStatus;
            try {
              final pipeline = await PipelineService.getPipelineFromChat(doc.id);
              if (pipeline != null) {
                pipelineId = pipeline.id;
                // Xác định collaboration status dựa trên receiverType
                if (receiverType == UserAccountType.designer) {
                  collaborationStatus = pipeline.designStatus.toString().split('.').last;
                } else if (receiverType == UserAccountType.contractor) {
                  collaborationStatus = pipeline.constructionStatus.toString().split('.').last;
                } else if (receiverType == UserAccountType.store) {
                  collaborationStatus = pipeline.materialsStatus.toString().split('.').last;
                }
              }
            } catch (e) {
              // Ignore pipeline errors
              print('⚠️ Error loading pipeline for chat ${doc.id}: $e');
            }

            // QUAN TRỌNG: Sử dụng normalizedChatId làm chat.id để đồng bộ với messages và notifications
            // Lưu document ID để có thể query messages nếu khác với normalized ID
            final documentId = doc.id != normalizedChatId ? doc.id : null;
            if (documentId != null) {
              print('⚠️ Chat document ID mismatch: doc.id=$documentId, normalizedChatId=$normalizedChatId');
              print('⚠️ Sử dụng normalized ID làm chat.id, nhưng lưu document ID để query messages');
            }
            
            final chat = Chat(
              id: normalizedChatId, // Sử dụng normalized ID thay vì doc.id để đồng bộ
              name: userData['name'] ?? 'Unknown',
              avatarUrl: userData['pic'],
              lastMessage: chatData['lastMessage'] ?? '',
              lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
                chatData['lastMessageTime'] ?? 0,
              ),
              unreadCount: chatData['unreadCounts']?[userId] ?? 0,
              isOnline: chatData['isOnline'] ?? false,
              lastMessageType: MessageType.values.firstWhere(
                (type) => type.toString().split('.').last == chatData['lastMessageType'],
                orElse: () => MessageType.text,
              ),
              lastMessageSender: chatData['lastMessageSender'],
              chatType: chatType,
              receiverType: receiverType,
              searchContext: chatData['searchContext'],
              isAutoMessage: chatData['isAutoMessage'] ?? false,
              pipelineId: pipelineId,
              collaborationStatus: collaborationStatus,
              documentId: documentId, // Lưu document ID để query messages nếu khác
            );
            
            print('✅ Added chat: ${chat.name} (id: ${chat.id}, documentId: ${chat.documentId})');
            chats.add(chat);
          } else {
            print('⚠️ User $otherUserId not found');
          }
        } catch (e) {
          print('❌ Error loading user $otherUserId: $e');
        }
      }

      // Sort by last message time (mới nhất trước)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      print('✅ Returning ${chats.length} unique chats (after deduplication)');
      return chats;
    } catch (e) {
      print('❌ Error getting chats: $e');
      return [];
    }
  }

  /// Lắng nghe chats realtime
  /// SỬA BUG: Filter đúng theo userId, tránh duplicate chats
  static Stream<List<Chat>> listenToChats() {
    // Lấy userId trước, sau đó tạo stream với filter đúng
    return Stream.fromFuture(_getCurrentUserId()).asyncExpand((userId) {
      if (userId == null || userId.isEmpty) {
        return Stream.value(<Chat>[]);
      }

      print('🔍 listenToChats: Listening for userId: $userId');
      
      // SỬA BUG: Filter đúng theo userId thay vì arrayContains: ''
      return _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .snapshots()
          .asyncMap((snapshot) async {
        final chats = <Chat>[];
        final seenChatIds = <String>{}; // Set để tránh duplicate
        
        for (var doc in snapshot.docs) {
          final chatData = doc.data();
          final participants = List<String>.from(chatData['participants'] ?? []);
          
          // Đảm bảo participants chứa userId (double check)
          if (!participants.contains(userId)) {
            print('⚠️ Chat ${doc.id} does not contain userId: $userId');
            continue;
          }
          
          // Tìm otherUserId (bỏ qua userId hiện tại)
          final otherUserId = participants.firstWhere(
            (id) => id != userId && id.isNotEmpty, 
            orElse: () => '',
          );
          
          if (otherUserId.isEmpty) {
            print('⚠️ Chat ${doc.id} has no valid otherUserId');
            continue;
          }
          
          // Tạo normalized chat ID để tránh duplicate
          final normalizedParticipants = [userId, otherUserId]..sort();
          final normalizedChatId = normalizedParticipants.join('_');
          
          // Kiểm tra duplicate - nếu đã thấy chat này với ID khác, skip
          if (seenChatIds.contains(normalizedChatId)) {
            print('⚠️ Duplicate chat detected: $normalizedChatId (original ID: ${doc.id})');
            continue;
          }
          seenChatIds.add(normalizedChatId);
          
          // Lấy thông tin người dùng khác
          try {
            final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              // Parse business context
              final chatTypeStr = chatData['chatType']?.toString() ?? 'normal';
              final chatType = ChatType.values.firstWhere(
                (type) => type.toString().split('.').last == chatTypeStr,
                orElse: () => ChatType.normal,
              );
              
              final receiverTypeStr = chatData['receiverType']?.toString();
              UserAccountType? receiverType;
              if (receiverTypeStr != null) {
                receiverType = UserAccountType.values.firstWhere(
                  (type) => type.toString().split('.').last == receiverTypeStr.split('.').last,
                  orElse: () => UserAccountType.general,
                );
              }

              // QUAN TRỌNG: Sử dụng normalizedChatId làm chat.id để đồng bộ với messages và notifications
              // Lưu document ID để có thể query messages nếu khác với normalized ID
              final documentId = doc.id != normalizedChatId ? doc.id : null;
              if (documentId != null) {
                print('⚠️ Chat document ID mismatch: doc.id=$documentId, normalizedChatId=$normalizedChatId');
                print('⚠️ Sử dụng normalized ID làm chat.id, nhưng lưu document ID để query messages');
              }
              
              final chat = Chat(
                id: normalizedChatId, // Sử dụng normalized ID thay vì doc.id để đồng bộ
                name: userData['name'] ?? 'Unknown',
                avatarUrl: userData['pic'],
                lastMessage: chatData['lastMessage'] ?? '',
                lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
                  chatData['lastMessageTime'] ?? 0,
                ),
                unreadCount: chatData['unreadCounts']?[userId] ?? 0,
                isOnline: chatData['isOnline'] ?? false,
                lastMessageType: MessageType.values.firstWhere(
                  (type) => type.toString().split('.').last == chatData['lastMessageType'],
                  orElse: () => MessageType.text,
                ),
                lastMessageSender: chatData['lastMessageSender'],
                chatType: chatType,
                receiverType: receiverType,
                searchContext: chatData['searchContext'],
                isAutoMessage: chatData['isAutoMessage'] ?? false,
                documentId: documentId, // Lưu document ID để query messages nếu khác
              );
              
              chats.add(chat);
            } else {
              print('⚠️ User $otherUserId not found in database');
            }
          } catch (e) {
            print('❌ Error loading user $otherUserId: $e');
          }
        }

        // Sort by last message time (mới nhất trước)
        chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        print('✅ listenToChats: Found ${chats.length} unique chats for userId: $userId');
        return chats;
      });
    });
  }

  /// Helper method để lấy current userId
  static Future<String?> _getCurrentUserId() async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;
      return currentUser['userId']?.toString();
    } catch (e) {
      print('❌ Error getting current userId: $e');
      return null;
    }
  }

  /// Tạo chat mới
  static Future<String?> createChat(String otherUserId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return null;

      // Tạo chatId tương thích với AutoMessageService
      final participantsList = [userId, otherUserId];
      participantsList.sort(); // Sắp xếp
      final chatId = participantsList.join('_');
      
      print('🔍 Creating chat with ID: $chatId');
      print('🔍 Participants sorted: $participantsList');

      // Kiểm tra xem đã có chat chưa
      final existingChatDoc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .get();

      if (existingChatDoc.exists) {
        print('✅ Chat already exists: $chatId');
        return chatId; // Chat đã tồn tại
      }

      // Tạo chat mới với chatId cố định
      final chatData = {
        'participants': participantsList, // Sử dụng participants đã sort
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageType': MessageType.text.toString().split('.').last,
        'lastMessageSender': null,
        'unreadCounts': {
          userId: 0,
          otherUserId: 0,
        },
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _firestore.collection(_chatsCollection).doc(chatId).set(chatData);
      print('✅ Chat created successfully: $chatId');
      return chatId;
    } catch (e) {
      print('❌ Error creating chat: $e');
      return null;
    }
  }

  /// Gửi tin nhắn
  static Future<String?> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      final userName = currentUser['name']?.toString() ?? 'Unknown';
      if (userId == null) return null;

      final now = DateTime.now();
      final messageData = {
        'chatId': chatId,
        'senderId': userId,
        'senderName': userName,
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': now.millisecondsSinceEpoch,
        'isRead': false,
        'status': MessageStatus.sent.toString().split('.').last,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
      };

      // Thêm tin nhắn
      final messageRef = await _firestore.collection(_messagesCollection).add(messageData);

      // Cập nhật chat
      String lastMessagePreview = content;
      if (fileUrl != null && fileName != null) {
        if (type == MessageType.image) {
          lastMessagePreview = '📷 Đã gửi hình ảnh';
        } else if (type == MessageType.file) {
          lastMessagePreview = '📎 $fileName';
        }
      }
      
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessage': lastMessagePreview,
        'lastMessageTime': now.millisecondsSinceEpoch,
        'lastMessageType': type.toString().split('.').last,
        'lastMessageSender': userName,
      });

      // Tăng unread count cho người nhận
      final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);
        final unreadCounts = Map<String, int>.from(chatData['unreadCounts'] ?? {});

        for (String participantId in participants) {
          if (participantId != userId) {
            unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
          }
        }

        await _firestore.collection(_chatsCollection).doc(chatId).update({
          'unreadCounts': unreadCounts,
        });

        // Tạo thông báo cho người nhận
        for (String participantId in participants) {
          if (participantId != userId) {
            await _createMessageNotification(
              receiverId: participantId,
              senderId: userId,
              senderName: userName,
              content: content,
              chatId: chatId,
            );
          }
        }
      }

      print('Message sent successfully: ${messageRef.id}');
      return messageRef.id;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Lấy tin nhắn của một chat
  /// QUAN TRỌNG: chatId phải là normalized ID (format: userId1_userId2, sorted)
  /// Nếu không tìm thấy messages với chatId, sẽ thử query với document ID (nếu có)
  /// Đảm bảo messages được lưu với normalized chatId để đồng bộ
  static Future<List<Message>> getMessages(String chatId, {String? documentId}) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      final myId = currentUser?['userId']?.toString();

      print('🔍 Getting messages for chatId: $chatId${documentId != null ? " (documentId: $documentId)" : ""}');
      
      // Query messages với normalized chatId (chuẩn)
      var snapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      print('📨 Found ${snapshot.docs.length} messages for chatId: $chatId');

      // Nếu không tìm thấy messages với normalized ID, thử với document ID (fallback)
      // (có thể messages được lưu với document ID thay vì normalized ID - backward compatibility)
      if (snapshot.docs.isEmpty && documentId != null && documentId != chatId) {
        print('⚠️ No messages found with normalized chatId: $chatId');
        print('⚠️ Trying to query with document ID: $documentId');
        
        snapshot = await _firestore
            .collection(_messagesCollection)
            .where('chatId', isEqualTo: documentId)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          print('⚠️ Found ${snapshot.docs.length} messages with document ID: $documentId');
          print('⚠️ WARNING: Messages được lưu với document ID thay vì normalized ID - cần migrate!');
        }
      }
      
      // Nếu vẫn không tìm thấy, có thể messages được lưu với ID khác
      if (snapshot.docs.isEmpty) {
        print('⚠️ No messages found for chatId: $chatId');
        print('⚠️ Có thể messages được lưu với chatId khác hoặc chưa có messages');
      }

      final items = snapshot.docs
          .map((doc) => _mapMessage(doc.data(), doc.id, myId))
          .toList();
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return items;
    } catch (e) {
      print('❌ Error getting messages for chatId $chatId: $e');
      // Nếu có lỗi với orderBy (có thể do thiếu index), thử query không có orderBy
      try {
        print('⚠️ Retrying without orderBy...');
        final currentUser = await UserSession.getCurrentUser();
        final myId = currentUser?['userId']?.toString();
        
        var snapshot = await _firestore
            .collection(_messagesCollection)
            .where('chatId', isEqualTo: chatId)
            .limit(50)
            .get();
        
        if (snapshot.docs.isEmpty && documentId != null && documentId != chatId) {
          snapshot = await _firestore
              .collection(_messagesCollection)
              .where('chatId', isEqualTo: documentId)
              .limit(50)
              .get();
        }
        
        final items = snapshot.docs
            .map((doc) => _mapMessage(doc.data(), doc.id, myId))
            .toList();
        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return items;
      } catch (e2) {
        print('❌ Error retrying getMessages: $e2');
        return [];
      }
    }
  }

  /// Lắng nghe tin nhắn realtime
  static Stream<List<Message>> listenToMessages(String chatId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
          final currentUser = await UserSession.getCurrentUser();
          final myId = currentUser?['userId']?.toString();
          final list = snapshot.docs
              .map((doc) => _mapMessage(doc.data(), doc.id, myId))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  /// Lấy thông tin tiêu đề chat (tên, avatar người còn lại)
  static Future<Map<String, String?>> getChatHeader(String chatId) async {
    final currentUser = await UserSession.getCurrentUser();
    final userId = currentUser?['userId']?.toString();
    if (userId == null) return {'name': 'Chat', 'avatar': null};

    final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
    if (!chatDoc.exists) return {'name': 'Chat', 'avatar': null};

    final data = chatDoc.data()!;
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
    if (otherUserId.isEmpty) return {'name': 'Chat', 'avatar': null};

    final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
    if (!userDoc.exists) return {'name': 'Chat', 'avatar': null};

    final userData = userDoc.data() as Map<String, dynamic>;
    return {
      'name': userData['name']?.toString() ?? 'Chat',
      'avatar': userData['pic']?.toString(),
    };
  }

  /// Lấy thông tin Chat đầy đủ từ chatId
  /// QUAN TRỌNG: chatId phải là normalized ID (format: userId1_userId2, sorted)
  /// Nếu không tìm thấy với chatId, sẽ thử normalize lại và tìm
  static Future<Chat?> getChatById(String chatId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return null;

      // Thử query với chatId trực tiếp (normalized ID)
      var chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      
      // Nếu không tìm thấy, thử normalize lại chatId từ participants
      // (có thể chatId được truyền vào không đúng format)
      if (!chatDoc.exists) {
        print('⚠️ Chat not found with ID: $chatId, trying to normalize...');
        
        // Nếu chatId có format userId1_userId2, đã là normalized, không cần normalize lại
        // Nếu không, có thể cần query theo participants
        // Tạm thời return null, vì không thể normalize mà không biết participants
        return null;
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      
      if (!participants.contains(userId)) return null;

      final otherUserId = participants.firstWhere(
        (id) => id != userId && id.isNotEmpty,
        orElse: () => '',
      );
      
      if (otherUserId.isEmpty) return null;

      final userDoc = await _firestore.collection('Users').doc(otherUserId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;

      // Parse business context từ Firestore
      final chatTypeStr = chatData['chatType']?.toString() ?? 'normal';
      var chatType = ChatType.values.firstWhere(
        (type) => type.toString().split('.').last == chatTypeStr,
        orElse: () => ChatType.normal,
      );
      
      var receiverTypeStr = chatData['receiverType']?.toString();
      UserAccountType? receiverType;
      if (receiverTypeStr != null) {
        receiverType = UserAccountType.values.firstWhere(
          (type) => type.toString().split('.').last == receiverTypeStr.split('.').last,
          orElse: () => UserAccountType.general,
        );
      }

      // QUAN TRỌNG: Nếu chat document không có business context, kiểm tra từ user profile và messages
      // Nếu người nhận là designer, contractor, hoặc store, đánh dấu là business chat
      if (chatType == ChatType.normal || receiverType == null) {
        // Lấy accountType từ user profile
        final accountTypeStr = userData['accountType']?.toString();
        if (accountTypeStr != null && accountTypeStr.isNotEmpty) {
          // Parse accountType - hỗ trợ cả "UserAccountType.designer" và "designer"
          final normalizedAccountType = accountTypeStr.replaceAll('UserAccountType.', '').toLowerCase().trim();
          UserAccountType? accountType;
          
          switch (normalizedAccountType) {
            case 'designer':
              accountType = UserAccountType.designer;
              break;
            case 'contractor':
              accountType = UserAccountType.contractor;
              break;
            case 'store':
              accountType = UserAccountType.store;
              break;
            case 'general':
              accountType = UserAccountType.general;
              break;
            default:
              // Thử parse như enum string
              try {
                accountType = UserAccountType.values.firstWhere(
                  (type) => type.toString().split('.').last == normalizedAccountType,
                  orElse: () => UserAccountType.general,
                );
              } catch (e) {
                accountType = UserAccountType.general;
              }
          }
          
          // Nếu accountType là designer, contractor, hoặc store, đánh dấu là business chat
          if (accountType == UserAccountType.designer || 
              accountType == UserAccountType.contractor || 
              accountType == UserAccountType.store) {
            chatType = ChatType.business;
            receiverType = accountType;
            print('📍 Chat $chatId: Đánh dấu là business chat với receiverType: $receiverType (từ user profile: $accountTypeStr)');
          }
        }
      }

      // Nếu vẫn chưa có receiverType, kiểm tra từ messages (nếu có business messages)
      if (receiverType == null) {
        try {
          final messagesSnapshot = await _firestore
              .collection(_messagesCollection)
              .where('chatId', isEqualTo: chatId)
              .limit(10) // Chỉ kiểm tra 10 messages gần nhất
              .get();
          
          // Kiểm tra xem có business messages không
          bool hasBusinessMessages = false;
          for (var doc in messagesSnapshot.docs) {
            final msgData = doc.data();
            final msgTypeStr = msgData['type']?.toString() ?? 'text';
            final msgType = MessageType.values.firstWhere(
              (type) => type.toString().split('.').last == msgTypeStr,
              orElse: () => MessageType.text,
            );
            
            // Nếu có business message (appointment, quote, portfolio, etc.), đánh dấu là business chat
            if (msgType == MessageType.appointmentRequest ||
                msgType == MessageType.quoteRequest ||
                msgType == MessageType.portfolioShare ||
                msgType == MessageType.materialCatalog ||
                msgType == MessageType.projectTimeline) {
              hasBusinessMessages = true;
              break;
            }
          }
          
          // Nếu có business messages, đánh dấu là business chat và lấy receiverType từ user profile
          if (hasBusinessMessages) {
            final accountTypeStr = userData['accountType']?.toString();
            if (accountTypeStr != null && accountTypeStr.isNotEmpty) {
              // Parse accountType - hỗ trợ cả "UserAccountType.designer" và "designer"
              final normalizedAccountType = accountTypeStr.replaceAll('UserAccountType.', '').toLowerCase().trim();
              UserAccountType? accountType;
              
              switch (normalizedAccountType) {
                case 'designer':
                  accountType = UserAccountType.designer;
                  break;
                case 'contractor':
                  accountType = UserAccountType.contractor;
                  break;
                case 'store':
                  accountType = UserAccountType.store;
                  break;
                case 'general':
                  accountType = UserAccountType.general;
                  break;
                default:
                  // Thử parse như enum string
                  try {
                    accountType = UserAccountType.values.firstWhere(
                      (type) => type.toString().split('.').last == normalizedAccountType,
                      orElse: () => UserAccountType.general,
                    );
                  } catch (e) {
                    accountType = UserAccountType.general;
                  }
              }
              
              if (accountType == UserAccountType.designer || 
                  accountType == UserAccountType.contractor || 
                  accountType == UserAccountType.store) {
                chatType = ChatType.business;
                receiverType = accountType;
                print('📍 Chat $chatId: Đánh dấu là business chat với receiverType: $receiverType (từ business messages, user profile: $accountTypeStr)');
              }
            }
          }
        } catch (e) {
          print('⚠️ Error checking business messages for chat $chatId: $e');
        }
      }

      // Tìm pipeline liên quan đến chat này
      // QUAN TRỌNG: Đọc pipelineId trực tiếp từ chat document trước (nhanh hơn)
      String? pipelineId;
      String? collaborationStatus;
      try {
        // Ưu tiên: Đọc pipelineId trực tiếp từ chat document
        pipelineId = chatData['pipelineId']?.toString();
        
        if (pipelineId != null && pipelineId.isNotEmpty) {
          print('✅ Found pipelineId in chat document: $pipelineId');
          // Load pipeline để lấy collaboration status
          final pipeline = await PipelineService.getPipeline(pipelineId);
          if (pipeline != null) {
            // Xác định collaboration status dựa trên receiverType
            if (receiverType == UserAccountType.designer) {
              collaborationStatus = pipeline.designStatus.toString().split('.').last;
            } else if (receiverType == UserAccountType.contractor) {
              collaborationStatus = pipeline.constructionStatus.toString().split('.').last;
            } else if (receiverType == UserAccountType.store) {
              collaborationStatus = pipeline.materialsStatus.toString().split('.').last;
            }
            print('✅ Pipeline loaded: ${pipeline.projectName}, status: $collaborationStatus');
          } else {
            print('⚠️ Pipeline not found: $pipelineId');
          }
        } else {
          // Fallback: Tìm pipeline theo participants (cho backward compatibility)
          print('⚠️ No pipelineId in chat document, trying fallback...');
          final pipeline = await PipelineService.getPipelineFromChat(chatId);
          if (pipeline != null) {
            pipelineId = pipeline.id;
            // Xác định collaboration status dựa trên receiverType
            if (receiverType == UserAccountType.designer) {
              collaborationStatus = pipeline.designStatus.toString().split('.').last;
            } else if (receiverType == UserAccountType.contractor) {
              collaborationStatus = pipeline.constructionStatus.toString().split('.').last;
            } else if (receiverType == UserAccountType.store) {
              collaborationStatus = pipeline.materialsStatus.toString().split('.').last;
            }
            print('✅ Pipeline found via fallback: ${pipeline.projectName}');
          }
        }
      } catch (e) {
        // Ignore pipeline errors
        print('⚠️ Error loading pipeline for chat $chatId: $e');
      }

      // QUAN TRỌNG: Đảm bảo chat.id sử dụng normalized ID (chatId từ parameter)
      // Nếu document ID khác với normalized ID, vẫn sử dụng normalized ID để đồng bộ
      // với messages và notifications
      final normalizedChatId = chatId; // chatId đã là normalized (từ parameter)
      
      // QUAN TRỌNG: Lưu document ID để truyền vào getMessages() nếu khác với normalized ID
      // Nếu document ID khác với normalized ID, có thể messages được lưu với document ID
      final documentId = chatDoc.id != normalizedChatId ? chatDoc.id : null;
      if (documentId != null) {
        print('⚠️ getChatById: Document ID ($documentId) khác với normalized ID ($normalizedChatId)');
        print('⚠️ Sử dụng normalized ID làm chat.id, nhưng lưu document ID để query messages');
      }
      
      return Chat(
        id: normalizedChatId, // Sử dụng normalized ID để đồng bộ
        name: userData['name'] ?? 'Unknown',
        avatarUrl: userData['pic'],
        lastMessage: chatData['lastMessage'] ?? '',
        lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
          chatData['lastMessageTime'] ?? 0,
        ),
        unreadCount: chatData['unreadCounts']?[userId] ?? 0,
        isOnline: chatData['isOnline'] ?? false,
        lastMessageType: MessageType.values.firstWhere(
          (type) => type.toString().split('.').last == chatData['lastMessageType'],
          orElse: () => MessageType.text,
        ),
        lastMessageSender: chatData['lastMessageSender'],
        chatType: chatType,
        receiverType: receiverType,
        searchContext: chatData['searchContext'],
        isAutoMessage: chatData['isAutoMessage'] ?? false,
        pipelineId: pipelineId,
        collaborationStatus: collaborationStatus,
        documentId: documentId, // Lưu document ID để query messages nếu khác
      );
    } catch (e) {
      print('❌ Error getting chat by ID: $e');
      return null;
    }
  }

  static Message _mapMessage(Map<String, dynamic> data, String id, String? myId) {
    final typeStr = data['type']?.toString() ?? 'text';
    final statusStr = data['status']?.toString() ?? 'sent';
    final type = MessageType.values.firstWhere(
      (t) => t.toString().split('.').last == typeStr,
      orElse: () => MessageType.text,
    );
    final status = MessageStatus.values.firstWhere(
      (s) => s.toString().split('.').last == statusStr,
      orElse: () => MessageStatus.sent,
    );

    final fromMe = myId != null && myId == (data['senderId']?.toString());

    return Message(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'] != null ? (data['fileSize'] as num).toInt() : null,
      isFromMe: fromMe,
      type: type,
      status: status,
      businessData: data['businessData'] != null 
          ? Map<String, dynamic>.from(data['businessData']) 
          : null,
      isAutoMessage: data['isAutoMessage'] ?? false,
    );
  }

  /// Cập nhật pipelineId cho chat
  static Future<void> updateChatPipelineId(String chatId, String pipelineId) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'pipelineId': pipelineId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Chat $chatId updated with pipelineId: $pipelineId');
    } catch (e) {
      print('❌ Error updating chat pipelineId: $e');
      rethrow;
    }
  }

  /// Đánh dấu tin nhắn đã đọc
  static Future<void> markAsRead(String chatId) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return;

      // Reset unread count
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'unreadCounts.$userId': 0,
      });

      // Đánh dấu tất cả tin nhắn trong chat là đã đọc (lọc ở client để tránh cần index)
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        if (data['senderId'] != userId) {
          batch.update(doc.reference, {
            'isRead': true,
            'status': MessageStatus.read.toString().split('.').last,
          });
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Tạo thông báo tin nhắn thông minh
  static Future<void> _createMessageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String content,
    required String chatId,
  }) async {
    try {
      // Kiểm tra xem đã có thông báo tin nhắn chưa đọc từ người này chưa
      final existingNotification = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: receiverId)
          .where('type', isEqualTo: 'message')
          .where('senderId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();

      if (existingNotification.docs.isNotEmpty) {
        // Cập nhật thông báo hiện tại
        final notificationDoc = existingNotification.docs.first;
        final notificationData = notificationDoc.data();
        final currentCount = notificationData['data']?['messageCount'] ?? 1;
        
        await notificationDoc.reference.update({
          'message': currentCount == 1 
              ? '$senderName: $content'
              : '$senderName đã gửi $currentCount tin nhắn mới',
          'data.messageCount': currentCount + 1,
          'data.lastMessage': content,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // Tạo thông báo mới
        await NotificationService.createNotification(
          receiverId: receiverId,
          title: 'Tin nhắn mới',
          message: '$senderName: $content',
          type: 'message',
          senderId: senderId,
          senderName: senderName,
          data: {
            'action': 'message',
            'chatId': chatId,
            'messageCount': 1,
            'lastMessage': content,
          },
        );
      }
    } catch (e) {
      print('Error creating message notification: $e');
    }
  }
}
