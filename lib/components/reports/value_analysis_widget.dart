import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class ValueAnalysisWidget extends StatelessWidget {
  final List<ConstructionMaterial> materials;

  const ValueAnalysisWidget({
    super.key,
    required this.materials,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return _buildEmptyState();
    }

    final analysis = _performValueAnalysis();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích giá trị',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildValueBreakdown(analysis),
          const SizedBox(height: 16),
          _buildTopMaterials(analysis),
          const SizedBox(height: 16),
          _buildRecommendations(analysis),
        ],
      ),
    );
  }

  Widget _buildValueBreakdown(ValueAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân bố giá trị',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                'Tổng giá trị',
                _formatPrice(analysis.totalValue),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueCard(
                'Giá trị TB/vật liệu',
                _formatPrice(analysis.averageValue),
                Icons.analytics,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                'Vật liệu đắt nhất',
                _formatPrice(analysis.highestValue),
                Icons.trending_up,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueCard(
                'Vật liệu rẻ nhất',
                _formatPrice(analysis.lowestValue),
                Icons.trending_down,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopMaterials(ValueAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 vật liệu có giá trị cao nhất',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analysis.topMaterials.map((material) => _buildMaterialItem(material)),
      ],
    );
  }

  Widget _buildMaterialItem(TopMaterial material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inventory, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  material.category,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(material.value),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '${material.stock.toInt()} ${material.unit}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ValueAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khuyến nghị',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analysis.recommendations.map((rec) => _buildRecommendationItem(rec)),
      ],
    );
  }

  Widget _buildRecommendationItem(Recommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rec.type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rec.type.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(rec.type.icon, color: rec.type.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rec.message,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Không có dữ liệu để phân tích',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  ValueAnalysis _performValueAnalysis() {
    final totalValue = materials.fold(0.0, (sum, m) => sum + m.totalValue);
    final averageValue = materials.isNotEmpty ? totalValue / materials.length : 0.0;
    
    final sortedMaterials = List<ConstructionMaterial>.from(materials)
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
    
    final highestValue = sortedMaterials.isNotEmpty ? sortedMaterials.first.totalValue : 0.0;
    final lowestValue = sortedMaterials.isNotEmpty ? sortedMaterials.last.totalValue : 0.0;
    
    final topMaterials = sortedMaterials.take(5).map((m) => TopMaterial(
      name: m.name,
      category: m.category,
      value: m.totalValue,
      stock: m.currentStock,
      unit: m.unit,
    )).toList();
    
    final recommendations = _generateRecommendations(totalValue, averageValue, materials);
    
    return ValueAnalysis(
      totalValue: totalValue,
      averageValue: averageValue,
      highestValue: highestValue,
      lowestValue: lowestValue,
      topMaterials: topMaterials,
      recommendations: recommendations,
    );
  }

  List<Recommendation> _generateRecommendations(double totalValue, double averageValue, List<ConstructionMaterial> materials) {
    final recommendations = <Recommendation>[];
    
    // Kiểm tra tồn kho thấp
    final lowStockCount = materials.where((m) => m.stockStatus == StockStatus.low).length;
    if (lowStockCount > 0) {
      recommendations.add(Recommendation(
        message: 'Có $lowStockCount vật liệu đang thiếu hàng. Cần nhập thêm ngay.',
        type: RecommendationType.warning,
      ));
    }
    
    // Kiểm tra tồn kho cao
    final highStockCount = materials.where((m) => m.stockStatus == StockStatus.high).length;
    if (highStockCount > 0) {
      recommendations.add(Recommendation(
        message: 'Có $highStockCount vật liệu tồn kho cao. Cân nhắc giảm nhập hàng.',
        type: RecommendationType.info,
      ));
    }
    
    // Kiểm tra giá trị tổng
    if (totalValue > 100000000) { // > 100 triệu
      recommendations.add(Recommendation(
        message: 'Tổng giá trị tồn kho cao. Cần quản lý chặt chẽ.',
        type: RecommendationType.success,
      ));
    }
    
    // Kiểm tra đa dạng vật liệu
    final categories = materials.map((m) => m.category).toSet().length;
    if (categories < 3) {
      recommendations.add(Recommendation(
        message: 'Cần đa dạng hóa các loại vật liệu để tối ưu hóa.',
        type: RecommendationType.info,
      ));
    }
    
    return recommendations;
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)}B VNĐ';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M VNĐ';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K VNĐ';
    } else {
      return '${price.toStringAsFixed(0)} VNĐ';
    }
  }
}

class ValueAnalysis {
  final double totalValue;
  final double averageValue;
  final double highestValue;
  final double lowestValue;
  final List<TopMaterial> topMaterials;
  final List<Recommendation> recommendations;

  ValueAnalysis({
    required this.totalValue,
    required this.averageValue,
    required this.highestValue,
    required this.lowestValue,
    required this.topMaterials,
    required this.recommendations,
  });
}

class TopMaterial {
  final String name;
  final String category;
  final double value;
  final double stock;
  final String unit;

  TopMaterial({
    required this.name,
    required this.category,
    required this.value,
    required this.stock,
    required this.unit,
  });
}

class Recommendation {
  final String message;
  final RecommendationType type;

  Recommendation({
    required this.message,
    required this.type,
  });
}

enum RecommendationType {
  info(Icons.info, Colors.blue),
  warning(Icons.warning, Colors.orange),
  success(Icons.check_circle, Colors.green),
  error(Icons.error, Colors.red);

  const RecommendationType(this.icon, this.color);
  final IconData icon;
  final Color color;
}
