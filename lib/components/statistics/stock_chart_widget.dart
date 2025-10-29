import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class StockChartWidget extends StatelessWidget {
  final List<ConstructionMaterial> materials;

  const StockChartWidget({
    super.key,
    required this.materials,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return _buildEmptyState();
    }

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
            'Biểu đồ tồn kho',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxStock = materials.fold(0.0, (max, material) => 
        material.maxStock > max ? material.maxStock : max);
    
    if (maxStock == 0) return _buildEmptyState();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: materials.take(8).map((material) {
        final currentRatio = material.currentStock / maxStock;
        final maxRatio = material.maxStock / maxStock;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chart area with fixed height to avoid overflow
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Max stock bar (background)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 120 * maxRatio,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      // Current stock bar (foreground)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 120 * currentRatio,
                          decoration: BoxDecoration(
                            color: _getStockColor(material.stockStatus),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      // Min stock line (fixed at 4px height)
                      Positioned(
                        bottom: 120 * (material.minStock / maxStock) - 1,
                        left: 0,
                        right: 0,
                        child: Container(height: 2, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  material.name.length > 6 
                      ? '${material.name.substring(0, 6)}...' 
                      : material.name,
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${material.currentStock.toInt()}',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStockColor(StockStatus status) {
    switch (status) {
      case StockStatus.low:
        return Colors.red;
      case StockStatus.normal:
        return Colors.green;
      case StockStatus.high:
        return Colors.orange;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey),
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
