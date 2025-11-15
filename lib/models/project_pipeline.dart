import 'user_profile.dart';

/// Trạng thái hợp tác trong pipeline
enum CollaborationStatus {
  none,           // Chưa hợp tác
  requested,      // Đã yêu cầu hợp tác
  accepted,       // Đã chấp nhận hợp tác
  inProgress,     // Đang hợp tác
  completed,      // Đã hoàn thành
  cancelled,      // Đã hủy
}

/// Giai đoạn trong pipeline dự án
enum PipelineStage {
  design,         // Giai đoạn thiết kế (với nhà thiết kế)
  construction,    // Giai đoạn thi công (với chủ thầu)
  materials,       // Giai đoạn vật liệu (với cửa hàng VLXD)
}

/// Trạng thái dự án
enum ProjectStatus {
  planning,       // Đang lên kế hoạch
  designing,      // Đang thiết kế
  constructing,   // Đang thi công
  completed,      // Đã hoàn thành
  onHold,         // Tạm hoãn
  cancelled,      // Đã hủy
}

/// Loại dự án
enum ProjectType {
  residential,    // Nhà ở
  office,         // Văn phòng
  commercial,     // Thương mại
  industrial,     // Công nghiệp
  other,          // Khác
}

/// Mô hình Pipeline dự án - theo dõi quá trình từ thiết kế → thi công → vật liệu
class ProjectPipeline {
  final String id;
  final String projectName;
  final String ownerId; // ID người dùng thường (chủ dự án)
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Thông tin dự án mới (Phase 1)
  final String? description; // Mô tả dự án
  final double? budget; // Ngân sách tổng dự kiến (VNĐ) - optional, có thể tính từ breakdown
  final String? location; // Địa điểm (Tỉnh/Thành phố)
  final DateTime? startDate; // Ngày bắt đầu dự kiến
  final DateTime? endDate; // Ngày hoàn thành dự kiến
  final ProjectStatus status; // Trạng thái dự án
  final ProjectType? projectType; // Loại dự án
  
  // Budget breakdown (Phase 1 Enhancement)
  final double? designBudget; // Ngân sách cho nhà thiết kế (triệu VNĐ)
  final double? constructionBudget; // Ngân sách cho chủ thầu (triệu VNĐ)
  final double? materialsBudget; // Ngân sách cho cửa hàng VLXD (triệu VNĐ)
  
  // Thông tin giai đoạn thiết kế
  final String? designerId;
  final String? designerName;
  final CollaborationStatus designStatus;
  final String? designFileUrl; // File thiết kế đã chốt
  final DateTime? designCompletedAt;
  
  // Thông tin giai đoạn thi công
  final String? contractorId;
  final String? contractorName;
  final CollaborationStatus constructionStatus;
  final String? constructionPlanUrl; // Kế hoạch thi công
  final DateTime? constructionCompletedAt;
  
  // Thông tin giai đoạn vật liệu
  final String? storeId;
  final String? storeName;
  final CollaborationStatus materialsStatus;
  final String? materialQuoteUrl; // Báo giá vật liệu
  final DateTime? materialsCompletedAt;
  
  // Metadata từ tìm kiếm ban đầu
  final Map<String, dynamic>? searchMetadata; // Tiêu chí tìm kiếm ban đầu
  final PipelineStage currentStage; // Giai đoạn hiện tại
  
  ProjectPipeline({
    required this.id,
    required this.projectName,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.budget,
    this.location,
    this.startDate,
    this.endDate,
    this.status = ProjectStatus.planning,
    this.projectType,
    this.designBudget,
    this.constructionBudget,
    this.materialsBudget,
    this.designerId,
    this.designerName,
    this.designStatus = CollaborationStatus.none,
    this.designFileUrl,
    this.designCompletedAt,
    this.contractorId,
    this.contractorName,
    this.constructionStatus = CollaborationStatus.none,
    this.constructionPlanUrl,
    this.constructionCompletedAt,
    this.storeId,
    this.storeName,
    this.materialsStatus = CollaborationStatus.none,
    this.materialQuoteUrl,
    this.materialsCompletedAt,
    this.searchMetadata,
    this.currentStage = PipelineStage.design,
  });

