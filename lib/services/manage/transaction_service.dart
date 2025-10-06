import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/material_transaction.dart' as transaction;
import 'transaction_history_service.dart';

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
    } catch (e) {
      print('Error updating material stock: $e');
      rethrow; // Re-throw để caller có thể xử lý
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
