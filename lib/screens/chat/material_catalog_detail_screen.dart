import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/construction_material.dart';
import '../../services/manage/material_service.dart';

class MaterialCatalogDetailScreen extends StatelessWidget {
  final Message message;

  const MaterialCatalogDetailScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final businessData = message.businessData ?? {};
    final materialIds = (businessData['materialIds'] as List?)?.cast<String>() ?? [];
    final category = businessData['category'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog vật liệu'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ConstructionMaterial>>(
        future: _loadMaterials(materialIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          final materials = snapshot.data ?? [];

          if (materials.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không tìm thấy vật liệu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (category != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange[50],
                  child: Text(
                    'Danh mục: $category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Icon(Icons.inventory, color: Colors.orange[700]),
                        ),
                        title: Text(
                          material.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Danh mục: ${material.category}'),
                            Text('Tồn kho: ${material.currentStock} ${material.unit}'),
                            Text('Giá: ${material.price.toStringAsFixed(0)} VNĐ/${material.unit}'),
                            if (material.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  material.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                        onTap: () {
                          // TODO: Navigate to material detail screen
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<ConstructionMaterial>> _loadMaterials(List<String> materialIds) async {
    final materials = <ConstructionMaterial>[];
    for (var materialId in materialIds) {
      final material = await MaterialService.getById(materialId);
      if (material != null) {
        materials.add(material);
      }
    }
    return materials;
  }
}

