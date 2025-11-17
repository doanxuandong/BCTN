import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TransactionType {
  import,  // Nhập kho
  export,  // Xuất kho
  adjust,  // Điều chỉnh
  transfer, // Chuyển kho
}

enum TransactionStatus {
  pending,   // Chờ xử lý
  completed, // Hoàn thành
  cancelled, // Đã hủy
}

class MaterialTransaction {
  final String id;
  final String materialId;
  final String materialName; // Tên vật liệu
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final String supplier; // Nhà cung cấp (cho nhập) hoặc người nhận (cho xuất)
  final String reason; // Lý do giao dịch
  final String note; // Ghi chú
  final String description; // Mô tả chi tiết
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime lastUpdated; // Thời gian cập nhật cuối
  final String createdBy; // Người tạo giao dịch
  final String? approvedBy; // Người duyệt (nếu cần)
  final DateTime? approvedAt; // Thời gian duyệt
  final List<String> attachments; // Đính kèm (hóa đơn, chứng từ)
  final Map<String, dynamic> additionalData; // Dữ liệu bổ sung
  
  // Thông tin liên kết với Project (Phase 1 Enhancement)
  final String? projectId; // ID của dự án (nếu transaction liên quan đến project)
  final String? projectName; // Tên dự án
  final String? fromUserId; // ID người/chủ thể chuyển (ví dụ: store khi xuất kho)
  final String? fromUserName; // Tên người/chủ thể chuyển
  final String? toUserId; // ID người/chủ thể nhận (ví dụ: owner/contractor khi store xuất kho)
  final String? toUserName; // Tên người/chủ thể nhận

  MaterialTransaction({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.userId,
    required this.type,
    required this.status,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.supplier,
    required this.reason,
    required this.note,
    required this.description,
    required this.transactionDate,
    required this.createdAt,
    required this.lastUpdated,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.attachments = const [],
    this.additionalData = const {},
    this.projectId,
    this.projectName,
    this.fromUserId,
    this.fromUserName,
    this.toUserId,
    this.toUserName,
  });

  MaterialTransaction copyWith({
    String? id,
    String? materialId,
    String? materialName,
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
    double? quantity,
    double? unitPrice,
    double? totalAmount,
    String? supplier,
    String? reason,
    String? note,
    String? description,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    List<String>? attachments,
    Map<String, dynamic>? additionalData,
    String? projectId,
    String? projectName,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? toUserName,
  }) {
    return MaterialTransaction(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      supplier: supplier ?? this.supplier,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      attachments: attachments ?? this.attachments,
      additionalData: additionalData ?? this.additionalData,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
    );
  }

  // Factory constructor từ Firestore
  factory MaterialTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaterialTransaction(
      id: doc.id,
      materialId: data['materialId'] ?? '',
      materialName: data['materialName'] ?? '',
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.import,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      quantity: (data['quantity'] ?? 0).toDouble(),
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      supplier: data['supplier'] ?? '',
      reason: data['reason'] ?? '',
      note: data['note'] ?? '',
      description: data['description'] ?? '',
      transactionDate: data['transactionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['transactionDate'])
          : DateTime.now(),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdated'])
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['approvedAt'])
          : null,
      attachments: List<String>.from(data['attachments'] ?? []),
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
      projectId: data['projectId'],
      projectName: data['projectName'],
      fromUserId: data['fromUserId'],
      fromUserName: data['fromUserName'],
      toUserId: data['toUserId'],
      toUserName: data['toUserName'],
    );
  }

  // Convert to Map cho Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'materialName': materialName,
      'userId': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'supplier': supplier,
      'reason': reason,
      'note': note,
      'description': description,
      'transactionDate': transactionDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'attachments': attachments,
      'additionalData': additionalData,
      if (projectId != null) 'projectId': projectId,
      if (projectName != null) 'projectName': projectName,
      if (fromUserId != null) 'fromUserId': fromUserId,
      if (fromUserName != null) 'fromUserName': fromUserName,
      if (toUserId != null) 'toUserId': toUserId,
      if (toUserName != null) 'toUserName': toUserName,
    };
  }

  // Helper methods
  bool get isImport => type == TransactionType.import;
  bool get isExport => type == TransactionType.export;
  bool get isAdjustment => type == TransactionType.adjust;
  bool get isTransfer => type == TransactionType.transfer;

  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isCancelled => status == TransactionStatus.cancelled;

  String get typeDisplayName {
    switch (type) {
      case TransactionType.import:
        return 'Nhập kho';
      case TransactionType.export:
        return 'Xuất kho';
      case TransactionType.adjust:
        return 'Điều chỉnh';
      case TransactionType.transfer:
        return 'Chuyển kho';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Chờ xử lý';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  Color get typeColor {
    switch (type) {
      case TransactionType.import:
        return Colors.blue;
      case TransactionType.export:
        return Colors.red;
      case TransactionType.adjust:
        return Colors.orange;
      case TransactionType.transfer:
        return Colors.purple;
    }
  }
}

