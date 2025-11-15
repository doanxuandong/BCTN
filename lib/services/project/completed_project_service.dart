import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/completed_project.dart';
import '../../models/project_pipeline.dart';
import '../../services/user/user_profile_service.dart';

/// Service để quản lý completed projects
class CompletedProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'completed_projects';

  /// Lưu completed project vào profile của người thực hiện
  /// Được gọi khi owner đánh dấu hoàn thành một giai đoạn
  static Future<bool> saveCompletedProject({
    required ProjectPipeline pipeline,
    required PipelineStage completedStage,
    required String completedByUserId, // ID người hoàn thành (designer/contractor/store)
    required String completedByName, // Tên người hoàn thành
  }) async {
    try {
      // Xác định completed stage info
      String completedStageValue;
      String completedStageName;
      String? completedFileUrl;
      DateTime? completedAt;

      switch (completedStage) {
        case PipelineStage.design:
          completedStageValue = 'design';
          completedStageName = 'Thiết kế';
          completedFileUrl = pipeline.designFileUrl;
          completedAt = pipeline.designCompletedAt;
          break;
        case PipelineStage.construction:
          completedStageValue = 'construction';
          completedStageName = 'Thi công';
          completedFileUrl = pipeline.constructionPlanUrl;
          completedAt = pipeline.constructionCompletedAt;
          break;
        case PipelineStage.materials:
          completedStageValue = 'materials';
          completedStageName = 'Vật liệu';
          completedFileUrl = pipeline.materialQuoteUrl;
          completedAt = pipeline.materialsCompletedAt;
          break;
      }

      // Lấy thông tin owner
      String ownerName = 'Chủ dự án';
      String? ownerAvatar;
      try {
        final ownerProfile = await UserProfileService.getProfile(pipeline.ownerId);
        if (ownerProfile != null) {
          ownerName = ownerProfile.displayName;
          ownerAvatar = ownerProfile.displayAvatar;
        }
      } catch (e) {
        print('⚠️ Error loading owner profile: $e');
      }

      // Đảm bảo completedByUserId là String (nếu là number thì convert)
      final completedByUserIdString = completedByUserId.toString();
      
      // Validation
      if (completedByUserIdString.isEmpty) {
        print('❌ Error: completedByUserId is empty');
        return false;
      }
      
      // Tạo completed project record
      final completedProject = CompletedProject(
        id: '', // Will be set by Firestore
        pipelineId: pipeline.id,
        projectName: pipeline.projectName,
        projectOwnerId: pipeline.ownerId,
        projectOwnerName: ownerName,
        projectOwnerAvatar: ownerAvatar,
        completedStage: completedStageValue,
        completedStageName: completedStageName,
        projectDescription: pipeline.description,
        projectLocation: pipeline.location,
        projectType: pipeline.projectType,
        projectImageUrl: null, // TODO: Có thể thêm ảnh dự án sau
        completedFileUrl: completedFileUrl,
        completedAt: completedAt ?? DateTime.now(),
        createdAt: DateTime.now(),
        completedByUserId: completedByUserIdString, // Đảm bảo là String
        completedByName: completedByName,
      );

      // Lưu vào collection completed_projects
      // Document ID: completedByUserId_pipelineId_completedStage để tránh duplicate
      final docId = '${completedByUserIdString}_${pipeline.id}_$completedStageValue';
      final dataToSave = completedProject.toFirestore();
      
      print('📝 Saving completed project:');
      print('  - DocId: $docId');
      print('  - completedByUserId: $completedByUserIdString (type: String)');
      print('  - completedByName: $completedByName');
      print('  - projectName: ${pipeline.projectName}');
      print('  - completedStage: $completedStageValue');
      print('  - completedAt: ${completedAt ?? DateTime.now()}');
      print('  - Data keys: ${dataToSave.keys.toList()}');
      
      await _firestore
          .collection(_collection)
          .doc(docId)
          .set(dataToSave, SetOptions(merge: false));

      print('✅ Saved completed project: $docId');
      print('  - Verify: Querying to check if saved...');
      
      // Verify: Query lại để kiểm tra đã lưu thành công chưa
      final verifyDoc = await _firestore.collection(_collection).doc(docId).get();
      if (verifyDoc.exists) {
        print('  - ✅ Verified: Document exists in Firestore');
        final verifyData = verifyDoc.data();
        print('  - Verified completedByUserId: ${verifyData?['completedByUserId']}');
      } else {
        print('  - ⚠️ Warning: Document not found after save');
      }
      
      return true;
    } catch (e) {
      print('❌ Error saving completed project: $e');
      return false;
    }
  }

  /// Lấy danh sách completed projects của một user
  static Future<List<CompletedProject>> getUserCompletedProjects(String userId) async {
    try {
      print('📊 Loading completed projects for userId: $userId');
      print('  - userId type: ${userId.runtimeType}');
      
      // Firestore yêu cầu composite index nếu dùng where + orderBy cùng lúc
      // Nên chỉ dùng where, rồi sort ở client-side
      // Lưu ý: Đảm bảo userId là String (nếu là number thì convert)
      final userIdString = userId.toString();
      
      print('  - Querying with userId: $userIdString');
      final snapshot = await _firestore
          .collection(_collection)
          .where('completedByUserId', isEqualTo: userIdString)
          .get();

      print('  - Found ${snapshot.docs.length} documents');
      
      final projects = snapshot.docs
          .map((doc) {
            try {
              print('  - Parsing doc: ${doc.id}');
              return CompletedProject.fromFirestore(doc);
            } catch (e) {
              print('  - ❌ Error parsing doc ${doc.id}: $e');
              return null;
            }
          })
          .where((p) => p != null)
          .cast<CompletedProject>()
          .toList();
      
      print('  - Parsed ${projects.length} projects successfully');
      
      // Sort theo completedAt (mới nhất trước) ở client-side
      projects.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      return projects;
    } catch (e) {
      print('❌ Error getting user completed projects: $e');
      print('  - Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Lấy completed project theo ID
  static Future<CompletedProject?> getCompletedProject(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return CompletedProject.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting completed project: $e');
      return null;
    }
  }
}

