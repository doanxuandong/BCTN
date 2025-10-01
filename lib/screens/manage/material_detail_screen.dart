import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class MaterialDetailScreen extends StatefulWidget {
  final ConstructionMaterial material;

  const MaterialDetailScreen({super.key, required this.material});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.material.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Edit functionality
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              // More options
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Thông tin', icon: Icon(Icons.info)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
            Tab(text: 'Thống kê', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildHistoryTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTransactionDialog();
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Giao dịch',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMaterialImage(),
          const SizedBox(height: 24),
          _buildBasicInfo(),
          const SizedBox(height: 16),
          _buildStockInfo(),
          const SizedBox(height: 16),
          _buildSupplierInfo(),
          const SizedBox(height: 16),
          _buildDescriptionInfo(),
        ],
      ),
    );
  }

  Widget _buildMaterialImage() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: widget.material.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.material.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultIcon();
                  },
                ),
              )
            : _buildDefaultIcon(),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (widget.material.category) {
      case 'Vật liệu kết dính':
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'Vật liệu cốt liệu':
        iconData = Icons.landscape;
        iconColor = Colors.brown;
        break;
      case 'Vật liệu xây':
        iconData = Icons.crop_square;
        iconColor = Colors.red;
        break;
      case 'Vật liệu cốt thép':
        iconData = Icons.straighten;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.construction;
        iconColor = Colors.orange;
    }

    return Icon(iconData, color: iconColor, size: 80);
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tên vật liệu', widget.material.name),
            _buildInfoRow('Loại', widget.material.category),
            _buildInfoRow('Đơn vị', widget.material.unit),
            _buildInfoRow('Giá', '${_formatPrice(widget.material.price)} VNĐ/${widget.material.unit}'),
            _buildInfoRow('Cập nhật lần cuối', _formatDate(widget.material.lastUpdated)),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin tồn kho',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStockCard(
                    'Tồn kho',
                    '${widget.material.currentStock} ${widget.material.unit}',
                    Colors.blue,
                    Icons.inventory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockCard(
                    'Tối thiểu',
                    '${widget.material.minStock} ${widget.material.unit}',
                    Colors.orange,
                    Icons.warning_amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStockCard(
                    'Tối đa',
                    '${widget.material.maxStock} ${widget.material.unit}',
                    Colors.green,
                    Icons.warehouse,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockCard(
                    'Giá trị',
                    '${_formatPrice(widget.material.totalValue)} VNĐ',
                    Colors.purple,
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStockStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard(String title, String value, Color color, IconData icon) {
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
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusIndicator() {
    Color color;
    String status;
    IconData icon;
    
    switch (widget.material.stockStatus) {
      case StockStatus.low:
        color = Colors.red;
        status = 'Tồn kho thấp';
        icon = Icons.trending_down;
        break;
      case StockStatus.high:
        color = Colors.orange;
        status = 'Tồn kho cao';
        icon = Icons.trending_up;
        break;
      case StockStatus.normal:
        color = Colors.green;
        status = 'Tồn kho bình thường';
        icon = Icons.trending_flat;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhà cung cấp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tên nhà cung cấp', widget.material.supplier),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mô tả',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.material.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final transactions = widget.material.transactions;
    
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có lịch sử giao dịch',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: transaction.type == TransactionType.import
                  ? Colors.green
                  : transaction.type == TransactionType.export
                      ? Colors.red
                      : Colors.orange,
              child: Icon(
                transaction.type == TransactionType.import
                    ? Icons.add
                    : transaction.type == TransactionType.export
                        ? Icons.remove
                        : Icons.edit,
                color: Colors.white,
              ),
            ),
            title: Text(
              transaction.type == TransactionType.import
                  ? 'Nhập kho'
                  : transaction.type == TransactionType.export
                      ? 'Xuất kho'
                      : 'Điều chỉnh',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số lượng: ${transaction.quantity} ${widget.material.unit}'),
                Text('Giá: ${_formatPrice(transaction.price)} VNĐ'),
                Text('Người thực hiện: ${transaction.operator}'),
                if (transaction.note.isNotEmpty) Text('Ghi chú: ${transaction.note}'),
              ],
            ),
            trailing: Text(
              _formatDate(transaction.date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Biểu đồ thống kê\n(Đang phát triển)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm giao dịch'),
        content: const Text('Chức năng thêm giao dịch đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)}B';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
