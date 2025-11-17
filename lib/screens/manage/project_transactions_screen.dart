import 'package:flutter/material.dart';
import '../../models/material_transaction.dart';
import '../../models/project_pipeline.dart';
import '../../services/manage/transaction_service.dart';
import '../../services/user/user_session.dart';

class ProjectTransactionsScreen extends StatefulWidget {
  final ProjectPipeline project;

  const ProjectTransactionsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectTransactionsScreen> createState() => _ProjectTransactionsScreenState();
}

class _ProjectTransactionsScreenState extends State<ProjectTransactionsScreen> {
  List<MaterialTransaction> _transactions = [];
  bool _loading = true;
  String? _currentUserId;
  String _searchQuery = '';
  TransactionType? _selectedType;
  // Phase 6 Enhancement: Project cost tracking
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserIdAndTransactions();
  }

  Future<void> _loadCurrentUserIdAndTransactions() async {
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser == null) return;
    
    final userId = currentUser['userId']?.toString();
    if (userId == null) return;
    
    setState(() {
      _currentUserId = userId;
    });
    
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (_currentUserId == null) return;
    
    setState(() => _loading = true);
    
    try {
      // Phase 4 Enhancement: Load transactions for user (contractor/owner can view)
      final transactions = await TransactionService.getProjectTransactionsForUser(
        widget.project.id,
        _currentUserId!,
      );
      
      // Phase 6 Enhancement: Calculate total cost
      double totalCost = 0;
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.export &&
            transaction.status == TransactionStatus.completed) {
          totalCost += transaction.totalAmount;
        }
      }
      
      setState(() {
        _transactions = transactions;
        _totalCost = totalCost;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading project transactions: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giao dịch vật liệu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              widget.project.projectName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Phase 6 Enhancement: Budget warning banner
          _buildBudgetWarningBanner(),
          _buildSearchAndFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Phase 6 Enhancement: Build budget warning banner
  Widget _buildBudgetWarningBanner() {
    // Chỉ hiển thị cảnh báo nếu có materialsBudget
    if (widget.project.materialsBudget == null || widget.project.materialsBudget! <= 0) {
      return const SizedBox.shrink();
    }

    final budget = widget.project.materialsBudget!;
    final percentage = budget > 0 ? (_totalCost / budget) * 100 : 0;
    final isOverBudget = _totalCost > budget;

    // Chỉ hiển thị cảnh báo nếu vượt quá 80% ngân sách hoặc vượt quá ngân sách
    if (percentage < 80 && !isOverBudget) {
      return const SizedBox.shrink();
    }

    Color warningColor;
    IconData warningIcon;
    String warningText;

    if (isOverBudget) {
      warningColor = Colors.red;
      warningIcon = Icons.warning;
      warningText = '⚠️ VƯỢT QUÁ NGÂN SÁCH!';
    } else if (percentage >= 90) {
      warningColor = Colors.orange;
      warningIcon = Icons.warning_amber;
      warningText = '⚠️ GẦN VƯỢT NGÂN SÁCH';
    } else {
      warningColor = Colors.orange[700]!;
      warningIcon = Icons.info_outline;
      warningText = 'ℹ️ Đã sử dụng ${percentage.toStringAsFixed(1)}% ngân sách';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: warningColor, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(warningIcon, color: warningColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warningText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: warningColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã chi: ${_formatPrice(_totalCost)} / Ngân sách: ${_formatPrice(budget)}',
                  style: TextStyle(
                    color: warningColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                if (isOverBudget)
                  Text(
                    'Vượt quá: ${_formatPrice(_totalCost - budget)}',
                    style: TextStyle(
                      color: warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  Widget _buildTransactionCard(MaterialTransaction transaction) {
    final filteredTransactions = _getFilteredTransactions();
    if (!filteredTransactions.contains(transaction)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
            // Phase 4 Enhancement: Hiển thị "từ ai sang ai"
            if (transaction.fromUserId != null && transaction.toUserId != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${transaction.fromUserName ?? "N/A"} → ${transaction.toUserName ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
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
            if (transaction.materialName.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                'Vật liệu',
                transaction.materialName,
                Icons.inventory,
              ),
            ],
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
            'Các giao dịch vật liệu của dự án này sẽ hiển thị ở đây',
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

  List<MaterialTransaction> _getFilteredTransactions() {
    var filtered = _transactions;

    // Filter by selected type
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
          t.materialName.toLowerCase().contains(query) ||
          (t.fromUserName?.toLowerCase().contains(query) ?? false) ||
          (t.toUserName?.toLowerCase().contains(query) ?? false) ||
          t.supplier.toLowerCase().contains(query) ||
          t.reason.toLowerCase().contains(query) ||
          t.note.toLowerCase().contains(query) ||
          t.typeDisplayName.toLowerCase().contains(query)
      ).toList();
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

