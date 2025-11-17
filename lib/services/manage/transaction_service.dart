import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/material_transaction.dart' as transaction;
import '../../models/construction_material.dart';
import '../../services/project/pipeline_service.dart';
import 'transaction_history_service.dart';
import 'material_service.dart';

class TransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'material_transactions';

  // Tạo giao dịch mới
  static Future<String?> createTransaction(transaction.MaterialTransaction transaction) async {
    try {
      print('Creating transaction for material: ${transaction.materialId}');
      final data = transaction.toFirestore();
      data.remove('id');
      
      print('Adding transaction to Firestore...');
      print('Transaction data: $data');
      final ref = await _firestore.collection(_collection).add(data).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Transaction creation timeout');
        },
      );
      print('Transaction added with ID: ${ref.id}');
      print('Transaction collection: $_collection');
      
      // Cập nhật tồn kho vật liệu
      print('Updating material stock...');
      await _updateMaterialStock(transaction).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Stock update timeout');
        },
      );
      print('Material stock updated successfully');
      
      // Also save to transaction history collection
      await TransactionHistoryService.createTransactionHistory(transaction);
      
      return ref.id;
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  // Lấy giao dịch theo userId
  static Future<List<transaction.MaterialTransaction>> getTransactionsByUserId(String userId, {int limit = 100}) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snap.docs.map((doc) => transaction.MaterialTransaction.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Lấy giao dịch theo materialId
  static Future<List<transaction.MaterialTransaction>> getTransactionsByMaterialId(String materialId, {int limit = 50}) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('materialId', isEqualTo: materialId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snap.docs.map((doc) => transaction.MaterialTransaction.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting material transactions: $e');
      return [];
    }
  }

  // Phase 2 Enhancement: Lấy giao dịch theo projectId
  static Future<List<transaction.MaterialTransaction>> getTransactionsByProjectId(String projectId, {int limit = 100}) async {
    try {
      // Firestore yêu cầu composite index nếu dùng where + orderBy cùng lúc
      // Nên chỉ dùng where, rồi sort ở client-side
      final snap = await _firestore
          .collection(_collection)
          .where('projectId', isEqualTo: projectId)
          .get();
      
      final transactions = snap.docs
          .map((doc) => transaction.MaterialTransaction.fromFirestore(doc))
          .toList();
      
      // Sort theo createdAt (mới nhất trước) ở client-side
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Limit ở client-side
      if (transactions.length > limit) {
        return transactions.sublist(0, limit);
      }
      
      return transactions;
    } catch (e) {
      print('Error getting project transactions: $e');
      return [];
    }
  }

  // Phase 2 Enhancement: Lấy giao dịch của project mà user có quyền xem
  // (contractor, owner, designer, store có thể xem TẤT CẢ transactions của project họ tham gia)
  static Future<List<transaction.MaterialTransaction>> getProjectTransactionsForUser(
    String projectId,
    String userId, {
    int limit = 100,
  }) async {
    try {
      // Lấy pipeline để kiểm tra user có tham gia project không
      final pipeline = await PipelineService.getPipeline(projectId);
      
      // Nếu user là owner, contractor, designer, hoặc store trong project, trả về TẤT CẢ transactions
      if (pipeline != null) {
        final isOwner = pipeline.ownerId == userId;
        final isContractor = pipeline.contractorId == userId;
        final isDesigner = pipeline.designerId == userId;
        final isStore = pipeline.storeId == userId;
        
        if (isOwner || isContractor || isDesigner || isStore) {
          print('✅ User $userId is participant (owner/contractor/designer/store) in project $projectId, returning ALL transactions');
          // Trả về TẤT CẢ transactions của project
          final allTransactions = await getTransactionsByProjectId(projectId, limit: limit);
          return allTransactions;
        }
      }
      
      // Nếu user KHÔNG tham gia project, chỉ lấy transactions mà user liên quan
      print('⚠️ User $userId is NOT participant in project $projectId, filtering transactions');
      final allTransactions = await getTransactionsByProjectId(projectId, limit: limit);
      
      // Filter: Chỉ lấy transactions mà:
      // 1. userId = userId (user tạo transaction)
      // 2. HOẶC fromUserId = userId (user là người chuyển)
      // 3. HOẶC toUserId = userId (user là người nhận)
      final filteredTransactions = allTransactions.where((t) =>
        t.userId == userId ||
        t.fromUserId == userId ||
        t.toUserId == userId
      ).toList();
      
      return filteredTransactions;
    } catch (e) {
      print('Error getting project transactions for user: $e');
      return [];
    }
  }

  // Phase 2 Enhancement: Tính tổng chi phí của project (chỉ tính export transactions)
  static Future<double> getProjectTotalCost(String projectId) async {
    try {
      final transactions = await getTransactionsByProjectId(projectId);
      
      // Chỉ tính export transactions (xuất kho) - đây là chi phí
      double totalCost = 0;
      for (final txn in transactions) {
        if (txn.type == transaction.TransactionType.export &&
            txn.status == transaction.TransactionStatus.completed) {
          totalCost += txn.totalAmount;
        }
      }
      
      return totalCost;
    } catch (e) {
      print('Error calculating project total cost: $e');
      return 0;
    }
  }

  // Lắng nghe giao dịch realtime
  static Stream<List<transaction.MaterialTransaction>> listenTransactionsByUserId(String userId, {int limit = 100}) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => transaction.MaterialTransaction.fromFirestore(doc)).toList());
  }

  // Cập nhật trạng thái giao dịch
  static Future<bool> updateTransactionStatus(String transactionId, transaction.TransactionStatus status, {String? approvedBy}) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (approvedBy != null) {
        updateData['approvedBy'] = approvedBy;
        updateData['approvedAt'] = FieldValue.serverTimestamp();
      }
      
      await _firestore.collection(_collection).doc(transactionId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  // Xóa giao dịch
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection(_collection).doc(transactionId).delete();
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Lấy thống kê giao dịch
  static Future<TransactionStats> getTransactionStats(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);
      
      if (startDate != null) {
        query = query.where('transactionDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
      }
      
      final snap = await query.get();
      final transactions = snap.docs.map((doc) => transaction.MaterialTransaction.fromFirestore(doc)).toList();
      
      return _calculateStats(transactions);
    } catch (e) {
      print('Error getting transaction stats: $e');
      return TransactionStats.empty();
    }
  }

  // Cập nhật tồn kho vật liệu sau giao dịch
  static Future<void> _updateMaterialStock(transaction.MaterialTransaction materialTransaction) async {
    try {
      print('Fetching material: ${materialTransaction.materialId}');
      final materialDoc = await _firestore
          .collection('materials')
          .doc(materialTransaction.materialId)
          .get();
      
      if (!materialDoc.exists) {
        print('Material not found: ${materialTransaction.materialId}');
        return;
      }
      
      final materialData = materialDoc.data()!;
      double currentStock = (materialData['currentStock'] ?? 0).toDouble();
      print('Current stock before update: $currentStock');
      
      // Cập nhật tồn kho dựa trên loại giao dịch
      switch (materialTransaction.type) {
        case transaction.TransactionType.import:
          currentStock += materialTransaction.quantity;
          print('Adding ${materialTransaction.quantity} to stock');
          break;
        case transaction.TransactionType.export:
          currentStock -= materialTransaction.quantity;
          print('Subtracting ${materialTransaction.quantity} from stock');
          break;
        case transaction.TransactionType.adjust:
          currentStock = materialTransaction.quantity; // Điều chỉnh về số lượng cụ thể
          print('Adjusting stock to ${materialTransaction.quantity}');
          break;
        case transaction.TransactionType.transfer:
          // Chuyển kho - có thể cần xử lý phức tạp hơn
          currentStock -= materialTransaction.quantity;
          print('Transferring ${materialTransaction.quantity} from stock');
          break;
      }
      
      // Đảm bảo tồn kho không âm
      if (currentStock < 0) currentStock = 0;
      print('Final stock after update: $currentStock');
      
      await _firestore.collection('materials').doc(materialTransaction.materialId).update({
        'currentStock': currentStock,
        'lastUpdated': Timestamp.now(),
      });
      print('Material stock updated in Firestore');
      
      // Phase 3 Enhancement: Nếu export transaction có toUserId và projectId,
      // tự động thêm vật liệu vào kho của người nhận (owner/contractor)
      if (materialTransaction.type == transaction.TransactionType.export &&
          materialTransaction.toUserId != null &&
          materialTransaction.projectId != null) {
        await _addMaterialToReceiver(materialTransaction);
      }
    } catch (e) {
      print('Error updating material stock: $e');
      rethrow; // Re-throw để caller có thể xử lý
    }
  }

  // Phase 3 Enhancement: Thêm vật liệu vào kho của người nhận khi store xuất kho cho owner/contractor
  static Future<void> _addMaterialToReceiver(transaction.MaterialTransaction transaction) async {
    try {
      print('🔄 Adding material to receiver: ${transaction.toUserId}');
      print('  - Material: ${transaction.materialName}');
      print('  - Quantity: ${transaction.quantity}');
      
      // Lấy thông tin vật liệu gốc từ store để copy thông tin
      final sourceMaterialDoc = await _firestore
          .collection('materials')
          .doc(transaction.materialId)
          .get();
      
      if (!sourceMaterialDoc.exists) {
        print('⚠️ Source material not found: ${transaction.materialId}');
        return;
      }
      
      final sourceMaterialData = sourceMaterialDoc.data()!;
      final receiverId = transaction.toUserId!;
      
      // Tìm vật liệu có cùng tên trong kho của người nhận
      final receiverMaterials = await MaterialService.getByUserId(receiverId);
      final existingMaterial = receiverMaterials.firstWhere(
        (m) => m.name.toLowerCase() == transaction.materialName.toLowerCase() &&
               m.category == (sourceMaterialData['category'] as String? ?? ''),
        orElse: () => ConstructionMaterial(
          id: '',
          userId: receiverId,
          name: '',
          category: '',
          unit: '',
          currentStock: 0,
          minStock: 0,
          maxStock: 0,
          price: 0,
          supplier: '',
          description: '',
          lastUpdated: DateTime.now(),
        ),
      );
      
      if (existingMaterial.id.isNotEmpty) {
        // Vật liệu đã tồn tại trong kho của receiver: cập nhật stock
        print('  - Material exists, updating stock...');
        final newStock = existingMaterial.currentStock + transaction.quantity;
        await _firestore.collection('materials').doc(existingMaterial.id).update({
          'currentStock': newStock,
          'lastUpdated': Timestamp.now(),
        });
        print('  - ✅ Updated stock: ${existingMaterial.currentStock} → $newStock');
      } else {
        // Vật liệu chưa có: tạo mới cho receiver
        print('  - Material not found, creating new material for receiver...');
        final newMaterial = ConstructionMaterial(
          id: '', // Will be set by Firestore
          userId: receiverId,
          name: transaction.materialName,
          category: sourceMaterialData['category'] as String? ?? 'Khác',
          unit: sourceMaterialData['unit'] as String? ?? 'cái',
          currentStock: transaction.quantity,
          minStock: 0,
          maxStock: (sourceMaterialData['maxStock'] as num?)?.toDouble() ?? transaction.quantity * 2,
          price: transaction.unitPrice, // Sử dụng giá từ transaction
          supplier: transaction.fromUserName ?? 'Từ giao dịch',
          description: 'Nhận từ dự án: ${transaction.projectName ?? "N/A"}',
          imageUrl: sourceMaterialData['imageUrl'] as String?,
          lastUpdated: DateTime.now(),
        );
        
        final newMaterialId = await MaterialService.create(newMaterial);
        print('  - ✅ Created new material for receiver: $newMaterialId');
        print('  - Stock: ${transaction.quantity} ${newMaterial.unit}');
      }
    } catch (e) {
      print('❌ Error adding material to receiver: $e');
      // Không throw để không ảnh hưởng đến transaction chính
    }
  }

  // Tính toán thống kê
  static TransactionStats _calculateStats(List<transaction.MaterialTransaction> transactions) {
    double totalImportValue = 0;
    double totalExportValue = 0;
    double totalImportQuantity = 0;
    double totalExportQuantity = 0;
    
    Map<transaction.TransactionType, int> typeCounts = {};
    Map<transaction.TransactionStatus, int> statusCounts = {};
    
    for (final transaction in transactions) {
      if (transaction.isImport) {
        totalImportValue += transaction.totalAmount;
        totalImportQuantity += transaction.quantity;
      } else if (transaction.isExport) {
        totalExportValue += transaction.totalAmount;
        totalExportQuantity += transaction.quantity;
      }
      
      typeCounts[transaction.type] = (typeCounts[transaction.type] ?? 0) + 1;
      statusCounts[transaction.status] = (statusCounts[transaction.status] ?? 0) + 1;
    }
    
    return TransactionStats(
      totalTransactions: transactions.length,
      totalImportValue: totalImportValue,
      totalExportValue: totalExportValue,
      totalImportQuantity: totalImportQuantity,
      totalExportQuantity: totalExportQuantity,
      typeCounts: typeCounts,
      statusCounts: statusCounts,
    );
  }
}