  ProjectPipeline copyWith({
    String? id,
    String? projectName,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    double? budget,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    ProjectType? projectType,
    double? designBudget,
    double? constructionBudget,
    double? materialsBudget,
    String? designerId,
    String? designerName,
    CollaborationStatus? designStatus,
    String? designFileUrl,
    DateTime? designCompletedAt,
    String? contractorId,
    String? contractorName,
    CollaborationStatus? constructionStatus,
    String? constructionPlanUrl,
    DateTime? constructionCompletedAt,
    String? storeId,
    String? storeName,
    CollaborationStatus? materialsStatus,
    String? materialQuoteUrl,
    DateTime? materialsCompletedAt,
    Map<String, dynamic>? searchMetadata,
    PipelineStage? currentStage,
  }) {
    return ProjectPipeline(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      projectType: projectType ?? this.projectType,
      designBudget: designBudget ?? this.designBudget,
      constructionBudget: constructionBudget ?? this.constructionBudget,
      materialsBudget: materialsBudget ?? this.materialsBudget,
      designerId: designerId ?? this.designerId,
      designerName: designerName ?? this.designerName,
      designStatus: designStatus ?? this.designStatus,
      designFileUrl: designFileUrl ?? this.designFileUrl,
      designCompletedAt: designCompletedAt ?? this.designCompletedAt,
      contractorId: contractorId ?? this.contractorId,
      contractorName: contractorName ?? this.contractorName,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      constructionPlanUrl: constructionPlanUrl ?? this.constructionPlanUrl,
      constructionCompletedAt: constructionCompletedAt ?? this.constructionCompletedAt,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      materialsStatus: materialsStatus ?? this.materialsStatus,
      materialQuoteUrl: materialQuoteUrl ?? this.materialQuoteUrl,
      materialsCompletedAt: materialsCompletedAt ?? this.materialsCompletedAt,
      searchMetadata: searchMetadata ?? this.searchMetadata,
      currentStage: currentStage ?? this.currentStage,
    );
  }

