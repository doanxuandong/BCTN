import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_pipeline.dart';

/// Model cho dự án đã hoàn thành
/// Lưu trong profile của người thực hiện (Designer, Contractor, Store)
class CompletedProject {
  final String id; // ID của completed project record
  final String pipelineId; // ID của pipeline gốc
  final String projectName; // Tên dự án
  final String projectOwnerId; // ID của chủ dự án (owner)
  final String projectOwnerName; // Tên của chủ dự án
  final String? projectOwnerAvatar; // Avatar của chủ dự án
  
  // Giai đoạn đã hoàn thành
  final String completedStage; // 'design', 'construction', 'materials'
  final String completedStageName; // 'Thiết kế', 'Thi công', 'Vật liệu'
  
  // Thông tin dự án
  final String? projectDescription; // Mô tả dự án
  final String? projectLocation; // Địa điểm dự án
  final ProjectType? projectType; // Loại dự án
  final String? projectImageUrl; // Ảnh dự án (nếu có)
  
  // File đã hoàn thành
  final String? completedFileUrl; // URL file đã hoàn thành (design file, construction plan, quote)
  
  // Ngày tháng
  final DateTime completedAt; // Ngày hoàn thành
  final DateTime createdAt; // Ngày tạo record
  
  // Người thực hiện
  final String completedByUserId; // ID người hoàn thành (designer/contractor/store)
  final String completedByName; // Tên người hoàn thành
  
  CompletedProject({
    required this.id,
    required this.pipelineId,
    required this.projectName,
    required this.projectOwnerId,
    required this.projectOwnerName,
    this.projectOwnerAvatar,
    required this.completedStage,
    required this.completedStageName,
    this.projectDescription,
    this.projectLocation,
    this.projectType,
    this.projectImageUrl,
    this.completedFileUrl,
    required this.completedAt,
    required this.createdAt,
    required this.completedByUserId,
    required this.completedByName,
  });

  /// Tạo từ Firestore DocumentSnapshot
  factory CompletedProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompletedProject(
      id: doc.id,
      pipelineId: data['pipelineId'] ?? '',
      projectName: data['projectName'] ?? '',
      projectOwnerId: data['projectOwnerId'] ?? '',
      projectOwnerName: data['projectOwnerName'] ?? '',
      projectOwnerAvatar: data['projectOwnerAvatar'],
      completedStage: data['completedStage'] ?? '',
      completedStageName: data['completedStageName'] ?? '',
      projectDescription: data['projectDescription'],
      projectLocation: data['projectLocation'],
      projectType: data['projectType'] != null
          ? _parseProjectType(data['projectType'])
          : null,
      projectImageUrl: data['projectImageUrl'],
      completedFileUrl: data['completedFileUrl'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedByUserId: data['completedByUserId'] ?? '',
      completedByName: data['completedByName'] ?? '',
    );
  }


  /// Parse ProjectType từ string
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

  /// Convert sang Map để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'pipelineId': pipelineId,
      'projectName': projectName,
      'projectOwnerId': projectOwnerId,
      'projectOwnerName': projectOwnerName,
      if (projectOwnerAvatar != null) 'projectOwnerAvatar': projectOwnerAvatar,
      'completedStage': completedStage,
      'completedStageName': completedStageName,
      if (projectDescription != null) 'projectDescription': projectDescription,
      if (projectLocation != null) 'projectLocation': projectLocation,
      if (projectType != null) 'projectType': projectType.toString().split('.').last,
      if (projectImageUrl != null) 'projectImageUrl': projectImageUrl,
      if (completedFileUrl != null) 'completedFileUrl': completedFileUrl,
      'completedAt': Timestamp.fromDate(completedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedByUserId': completedByUserId,
      'completedByName': completedByName,
    };
  }
}

