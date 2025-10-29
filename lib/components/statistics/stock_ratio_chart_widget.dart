import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class StockRatioChartWidget extends StatelessWidget {
  final List<ConstructionMaterial> materials;

  const StockRatioChartWidget({
    super.key,
    required this.materials,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tính tỉ lệ đảm bảo: current / minStock (%). Nếu min = 0, dùng current / max.
    final items = materials
        .map((m) {
          final minBase = m.minStock > 0 ? m.minStock : (m.maxStock > 0 ? m.maxStock : 1);
          final ratio = (m.currentStock / minBase) * 100.0;
          return _RatioItem(name: m.name, ratio: ratio.clamp(0, 200));
        })
        .toList()
      ..sort((a, b) => a.ratio.compareTo(b.ratio));

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
            'Tỉ lệ đảm bảo tồn kho',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 8),
          ...items.take(8).map((e) => _buildBar(e)).toList(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String text) => Row(
          children: [
            Container(width: 12, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );

    return Row(
      children: [
        item(Colors.red, '< 100% Thiếu'),
        const SizedBox(width: 12),
        item(Colors.orange, '100-120% Vừa đủ'),
        const SizedBox(width: 12),
        item(Colors.green, '> 120% Dư'),
      ],
    );
  }

  Widget _buildBar(_RatioItem item) {
    final percent = (item.ratio / 200).clamp(0.0, 1.0); // tối đa 200%
    final color = item.ratio < 100
        ? Colors.red
        : (item.ratio <= 120 ? Colors.orange : Colors.green);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 12,
                            width: constraints.maxWidth,
                            color: Colors.grey.withOpacity(0.15),
                          ),
                          Container(
                            height: 12,
                            width: constraints.maxWidth * percent,
                            color: color,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '${item.ratio.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}

class _RatioItem {
  final String name;
  final double ratio;
  _RatioItem({required this.name, required this.ratio});
}



