import 'package:flutter/material.dart';
import '../../models/material_transaction.dart';
import '../../services/manage/transaction_history_service.dart';
import '../../services/user/user_session.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  List<MaterialTransaction> _transactions = [];
  bool _loading = true;
  String? _currentUserId;
  late TabController _tabController;
  String _searchQuery = '';
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeUserAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserAndLoad() async {
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser != null) {
      _currentUserId = currentUser['userId']?.toString();
      if (_currentUserId != null) {
        _loadTransactions();
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (_currentUserId == null) return;
    
    setState(() => _loading = true);
    
    try {
      print('Loading transaction history for user: $_currentUserId');
      final transactions = await TransactionHistoryService.getTransactionHistoryByUserId(_currentUserId!);
      print('Loaded ${transactions.length} transaction history records');
      for (var transaction in transactions) {
        print('Transaction: ${transaction.typeDisplayName} - ${transaction.quantity} - ${transaction.totalAmount}');
      }
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      print('Error loading transaction history: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tất cả', icon: Icon(Icons.list)),
            Tab(text: 'Nhập', icon: Icon(Icons.add_circle)),
            Tab(text: 'Xuất', icon: Icon(Icons.remove_circle)),
            Tab(text: 'Khác', icon: Icon(Icons.tune)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(_getFilteredTransactions()),
                _buildTransactionList(_getFilteredTransactions(TransactionType.import)),
                _buildTransactionList(_getFilteredTransactions(TransactionType.export)),
                _buildTransactionList(_getFilteredTransactions(null, true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm giao dịch...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', null),
                const SizedBox(width: 8),
                _buildFilterChip('Nhập kho', TransactionType.import),
                const SizedBox(width: 8),
                _buildFilterChip('Xuất kho', TransactionType.export),
                const SizedBox(width: 8),
                _buildFilterChip('Điều chỉnh', TransactionType.adjust),
                const SizedBox(width: 8),
                _buildFilterChip('Chuyển kho', TransactionType.transfer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildTransactionList(List<MaterialTransaction> transactions) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(MaterialTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction.typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction.type),
                    color: transaction.typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.typeDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(transaction.transactionDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: transaction.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    transaction.statusDisplayName,
                    style: TextStyle(
                      color: transaction.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Số lượng',
                    '${transaction.quantity.toInt()}',
                    Icons.scale,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Đơn giá',
                    _formatPrice(transaction.unitPrice),
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tổng tiền',
                    _formatPrice(transaction.totalAmount),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            if (transaction.supplier.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                transaction.isImport ? 'Nhà cung cấp' : 'Người nhận',
                transaction.supplier,
                transaction.isImport ? Icons.business : Icons.person,
              ),
            ],
            if (transaction.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                'Lý do',
                transaction.reason,
                Icons.info,
              ),
            ],
            if (transaction.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                'Ghi chú',
                transaction.note,
                Icons.note,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có giao dịch nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các giao dịch nhập/xuất hàng sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<MaterialTransaction> _getFilteredTransactions([TransactionType? type, bool excludeImportExport = false]) {
    var filtered = _transactions;

    // Filter by type
    if (type != null) {
      filtered = filtered.where((t) => t.type == type).toList();
    } else if (excludeImportExport) {
      filtered = filtered.where((t) => !t.isImport && !t.isExport).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
          t.supplier.toLowerCase().contains(query) ||
          t.reason.toLowerCase().contains(query) ||
          t.note.toLowerCase().contains(query) ||
          t.typeDisplayName.toLowerCase().contains(query)
      ).toList();
    }

    // Filter by selected type
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    return filtered;
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.import:
        return Icons.add_circle;
      case TransactionType.export:
        return Icons.remove_circle;
      case TransactionType.adjust:
        return Icons.tune;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
