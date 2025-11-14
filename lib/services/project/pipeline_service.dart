import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_pipeline.dart';
import '../user/user_session.dart';

class PipelineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'project_pipelines';

  /// Tạo pipeline mới từ tìm kiếm nhà thiết kế
  static Future<String?> createPipelineFromDesignerSearch({
    required String designerId,
    required String designerName,
    required Map<String, dynamic> searchMetadata,
    String? projectName,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final ownerId = currentUser['userId']?.toString();
      if (ownerId == null) return null;

      final pipeline = ProjectPipeline(
        id: '', // Will be set by Firestore
        projectName: projectName ?? 'Dự án mới',
        ownerId: ownerId,
        createdAt: DateTime.now(),
        designerId: designerId,
        designerName: designerName,
        designStatus: CollaborationStatus.requested,
        searchMetadata: searchMetadata,
        currentStage: PipelineStage.design,
      );

      final docRef = await _firestore.collection(_collection).add(pipeline.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error creating pipeline: $e');
      return null;
    }
  }

  /// Tạo pipeline mới từ tìm kiếm chủ thầu (Contractor)
  /// Nếu đã có pipeline với Designer, sẽ cập nhật pipeline đó
  /// Nếu chưa có, sẽ tạo pipeline mới
  static Future<String?> createPipelineFromContractorSearch({
    required String contractorId,
    required String contractorName,
    required Map<String, dynamic> searchMetadata,
    String? projectName,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final ownerId = currentUser['userId']?.toString();
      if (ownerId == null) return null;

      // Tìm pipeline hiện tại có Designer (chưa có Contractor)
      // Firestore không hỗ trợ isNotNull, nên query tất cả rồi filter ở client-side
      final existingPipelineSnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // Filter: Tìm pipeline có designerId nhưng chưa có contractorId
      if (existingPipelineSnapshot.docs.isNotEmpty) {
        for (var doc in existingPipelineSnapshot.docs) {
          final data = doc.data();
          
          // Chỉ cập nhật nếu pipeline có Designer nhưng chưa có Contractor
          if (data['designerId'] != null && 
              (data['contractorId'] == null || data['contractorId'] == '')) {
            final existingPipelineId = doc.id;
            
            print('✅ Found existing pipeline with Designer, updating with Contractor: $existingPipelineId');
            
            await _firestore.collection(_collection).doc(existingPipelineId).update({
              'contractorId': contractorId,
              'contractorName': contractorName,
              'constructionStatus': CollaborationStatus.requested.toString().split('.').last,
              'currentStage': PipelineStage.construction.toString().split('.').last,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
            
            return existingPipelineId;
          }
        }
      }
      
      // Không tìm thấy pipeline phù hợp, tạo pipeline mới với Contractor
      print('✅ No existing pipeline found, creating new pipeline with Contractor');
      
      final pipeline = ProjectPipeline(
        id: '', // Will be set by Firestore
        projectName: projectName ?? 'Dự án mới',
        ownerId: ownerId,
        createdAt: DateTime.now(),
        contractorId: contractorId,
        contractorName: contractorName,
        constructionStatus: CollaborationStatus.requested,
        searchMetadata: searchMetadata,
        currentStage: PipelineStage.construction,
      );

      final docRef = await _firestore.collection(_collection).add(pipeline.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error creating contractor pipeline: $e');
      return null;
    }
  }

  /// Tạo pipeline mới từ tìm kiếm cửa hàng vật liệu (Store)
  /// Nếu đã có pipeline với Designer/Contractor, sẽ cập nhật pipeline đó
  /// Nếu chưa có, sẽ tạo pipeline mới
  static Future<String?> createPipelineFromStoreSearch({
    required String storeId,
    required String storeName,
    required Map<String, dynamic> searchMetadata,
    String? projectName,
  }) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;

      final ownerId = currentUser['userId']?.toString();
      if (ownerId == null) return null;

      // Tìm pipeline hiện tại có Designer hoặc Contractor (chưa có Store)
      // Ưu tiên pipeline đang ở giai đoạn construction hoặc materials
      final existingPipelineSnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .where('storeId', isNull: true)
          .limit(1)
          .get();

      if (existingPipelineSnapshot.docs.isNotEmpty) {
        // Cập nhật pipeline hiện tại với Store
        final existingDoc = existingPipelineSnapshot.docs.first;
        final existingPipelineId = existingDoc.id;
        
        print('✅ Found existing pipeline, updating with Store: $existingPipelineId');
        
        await _firestore.collection(_collection).doc(existingPipelineId).update({
          'storeId': storeId,
          'storeName': storeName,
          'materialsStatus': CollaborationStatus.requested.toString().split('.').last,
          'currentStage': PipelineStage.materials.toString().split('.').last,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        
        return existingPipelineId;
      } else {
        // Tạo pipeline mới với Store
        print('✅ No existing pipeline found, creating new pipeline with Store');
        
        final pipeline = ProjectPipeline(
          id: '', // Will be set by Firestore
          projectName: projectName ?? 'Dự án mới',
          ownerId: ownerId,
          createdAt: DateTime.now(),
          storeId: storeId,
          storeName: storeName,
          materialsStatus: CollaborationStatus.requested,
          searchMetadata: searchMetadata,
          currentStage: PipelineStage.materials,
        );

        final docRef = await _firestore.collection(_collection).add(pipeline.toFirestore());
        return docRef.id;
      }
    } catch (e) {
      print('❌ Error creating store pipeline: $e');
      return null;
    }
  }

  /// Lấy pipeline theo ID
  static Future<ProjectPipeline?> getPipeline(String pipelineId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(pipelineId).get();
      if (!doc.exists) return null;
      return ProjectPipeline.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error getting pipeline: $e');
      return null;
    }
  }

  /// Lấy tất cả pipeline của người dùng hiện tại
  /// Bao gồm: pipelines mà user là owner, designer, contractor, hoặc store
  static Future<List<ProjectPipeline>> getUserPipelines() async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        print('⚠️ No current user');
        return [];
      }

      final userId = currentUser['userId']?.toString();
      if (userId == null) {
        print('⚠️ No userId in current user');
        return [];
      }

      print('🔍 Getting ALL pipelines for userId: $userId (as owner, designer, contractor, or store)');

      // Query pipelines mà user là owner
      final ownerSnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .get();
      
      print('✅ Found ${ownerSnapshot.docs.length} pipelines where user is OWNER');

      // Query pipelines mà user là designer
      final designerSnapshot = await _firestore
          .collection(_collection)
          .where('designerId', isEqualTo: userId)
          .get();
      
      print('✅ Found ${designerSnapshot.docs.length} pipelines where user is DESIGNER');

      // Query pipelines mà user là contractor
      final contractorSnapshot = await _firestore
          .collection(_collection)
          .where('contractorId', isEqualTo: userId)
          .get();
      
      print('✅ Found ${contractorSnapshot.docs.length} pipelines where user is CONTRACTOR');

      // Query pipelines mà user là store
      final storeSnapshot = await _firestore
          .collection(_collection)
          .where('storeId', isEqualTo: userId)
          .get();
      
      print('✅ Found ${storeSnapshot.docs.length} pipelines where user is STORE');

      // Merge tất cả documents và remove duplicates
      final allDocs = <String, DocumentSnapshot>{};
      
      for (var doc in ownerSnapshot.docs) {
        allDocs[doc.id] = doc;
      }
      for (var doc in designerSnapshot.docs) {
        allDocs[doc.id] = doc;
      }
      for (var doc in contractorSnapshot.docs) {
        allDocs[doc.id] = doc;
      }
      for (var doc in storeSnapshot.docs) {
        allDocs[doc.id] = doc;
      }

      print('✅ Total unique pipelines: ${allDocs.length}');

      final pipelines = <ProjectPipeline>[];
      for (var doc in allDocs.values) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          
          // Xác định vai trò của user trong pipeline này
          final pipelineOwnerId = data['ownerId']?.toString();
          final pipelineDesignerId = data['designerId']?.toString();
          final pipelineContractorId = data['contractorId']?.toString();
          final pipelineStoreId = data['storeId']?.toString();
          
          String userRole = 'Unknown';
          if (pipelineOwnerId == userId) userRole = 'Owner';
          else if (pipelineDesignerId == userId) userRole = 'Designer';
          else if (pipelineContractorId == userId) userRole = 'Contractor';
          else if (pipelineStoreId == userId) userRole = 'Store';
          
          print('  📄 Pipeline ${doc.id} (User role: $userRole):');
          print('    - projectName: ${data['projectName']}');
          print('    - ownerId: $pipelineOwnerId');
          print('    - designerId: $pipelineDesignerId, designerName: ${data['designerName']}');
          print('    - contractorId: $pipelineContractorId, contractorName: ${data['contractorName']}');
          print('    - storeId: $pipelineStoreId, storeName: ${data['storeName']}');
          print('    - designStatus: ${data['designStatus']}');
          print('    - constructionStatus: ${data['constructionStatus']}');
          print('    - materialsStatus: ${data['materialsStatus']}');
          
          final pipeline = ProjectPipeline.fromFirestore(data, doc.id);
          pipelines.add(pipeline);
          print('  ✅ Parsed pipeline: ${pipeline.projectName}, ID: ${pipeline.id}');
          print('    - Designer: ${pipeline.designerName ?? "null"}, Status: ${pipeline.designStatus}');
          print('    - Contractor: ${pipeline.contractorName ?? "null"}, Status: ${pipeline.constructionStatus}');
          print('    - Store: ${pipeline.storeName ?? "null"}, Status: ${pipeline.materialsStatus}');
        } catch (e, stackTrace) {
          print('⚠️ Error parsing pipeline ${doc.id}: $e');
          print('⚠️ Stack trace: $stackTrace');
        }
      }

      // Sort theo createdAt (mới nhất trước) ở client-side
      pipelines.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Returning ${pipelines.length} pipelines');
      return pipelines;
    } catch (e, stackTrace) {
      print('❌ Error getting user pipelines: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Lấy pipeline mà người dùng đang tham gia (như designer, contractor, store)
  static Future<List<ProjectPipeline>> getParticipatingPipelines() async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return [];

      final userId = currentUser['userId']?.toString();
      if (userId == null) return [];

      // Tìm pipeline mà user là designer, contractor, hoặc store
      final snapshot = await _firestore
          .collection(_collection)
          .where('designerId', isEqualTo: userId)
          .get();

      final contractorSnapshot = await _firestore
          .collection(_collection)
          .where('contractorId', isEqualTo: userId)
          .get();

      final storeSnapshot = await _firestore
          .collection(_collection)
          .where('storeId', isEqualTo: userId)
          .get();

      final allDocs = <DocumentSnapshot>[];
      allDocs.addAll(snapshot.docs);
      allDocs.addAll(contractorSnapshot.docs);
      allDocs.addAll(storeSnapshot.docs);

      // Remove duplicates
      final uniqueIds = <String>{};
      final uniqueDocs = <DocumentSnapshot>[];
      for (var doc in allDocs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          uniqueDocs.add(doc);
        }
      }

      return uniqueDocs
          .map((doc) => ProjectPipeline.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('❌ Error getting participating pipelines: $e');
      return [];
    }
  }

  /// Chấp nhận hợp tác thiết kế
  static Future<bool> acceptDesignCollaboration(String pipelineId) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'designStatus': CollaborationStatus.accepted.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error accepting design collaboration: $e');
      return false;
    }
  }

  /// Cập nhật designFileUrl (không thay đổi status)
  /// Sử dụng khi Designer gửi file thiết kế trong chat
  static Future<bool> updateDesignFileUrl({
    required String pipelineId,
    required String designFileUrl,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'designFileUrl': designFileUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Design file URL updated: $designFileUrl');
      return true;
    } catch (e) {
      print('❌ Error updating design file URL: $e');
      return false;
    }
  }

  /// Hoàn thành thiết kế và chuyển sang giai đoạn thi công
  static Future<bool> completeDesign({
    required String pipelineId,
    required String designFileUrl,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'designStatus': CollaborationStatus.completed.toString().split('.').last,
        'designFileUrl': designFileUrl,
        'designCompletedAt': DateTime.now().millisecondsSinceEpoch,
        'currentStage': PipelineStage.construction.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error completing design: $e');
      return false;
    }
  }

  /// Gửi thiết kế cho chủ thầu
  static Future<bool> sendDesignToContractor({
    required String pipelineId,
    required String contractorId,
    required String contractorName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'contractorId': contractorId,
        'contractorName': contractorName,
        'constructionStatus': CollaborationStatus.requested.toString().split('.').last,
        'currentStage': PipelineStage.construction.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error sending design to contractor: $e');
      return false;
    }
  }

  /// Chấp nhận hợp tác thi công
  static Future<bool> acceptConstructionCollaboration(String pipelineId) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'constructionStatus': CollaborationStatus.accepted.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error accepting construction collaboration: $e');
      return false;
    }
  }

  /// Cập nhật constructionPlanUrl (không thay đổi status)
  /// Sử dụng khi Contractor gửi kế hoạch thi công trong chat
  static Future<bool> updateConstructionPlanUrl({
    required String pipelineId,
    required String constructionPlanUrl,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'constructionPlanUrl': constructionPlanUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Construction plan URL updated: $constructionPlanUrl');
      return true;
    } catch (e) {
      print('❌ Error updating construction plan URL: $e');
      return false;
    }
  }

  /// Gửi kế hoạch thi công
  static Future<bool> submitConstructionPlan({
    required String pipelineId,
    required String planUrl,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'constructionStatus': CollaborationStatus.inProgress.toString().split('.').last,
        'constructionPlanUrl': planUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error submitting construction plan: $e');
      return false;
    }
  }

  /// Hoàn thành thi công và chuyển sang giai đoạn vật liệu
  static Future<bool> completeConstruction({
    required String pipelineId,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'constructionStatus': CollaborationStatus.completed.toString().split('.').last,
        'constructionCompletedAt': DateTime.now().millisecondsSinceEpoch,
        'currentStage': PipelineStage.materials.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error completing construction: $e');
      return false;
    }
  }

  /// Gửi kế hoạch thi công cho cửa hàng VLXD
  static Future<bool> sendConstructionPlanToStore({
    required String pipelineId,
    required String storeId,
    required String storeName,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'storeId': storeId,
        'storeName': storeName,
        'materialsStatus': CollaborationStatus.requested.toString().split('.').last,
        'currentStage': PipelineStage.materials.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error sending plan to store: $e');
      return false;
    }
  }

  /// Chấp nhận hợp tác mua vật liệu
  static Future<bool> acceptMaterialsCollaboration(String pipelineId) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'materialsStatus': CollaborationStatus.accepted.toString().split('.').last,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error accepting materials collaboration: $e');
      return false;
    }
  }

  /// Cập nhật materialQuoteUrl (không thay đổi status)
  /// Sử dụng khi Store gửi báo giá vật liệu trong chat
  static Future<bool> updateMaterialQuoteUrl({
    required String pipelineId,
    required String materialQuoteUrl,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'materialQuoteUrl': materialQuoteUrl,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Material quote URL updated: $materialQuoteUrl');
      return true;
    } catch (e) {
      print('❌ Error updating material quote URL: $e');
      return false;
    }
  }

  /// Hoàn thành mua vật liệu
  static Future<bool> completeMaterials({
    required String pipelineId,
    required String quoteUrl,
  }) async {
    try {
      await _firestore.collection(_collection).doc(pipelineId).update({
        'materialsStatus': CollaborationStatus.completed.toString().split('.').last,
        'materialQuoteUrl': quoteUrl,
        'materialsCompletedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error completing materials: $e');
      return false;
    }
  }

  /// Lấy pipeline từ chat ID (nếu có)
  /// Ưu tiên đọc pipelineId trực tiếp từ chat document (nhanh hơn)
  /// Nếu không có, sẽ query theo participants (fallback)
  static Future<ProjectPipeline?> getPipelineFromChat(String chatId) async {
    try {
      // Ưu tiên: Đọc pipelineId trực tiếp từ chat document
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return null;

      final chatData = chatDoc.data()!;
      final pipelineId = chatData['pipelineId'] as String?;

      // Nếu có pipelineId trong chat document, đọc trực tiếp (nhanh hơn)
      if (pipelineId != null && pipelineId.isNotEmpty) {
        final pipeline = await getPipeline(pipelineId);
        if (pipeline != null) {
          return pipeline;
        }
      }

      // Fallback: Tìm pipeline theo participants (cho backward compatibility)
      final participants = List<String>.from(chatData['participants'] ?? []);
      
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return null;
      final userId = currentUser['userId']?.toString();
      if (userId == null) return null;

      // Tìm pipeline mà user là owner và có designer/contractor/store trong participants
      final otherUserId = participants.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) return null;

      // Tìm pipeline có designerId, contractorId, hoặc storeId trùng với otherUserId
      final designerSnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .where('designerId', isEqualTo: otherUserId)
          .limit(1)
          .get();

      if (designerSnapshot.docs.isNotEmpty) {
        return ProjectPipeline.fromFirestore(
          designerSnapshot.docs.first.data(),
          designerSnapshot.docs.first.id,
        );
      }

      final contractorSnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .where('contractorId', isEqualTo: otherUserId)
          .limit(1)
          .get();

      if (contractorSnapshot.docs.isNotEmpty) {
        return ProjectPipeline.fromFirestore(
          contractorSnapshot.docs.first.data(),
          contractorSnapshot.docs.first.id,
        );
      }

      final storeSnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .where('storeId', isEqualTo: otherUserId)
          .limit(1)
          .get();

      if (storeSnapshot.docs.isNotEmpty) {
        return ProjectPipeline.fromFirestore(
          storeSnapshot.docs.first.data(),
          storeSnapshot.docs.first.id,
        );
      }

      return null;
    } catch (e) {
      print('❌ Error getting pipeline from chat: $e');
      return null;
    }
  }
}

