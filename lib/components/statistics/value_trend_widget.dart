import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class ValueTrendWidget extends StatelessWidget {
  final List<ConstructionMaterial> materials;

  const ValueTrendWidget({
    super.key,
    required this.materials,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return _buildEmptyState();
    }

    final trendData = _getTrendData();

    return Container(
      height: 180,
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
            'Xu hướng giá trị tồn kho',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildLineChart(trendData),
          ),
        ],
      ),
    );
  }

  List<TrendPoint> _getTrendData() {
    // Tạo dữ liệu giả lập cho 7 ngày gần đây
    final now = DateTime.now();
    final List<TrendPoint> data = [];
    
    double baseValue = materials.fold(0.0, (sum, m) => sum + m.totalValue);
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Tạo biến động ngẫu nhiên nhỏ
      final variation = (baseValue * 0.1 * (0.5 - (i % 3) * 0.2));
      final value = baseValue + variation;
      
      data.add(TrendPoint(
        date: date,
        value: value,
      ));
    }
    
    return data;
  }

  Widget _buildLineChart(List<TrendPoint> data) {
    final maxValue = data.fold(0.0, (max, point) => point.value > max ? point.value : max);
    final minValue = data.fold(double.infinity, (min, point) => point.value < min ? point.value : min);
    final range = maxValue - minValue;
    
    if (range == 0) return _buildEmptyState();

    return CustomPaint(
      painter: LineChartPainter(data: data, maxValue: maxValue, minValue: minValue),
      child: Container(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 48, color: Colors.grey),
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

class TrendPoint {
  final DateTime date;
  final double value;

  TrendPoint({
    required this.date,
    required this.value,
  });
}

class LineChartPainter extends CustomPainter {
  final List<TrendPoint> data;
  final double maxValue;
  final double minValue;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final range = maxValue - minValue;
    if (range == 0) return;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].value - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Vẽ điểm
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    // Hoàn thành fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Vẽ fill
    canvas.drawPath(fillPath, fillPaint);
    
    // Vẽ line
    canvas.drawPath(path, paint);

    // Vẽ grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