class TransactionStats {
  final int totalTransactions;
  final double totalImportValue;
  final double totalExportValue;
  final double totalImportQuantity;
  final double totalExportQuantity;
  final Map<transaction.TransactionType, int> typeCounts;
  final Map<transaction.TransactionStatus, int> statusCounts;

  TransactionStats({
    required this.totalTransactions,
    required this.totalImportValue,
    required this.totalExportValue,
    required this.totalImportQuantity,
    required this.totalExportQuantity,
    required this.typeCounts,
    required this.statusCounts,
  });

  factory TransactionStats.empty() {
    return TransactionStats(
      totalTransactions: 0,
      totalImportValue: 0,
      totalExportValue: 0,
      totalImportQuantity: 0,
      totalExportQuantity: 0,
      typeCounts: {},
      statusCounts: {},
    );
  }

  double get netValue => totalImportValue - totalExportValue;
  double get netQuantity => totalImportQuantity - totalExportQuantity;
  
  int get importCount => typeCounts[transaction.TransactionType.import] ?? 0;
  int get exportCount => typeCounts[transaction.TransactionType.export] ?? 0;
  int get adjustCount => typeCounts[transaction.TransactionType.adjust] ?? 0;
  int get transferCount => typeCounts[transaction.TransactionType.transfer] ?? 0;
  
  int get completedCount => statusCounts[transaction.TransactionStatus.completed] ?? 0;
  int get pendingCount => statusCounts[transaction.TransactionStatus.pending] ?? 0;
  int get cancelledCount => statusCounts[transaction.TransactionStatus.cancelled] ?? 0;
}
