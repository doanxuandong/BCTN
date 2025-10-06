import 'package:flutter/material.dart';
import '../../services/manage/transaction_service.dart';

class TransactionChartWidget extends StatefulWidget {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionChartWidget({
    super.key,
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  State<TransactionChartWidget> createState() => _TransactionChartWidgetState();
}

class _TransactionChartWidgetState extends State<TransactionChartWidget> {
  TransactionStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(TransactionChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    
    try {
      final stats = await TransactionService.getTransactionStats(
        widget.userId,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null || _stats!.totalTransactions == 0) {
      return _buildEmptyState();
    }

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
            'Thống kê giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildTransactionChart(),
          const SizedBox(height: 16),
          _buildTypeDistribution(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Tổng giao dịch',
            '${_stats!.totalTransactions}',
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Nhập hàng',
            '${_stats!.importCount}',
            Icons.add_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Xuất hàng',
            '${_stats!.exportCount}',
            Icons.remove_circle,
            Colors.red,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
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

  Widget _buildTransactionChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giá trị giao dịch',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildValueBar(
                'Nhập',
                _stats!.totalImportValue,
                _stats!.totalImportValue + _stats!.totalExportValue,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildValueBar(
                'Xuất',
                _stats!.totalExportValue,
                _stats!.totalImportValue + _stats!.totalExportValue,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nhập: ${_formatPrice(_stats!.totalImportValue)}',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
            Text(
              'Xuất: ${_formatPrice(_stats!.totalExportValue)}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueBar(String label, double value, double maxValue, Color color) {
    final ratio = maxValue > 0 ? value / maxValue : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatPrice(value),
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân bố loại giao dịch',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeItem(
                'Nhập',
                _stats!.importCount,
                _stats!.totalTransactions,
                Colors.green,
                Icons.add_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeItem(
                'Xuất',
                _stats!.exportCount,
                _stats!.totalTransactions,
                Colors.red,
                Icons.remove_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeItem(
                'Điều chỉnh',
                _stats!.adjustCount,
                _stats!.totalTransactions,
                Colors.orange,
                Icons.tune,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeItem(
                'Chuyển kho',
                _stats!.transferCount,
                _stats!.totalTransactions,
                Colors.purple,
                Icons.swap_horiz,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeItem(String label, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
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
}