  /// Chuyển đổi từ Firestore document
  factory ProjectPipeline.fromFirestore(Map<String, dynamic> data, String docId) {
    return ProjectPipeline(
      id: docId,
      projectName: data['projectName'] ?? 'Dự án không tên',
      ownerId: data['ownerId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) 
          : null,
      description: data['description'],
      budget: data['budget'] != null ? (data['budget'] as num).toDouble() : null,
      location: data['location'],
      designBudget: data['designBudget'] != null ? (data['designBudget'] as num).toDouble() : null,
      constructionBudget: data['constructionBudget'] != null ? (data['constructionBudget'] as num).toDouble() : null,
      materialsBudget: data['materialsBudget'] != null ? (data['materialsBudget'] as num).toDouble() : null,
      startDate: data['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['startDate'])
          : null,
      endDate: data['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
          : null,
      status: _parseProjectStatus(data['status']),
      projectType: _parseProjectType(data['projectType']),
      designerId: data['designerId'],
      designerName: data['designerName'],
      designStatus: _parseCollaborationStatus(data['designStatus']),
      designFileUrl: data['designFileUrl'],
      designCompletedAt: data['designCompletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['designCompletedAt'])
          : null,
      contractorId: data['contractorId'],
      contractorName: data['contractorName'],
      constructionStatus: _parseCollaborationStatus(data['constructionStatus']),
      constructionPlanUrl: data['constructionPlanUrl'],
      constructionCompletedAt: data['constructionCompletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['constructionCompletedAt'])
          : null,
      storeId: data['storeId'],
      storeName: data['storeName'],
      materialsStatus: _parseCollaborationStatus(data['materialsStatus']),
      materialQuoteUrl: data['materialQuoteUrl'],
      materialsCompletedAt: data['materialsCompletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['materialsCompletedAt'])
          : null,
      searchMetadata: data['searchMetadata'] != null 
          ? Map<String, dynamic>.from(data['searchMetadata']) 
          : null,
      currentStage: _parsePipelineStage(data['currentStage']),
    );
  }

  /// Chuyển đổi sang Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'projectName': projectName,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'description': description,
      'budget': budget,
      'location': location,
      'designBudget': designBudget,
      'constructionBudget': constructionBudget,
      'materialsBudget': materialsBudget,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'projectType': projectType?.toString().split('.').last,
      'designerId': designerId,
      'designerName': designerName,
      'designStatus': designStatus.toString().split('.').last,
      'designFileUrl': designFileUrl,
      'designCompletedAt': designCompletedAt?.millisecondsSinceEpoch,
      'contractorId': contractorId,
      'contractorName': contractorName,
      'constructionStatus': constructionStatus.toString().split('.').last,
      'constructionPlanUrl': constructionPlanUrl,
      'constructionCompletedAt': constructionCompletedAt?.millisecondsSinceEpoch,
      'storeId': storeId,
      'storeName': storeName,
      'materialsStatus': materialsStatus.toString().split('.').last,
      'materialQuoteUrl': materialQuoteUrl,
      'materialsCompletedAt': materialsCompletedAt?.millisecondsSinceEpoch,
      'searchMetadata': searchMetadata,
      'currentStage': currentStage.toString().split('.').last,
    };
  }

  static CollaborationStatus _parseCollaborationStatus(dynamic value) {
    if (value == null) return CollaborationStatus.none;
    final str = value.toString().split('.').last;
    return CollaborationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == str,
      orElse: () => CollaborationStatus.none,
    );
  }

  static PipelineStage _parsePipelineStage(dynamic value) {
    if (value == null) return PipelineStage.design;
    final str = value.toString().split('.').last;
    return PipelineStage.values.firstWhere(
      (e) => e.toString().split('.').last == str,
      orElse: () => PipelineStage.design,
    );
  }

  static ProjectStatus _parseProjectStatus(dynamic value) {
    if (value == null) return ProjectStatus.planning;
    final str = value.toString().split('.').last;
    return ProjectStatus.values.firstWhere(
      (e) => e.toString().split('.').last == str,
      orElse: () => ProjectStatus.planning,
    );
  }

  static ProjectType? _parseProjectType(dynamic value) {
    if (value == null) return null;
    final str = value.toString().split('.').last;
    try {
      return ProjectType.values.firstWhere(
        (e) => e.toString().split('.').last == str,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Kiểm tra xem dự án có đối tác nào chưa
  bool hasAnyPartner() {
    return designerId != null || contractorId != null || storeId != null;
  }
  
  /// Lấy ngân sách theo loại đối tác
  double? getBudgetForPartnerType(UserAccountType accountType) {
    switch (accountType) {
      case UserAccountType.designer:
        return designBudget;
      case UserAccountType.contractor:
        return constructionBudget;
      case UserAccountType.store:
        return materialsBudget;
      default:
        return null;
    }
  }
  
  /// Tính tổng ngân sách từ breakdown (nếu có)
  double? getTotalBudget() {
    double? total;
    if (designBudget != null) total = (total ?? 0) + designBudget!;
    if (constructionBudget != null) total = (total ?? 0) + constructionBudget!;
    if (materialsBudget != null) total = (total ?? 0) + materialsBudget!;
    return total ?? budget; // Fallback to total budget if breakdown is empty
  }

  /// Lấy trạng thái hợp tác theo giai đoạn
  CollaborationStatus getStatusForStage(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.design:
        return designStatus;
      case PipelineStage.construction:
        return constructionStatus;
      case PipelineStage.materials:
        return materialsStatus;
    }
  }

  /// Lấy tên đối tác theo giai đoạn
  String? getPartnerNameForStage(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.design:
        return designerName;
      case PipelineStage.construction:
        return contractorName;
      case PipelineStage.materials:
        return storeName;
    }
  }

  /// Kiểm tra xem có đang hợp tác ở giai đoạn nào không
  bool isCollaboratingAtStage(PipelineStage stage) {
    final status = getStatusForStage(stage);
    return status == CollaborationStatus.accepted || 
           status == CollaborationStatus.inProgress;
  }

  /// Lấy mô tả trạng thái
  String getStatusDescription() {
    switch (currentStage) {
      case PipelineStage.design:
        switch (designStatus) {
          case CollaborationStatus.none:
            return 'Chưa tìm nhà thiết kế';
          case CollaborationStatus.requested:
            return 'Đã gửi yêu cầu hợp tác thiết kế';
          case CollaborationStatus.accepted:
          case CollaborationStatus.inProgress:
            return 'Đang hợp tác với ${designerName ?? "nhà thiết kế"}';
          case CollaborationStatus.completed:
            return 'Đã hoàn thành thiết kế';
          case CollaborationStatus.cancelled:
            return 'Đã hủy hợp tác thiết kế';
        }
      case PipelineStage.construction:
        switch (constructionStatus) {
          case CollaborationStatus.none:
            return 'Chưa tìm chủ thầu';
          case CollaborationStatus.requested:
            return 'Đã gửi yêu cầu hợp tác thi công';
          case CollaborationStatus.accepted:
          case CollaborationStatus.inProgress:
            return 'Đang hợp tác với ${contractorName ?? "chủ thầu"}';
          case CollaborationStatus.completed:
            return 'Đã hoàn thành thi công';
          case CollaborationStatus.cancelled:
            return 'Đã hủy hợp tác thi công';
        }
      case PipelineStage.materials:
        switch (materialsStatus) {
          case CollaborationStatus.none:
            return 'Chưa tìm cửa hàng VLXD';
          case CollaborationStatus.requested:
            return 'Đã gửi yêu cầu báo giá';
          case CollaborationStatus.accepted:
          case CollaborationStatus.inProgress:
            return 'Đang hợp tác với ${storeName ?? "cửa hàng VLXD"}';
          case CollaborationStatus.completed:
            return 'Đã hoàn thành mua vật liệu';
          case CollaborationStatus.cancelled:
            return 'Đã hủy hợp tác mua vật liệu';
        }
    }
  }
}
