import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class InventoryReportWidget extends StatelessWidget {
  final List<ConstructionMaterial> materials;
  final DateTime? startDate;
  final DateTime? endDate;

  const InventoryReportWidget({
    super.key,
    required this.materials,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final reportData = _generateReportData();

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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSummaryCards(reportData),
          const SizedBox(height: 16),
          _buildDetailedTable(reportData),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Báo cáo tồn kho',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Ngày tạo: ${_formatDate(DateTime.now())}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ReportData data) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Tổng vật liệu',
            '${data.totalItems}',
            Icons.inventory,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Tổng giá trị',
            _formatPrice(data.totalValue),
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Thiếu hàng',
            '${data.lowStockItems}',
            Icons.warning,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Tồn kho cao',
            '${data.highStockItems}',
            Icons.warehouse,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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

  Widget _buildDetailedTable(ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết vật liệu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Tên vật liệu')),
                DataColumn(label: Text('Loại')),
                DataColumn(label: Text('Tồn kho')),
                DataColumn(label: Text('Giá')),
                DataColumn(label: Text('Giá trị')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: materials.map((material) {
                return DataRow(
                  cells: [
                    DataCell(Text(material.name)),
                    DataCell(Text(material.category)),
                    DataCell(Text('${material.currentStock.toInt()} ${material.unit}')),
                    DataCell(Text(_formatPrice(material.price))),
                    DataCell(Text(_formatPrice(material.totalValue))),
                    DataCell(_buildStatusChip(material.stockStatus)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(StockStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case StockStatus.low:
        color = Colors.red;
        text = 'Thiếu hàng';
        break;
      case StockStatus.normal:
        color = Colors.green;
        text = 'Bình thường';
        break;
      case StockStatus.high:
        color = Colors.orange;
        text = 'Tồn kho cao';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportToPDF(context),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Xuất PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportToExcel(context),
            icon: const Icon(Icons.table_chart),
            label: const Text('Xuất Excel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareReport(context),
            icon: const Icon(Icons.share),
            label: const Text('Chia sẻ'),
          ),
        ),
      ],
    );
  }

  ReportData _generateReportData() {
    final totalItems = materials.length;
    final totalValue = materials.fold(0.0, (sum, m) => sum + m.totalValue);
    final lowStockItems = materials.where((m) => m.stockStatus == StockStatus.low).length;
    final highStockItems = materials.where((m) => m.stockStatus == StockStatus.high).length;

    return ReportData(
      totalItems: totalItems,
      totalValue: totalValue,
      lowStockItems: lowStockItems,
      highStockItems: highStockItems,
    );
  }

  void _exportToPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng xuất PDF đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportToExcel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng xuất Excel đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng chia sẻ đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ReportData {
  final int totalItems;
  final double totalValue;
  final int lowStockItems;
  final int highStockItems;

  ReportData({
    required this.totalItems,
    required this.totalValue,
    required this.lowStockItems,
    required this.highStockItems,
  });
}
