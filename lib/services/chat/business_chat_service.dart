import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_model.dart';
import '../../models/user_profile.dart';
import '../../models/construction_material.dart';
import '../user/user_session.dart';
import 'chat_service.dart';
import '../manage/material_service.dart';
import '../storage/image_service.dart';
import 'dart:io';

/// Service quản lý các tính năng nghiệp vụ trong chat
class BusinessChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Gửi yêu cầu báo giá
  static Future<String?> sendQuoteRequest({
    required String chatId,
    required String receiverId,
    required UserAccountType receiverType,
    required String projectDescription,
    double? estimatedBudget,
    String? projectType,
    DateTime? expectedStartDate,
    String? projectId, // Phase 1: Link với dự án đã chọn
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final businessData = {
        'receiverType': receiverType.toString(),
        'projectDescription': projectDescription,
        if (estimatedBudget != null) 'estimatedBudget': estimatedBudget,
        if (projectType != null) 'projectType': projectType,
        if (expectedStartDate != null) 'expectedStartDate': expectedStartDate.millisecondsSinceEpoch,
        if (projectId != null) 'projectId': projectId, // Phase 1: Lưu projectId
        'status': 'pending', // pending, responded, accepted, rejected
      };

      String content = '💰 Yêu cầu báo giá';
      if (projectType != null) {
        content += ' - $projectType';
      }
      if (estimatedBudget != null) {
        content += '\nNgân sách dự kiến: ${estimatedBudget.toStringAsFixed(0)} triệu VNĐ';
      }

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.quoteRequest,
      );

      if (messageId != null) {
        // Lưu business data vào message
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sending quote request: $e');
      return null;
    }
  }

  /// Gửi phản hồi báo giá
  static Future<String?> sendQuoteResponse({
    required String chatId,
    required String quoteRequestMessageId,
    required double price,
    String? notes,
    DateTime? estimatedCompletionDate,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final businessData = {
        'quoteRequestMessageId': quoteRequestMessageId,
        'price': price,
        if (notes != null) 'notes': notes,
        if (estimatedCompletionDate != null) 'estimatedCompletionDate': estimatedCompletionDate.millisecondsSinceEpoch,
        'status': 'responded',
      };

      String content = '💵 Báo giá: ${price.toStringAsFixed(0)} triệu VNĐ';
      if (notes != null && notes.isNotEmpty) {
        content += '\n$notes';
      }
      if (estimatedCompletionDate != null) {
        content += '\nDự kiến hoàn thành: ${_formatDate(estimatedCompletionDate)}';
      }

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.quoteResponse,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });

        // Cập nhật status của quote request
        await _firestore.collection('messages').doc(quoteRequestMessageId).update({
          'businessData.status': 'responded',
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sending quote response: $e');
      return null;
    }
  }

  /// Chia sẻ catalog vật liệu (cho cửa hàng VLXD)
  static Future<String?> shareMaterialCatalog({
    required String chatId,
    required List<String> materialIds,
    String? category,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      // Lấy thông tin vật liệu
      final materials = <ConstructionMaterial>[];
      for (var materialId in materialIds) {
        final material = await MaterialService.getById(materialId);
        if (material != null) {
          materials.add(material);
        }
      }

      if (materials.isEmpty) {
        print('⚠️ No materials found');
        return null;
      }

      final businessData = {
        'materialIds': materialIds,
        'materialCount': materials.length,
        if (category != null) 'category': category,
      };

      String content = '📦 Catalog vật liệu (${materials.length} sản phẩm)';
      if (category != null) {
        content += ' - $category';
      }

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.materialCatalog,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sharing material catalog: $e');
      return null;
    }
  }

  /// Chia sẻ portfolio (cho nhà thiết kế)
  static Future<String?> sharePortfolio({
    required String chatId,
    required List<String> imageUrls,
    String? projectTitle,
    String? projectDescription,
  }) async {
    try {
      final businessData = {
        'imageUrls': imageUrls,
        'imageCount': imageUrls.length,
        if (projectTitle != null) 'projectTitle': projectTitle,
        if (projectDescription != null) 'projectDescription': projectDescription,
      };

      String content = '🎨 Portfolio';
      if (projectTitle != null) {
        content += ' - $projectTitle';
      }
      content += '\n${imageUrls.length} hình ảnh';

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.portfolioShare,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sharing portfolio: $e');
      return null;
    }
  }

  /// Upload và chia sẻ portfolio từ files
  static Future<String?> sharePortfolioFromFiles({
    required String chatId,
    required List<File> imageFiles,
    String? projectTitle,
    String? projectDescription,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final userId = currentUser['userId']?.toString();
      if (userId == null) return null;

      // Upload ảnh lên Firebase Storage
      final imageUrls = await ImageService.uploadMultipleImages(
        imageFiles: imageFiles,
        userId: userId,
        type: 'portfolio',
      );

      if (imageUrls.isEmpty) {
        print('⚠️ No images uploaded');
        return null;
      }

      // Chia sẻ portfolio với URLs
      return await sharePortfolio(
        chatId: chatId,
        imageUrls: imageUrls,
        projectTitle: projectTitle,
        projectDescription: projectDescription,
      );
    } catch (e) {
      print('❌ Error sharing portfolio from files: $e');
      return null;
    }
  }

  /// Chia sẻ timeline dự án (cho chủ thầu)
  static Future<String?> shareProjectTimeline({
    required String chatId,
    required String projectName,
    required List<Map<String, dynamic>> milestones,
    DateTime? expectedStartDate,
    DateTime? expectedEndDate,
  }) async {
    try {
      final businessData = {
        'projectName': projectName,
        'milestones': milestones,
        if (expectedStartDate != null) 'expectedStartDate': expectedStartDate.millisecondsSinceEpoch,
        if (expectedEndDate != null) 'expectedEndDate': expectedEndDate.millisecondsSinceEpoch,
      };

      String content = '📅 Timeline dự án: $projectName';
      if (expectedStartDate != null && expectedEndDate != null) {
        content += '\nTừ ${_formatDate(expectedStartDate)} đến ${_formatDate(expectedEndDate)}';
      }
      content += '\n${milestones.length} mốc thời gian';

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.projectTimeline,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sharing project timeline: $e');
      return null;
    }
  }

  /// Phase 5 Enhancement: Gửi báo cáo sử dụng vật liệu (cho contractor)
  static Future<String?> sendMaterialUsageReport({
    required String chatId,
    required DateTime usageDate,
    required String materialName,
    required double quantity,
    String? unit,
    String? notes,
    String? projectId, // Link với project nếu có
  }) async {
    try {
      final businessData = {
        'usageDate': usageDate.millisecondsSinceEpoch,
        'materialName': materialName,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (notes != null) 'notes': notes,
        if (projectId != null) 'projectId': projectId,
      };

      String content = '📋 Báo cáo sử dụng vật liệu';
      content += '\nNgày: ${_formatDate(usageDate)}';
      content += '\nVật liệu: $materialName';
      content += '\nSố lượng: $quantity${unit != null ? ' $unit' : ''}';
      if (notes != null && notes.isNotEmpty) {
        content += '\nGhi chú: $notes';
      }

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.materialUsageReport,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sending material usage report: $e');
      return null;
    }
  }

  /// Gửi yêu cầu hẹn gặp
  static Future<String?> sendAppointmentRequest({
    required String chatId,
    required DateTime requestedDate,
    required String location,
    String? purpose,
    String? notes,
  }) async {
    try {
      final businessData = {
        'requestedDate': requestedDate.millisecondsSinceEpoch,
        'location': location,
        if (purpose != null) 'purpose': purpose,
        if (notes != null) 'notes': notes,
        'status': 'pending', // pending, accepted, rejected
      };

      String content = '📅 Yêu cầu hẹn gặp';
      content += '\nThời gian: ${_formatDateTime(requestedDate)}';
      content += '\nĐịa điểm: $location';
      if (purpose != null) {
        content += '\nMục đích: $purpose';
      }

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.appointmentRequest,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error sending appointment request: $e');
      return null;
    }
  }

  /// Xác nhận hẹn gặp
  static Future<String?> confirmAppointment({
    required String chatId,
    required String appointmentRequestMessageId,
    DateTime? confirmedDate,
    String? notes,
  }) async {
    try {
      final businessData = {
        'appointmentRequestMessageId': appointmentRequestMessageId,
        'status': 'accepted',
        if (confirmedDate != null) 'confirmedDate': confirmedDate.millisecondsSinceEpoch,
        if (notes != null) 'notes': notes,
      };

      String content = '✅ Xác nhận hẹn gặp';
      if (confirmedDate != null) {
        content += '\nThời gian: ${_formatDateTime(confirmedDate)}';
      }
      if (notes != null && notes.isNotEmpty) {
        content += '\n$notes';
      }

      final messageId = await ChatService.sendMessage(
        chatId: chatId,
        content: content,
        type: MessageType.appointmentConfirm,
      );

      if (messageId != null) {
        await _firestore.collection('messages').doc(messageId).update({
          'businessData': businessData,
        });

        // Cập nhật status của appointment request
        await _firestore.collection('messages').doc(appointmentRequestMessageId).update({
          'businessData.status': 'accepted',
        });
      }

      return messageId;
    } catch (e) {
      print('❌ Error confirming appointment: $e');
      return null;
    }
  }

  /// Lấy danh sách vật liệu của người dùng (để chia sẻ trong chat)
  static Future<List<ConstructionMaterial>> getUserMaterials({
    int limit = 20,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return [];

      final userId = currentUser['userId']?.toString();
      if (userId == null) return [];

      return await MaterialService.getByUserId(userId, limit: limit);
    } catch (e) {
      print('❌ Error getting user materials: $e');
      return [];
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

