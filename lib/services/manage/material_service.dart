import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/construction_material.dart';
import '../storage/image_service.dart';
import 'dart:io';

class MaterialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'materials';

  static Future<List<ConstructionMaterial>> getAll({int limit = 100}) async {
    final snap = await _firestore.collection(_collection).limit(limit).get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  // Lấy tất cả vật liệu của một user cụ thể
  static Future<List<ConstructionMaterial>> getByUserId(String userId, {int limit = 100}) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  static Stream<List<ConstructionMaterial>> listenAll({int limit = 200}) {
    return _firestore.collection(_collection).limit(limit).snapshots().map(
          (s) => s.docs.map((d) => _fromDoc(d)).toList(),
        );
  }

  // Lắng nghe thay đổi vật liệu của một user cụ thể
  static Stream<List<ConstructionMaterial>> listenByUserId(String userId, {int limit = 200}) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => _fromDoc(d)).toList());
  }

  static Future<ConstructionMaterial?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  static Future<String?> create(ConstructionMaterial m) async {
    final data = _toMap(m);
    data.remove('id');
    final ref = await _firestore.collection(_collection).add(data);
    return ref.id;
  }

  static Future<bool> update(ConstructionMaterial m) async {
    try {
      await _firestore.collection(_collection).doc(m.id).update(_toMap(m));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> uploadImage(String userId, String path) async {
    return ImageService.uploadImage(imageFile: File(path), userId: userId, type: 'materials');
  }

  static ConstructionMaterial _fromDoc(DocumentSnapshot doc) {
    try {
      final d = doc.data() as Map<String, dynamic>;
      print('Parsing material: ${doc.id}');
      print('lastUpdated type: ${d['lastUpdated'].runtimeType}');
      print('lastUpdated value: ${d['lastUpdated']}');
      
      return ConstructionMaterial(
        id: doc.id,
        userId: d['userId'] ?? '', // Thêm userId từ Firestore
        name: d['name'] ?? '',
        category: d['category'] ?? '',
        unit: d['unit'] ?? '',
        currentStock: (d['currentStock'] ?? 0).toDouble(),
        minStock: (d['minStock'] ?? 0).toDouble(),
        maxStock: (d['maxStock'] ?? 0).toDouble(),
        price: (d['price'] ?? 0).toDouble(),
        supplier: d['supplier'] ?? '',
        description: d['description'] ?? '',
        imageUrl: d['imageUrl'],
        lastUpdated: d['lastUpdated'] != null
            ? _parseDateTime(d['lastUpdated'])
            : DateTime.now(),
        transactions: const [],
      );
    } catch (e) {
      print('Error parsing material ${doc.id}: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  static Map<String, dynamic> _toMap(ConstructionMaterial m) {
    return {
      'userId': m.userId, // Thêm userId vào map để lưu vào Firestore
      'name': m.name,
      'category': m.category,
      'unit': m.unit,
      'currentStock': m.currentStock,
      'minStock': m.minStock,
      'maxStock': m.maxStock,
      'price': m.price,
      'supplier': m.supplier,
      'description': m.description,
      'imageUrl': m.imageUrl,
      'lastUpdated': m.lastUpdated.millisecondsSinceEpoch,
    };
  }
}


