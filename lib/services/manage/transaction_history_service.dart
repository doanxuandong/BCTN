import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/user_session.dart';
import '../../models/material_transaction.dart' as transaction;

class TransactionHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collectionName = 'transaction_history';

  /// Tạo lịch sử giao dịch mới
  static Future<String?> createTransactionHistory(transaction.MaterialTransaction materialTransaction) async {
    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        print('No current user found');
        return null;
      }

      final transactionHistoryData = {
        'id': materialTransaction.id,
        'userId': currentUser['userId'],
        'materialId': materialTransaction.materialId,
        'materialName': materialTransaction.materialName,
        'type': materialTransaction.type.toString(),
        'quantity': materialTransaction.quantity,
        'unitPrice': materialTransaction.unitPrice,
        'totalAmount': materialTransaction.totalAmount,
        'description': materialTransaction.description,
        'status': materialTransaction.status.toString(),
        'createdAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      };

      print('Creating transaction history for user: ${currentUser['userId']}');
      print('Transaction data: $transactionHistoryData');

      final docRef = await _firestore
          .collection(_collectionName)
          .add(transactionHistoryData)
          .timeout(const Duration(seconds: 10));

      print('Transaction history created with ID: ${docRef.id}');
      
      // Verify the data was saved
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('Transaction history verified in Firestore');
      } else {
        print('ERROR: Transaction history not found in Firestore');
      }
      
      return docRef.id;
    } catch (e) {
      print('Error creating transaction history: $e');
      return null;
    }
  }

  /// Lấy lịch sử giao dịch theo userId
  static Future<List<transaction.MaterialTransaction>> getTransactionHistoryByUserId(String userId) async {
    try {
      print('Loading transaction history for user: $userId');
      print('Collection name: $_collectionName');
      
      // Bỏ orderBy để tránh lỗi index, sẽ sort trong code
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 10));

      print('Found ${querySnapshot.docs.length} transaction history records');
      
      // Debug: List all documents in collection
      final allDocs = await _firestore.collection(_collectionName).get();
      print('Total documents in $_collectionName: ${allDocs.docs.length}');
      for (var doc in allDocs.docs) {
        print('Document ID: ${doc.id}, userId: ${doc.data()['userId']}');
      }

      final transactions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Transaction history data: $data');
        
        return transaction.MaterialTransaction(
          id: data['id'] ?? '',
          materialId: data['materialId'] ?? '',
          materialName: data['materialName'] ?? '',
          userId: data['userId'] ?? '',
          type: _parseTransactionType(data['type']),
          status: _parseTransactionStatus(data['status']),
          quantity: (data['quantity'] ?? 0).toDouble(),
          unitPrice: (data['unitPrice'] ?? 0).toDouble(),
          totalAmount: (data['totalAmount'] ?? 0).toDouble(),
          supplier: data['supplier'] ?? '',
          reason: data['reason'] ?? '',
          note: data['note'] ?? '',
          description: data['description'] ?? '',
          transactionDate: _parseDateTime(data['transactionDate']),
          createdAt: _parseDateTime(data['createdAt']),
          lastUpdated: _parseDateTime(data['lastUpdated']),
          createdBy: data['createdBy'] ?? '',
        );
      }).toList();

      // Sort by createdAt descending trong code
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Parsed ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('Error loading transaction history: $e');
      return [];
    }
  }

  /// Lấy stream lịch sử giao dịch theo userId
  static Stream<List<transaction.MaterialTransaction>> listenTransactionHistoryByUserId(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return transaction.MaterialTransaction(
          id: data['id'] ?? '',
          materialId: data['materialId'] ?? '',
          materialName: data['materialName'] ?? '',
          userId: data['userId'] ?? '',
          type: _parseTransactionType(data['type']),
          status: _parseTransactionStatus(data['status']),
          quantity: (data['quantity'] ?? 0).toDouble(),
          unitPrice: (data['unitPrice'] ?? 0).toDouble(),
          totalAmount: (data['totalAmount'] ?? 0).toDouble(),
          supplier: data['supplier'] ?? '',
          reason: data['reason'] ?? '',
          note: data['note'] ?? '',
          description: data['description'] ?? '',
          transactionDate: _parseDateTime(data['transactionDate']),
          createdAt: _parseDateTime(data['createdAt']),
          lastUpdated: _parseDateTime(data['lastUpdated']),
          createdBy: data['createdBy'] ?? '',
        );
      }).toList();
      
      // Sort by createdAt descending trong code
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  /// Xóa lịch sử giao dịch
  static Future<bool> deleteTransactionHistory(String transactionId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .where('id', isEqualTo: transactionId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      return true;
    } catch (e) {
      print('Error deleting transaction history: $e');
      return false;
    }
  }

  /// Parse TransactionType từ string
  static transaction.TransactionType _parseTransactionType(String? typeString) {
    switch (typeString) {
      case 'TransactionType.import':
        return transaction.TransactionType.import;
      case 'TransactionType.export':
        return transaction.TransactionType.export;
      default:
        return transaction.TransactionType.import;
    }
  }

  /// Parse TransactionStatus từ string
  static transaction.TransactionStatus _parseTransactionStatus(String? statusString) {
    switch (statusString) {
      case 'TransactionStatus.completed':
        return transaction.TransactionStatus.completed;
      case 'TransactionStatus.pending':
        return transaction.TransactionStatus.pending;
      case 'TransactionStatus.cancelled':
        return transaction.TransactionStatus.cancelled;
      default:
        return transaction.TransactionStatus.completed;
    }
  }

  /// Parse DateTime từ Firestore data
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    
    return DateTime.now();
  }
}
