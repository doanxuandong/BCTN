import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class CategoryChartWidget extends StatelessWidget {
  final List<ConstructionMaterial> materials;

  const CategoryChartWidget({
    super.key,
    required this.materials,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return _buildEmptyState();
    }

    final categoryData = _getCategoryData();

    return Container(
      height: 250,
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
            'Phân bố theo loại vật liệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPieChart(categoryData),
          ),
          const SizedBox(height: 16),
          _buildLegend(categoryData),
        ],
      ),
    );
  }

  Map<String, CategoryData> _getCategoryData() {
    final Map<String, CategoryData> data = {};
    
    for (final material in materials) {
      if (data.containsKey(material.category)) {
        data[material.category]!.count++;
        data[material.category]!.totalValue += material.totalValue;
        data[material.category]!.totalStock += material.currentStock;
      } else {
        data[material.category] = CategoryData(
          category: material.category,
          count: 1,
          totalValue: material.totalValue,
          totalStock: material.currentStock,
        );
      }
    }
    
    return data;
  }

  Widget _buildPieChart(Map<String, CategoryData> data) {
    final totalValue = data.values.fold(0.0, (sum, item) => sum + item.totalValue);
    if (totalValue == 0) return _buildEmptyState();

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];


    return CustomPaint(
      painter: PieChartPainter(
        data: data.values.toList(),
        totalValue: totalValue,
        colors: colors,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${data.length}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Text(
              'Loại vật liệu',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, CategoryData> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: data.entries.map((entry) {
          final index = data.keys.toList().indexOf(entry.key);
          final color = colors[index % colors.length];
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.value.category} (${entry.value.count})',
                style: const TextStyle(fontSize: 9),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Không có dữ liệu để hiển thị',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class CategoryData {
  final String category;
  int count;
  double totalValue;
  double totalStock;

  CategoryData({
    required this.category,
    required this.count,
    required this.totalValue,
    required this.totalStock,
  });
}

class PieChartPainter extends CustomPainter {
  final List<CategoryData> data;
  final double totalValue;
  final List<Color> colors;

  PieChartPainter({
    required this.data,
    required this.totalValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;
    
    double startAngle = -90 * (3.14159 / 180); // Start from top
    
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].totalValue / totalValue) * 2 * 3.14159;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
