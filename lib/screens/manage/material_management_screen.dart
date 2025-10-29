import 'package:flutter/material.dart';
import '../../models/construction_material.dart';
import '../../services/manage/material_service.dart';
import '../../services/user/user_session.dart';
import '../../components/material_card.dart';
import '../../components/statistics/stock_chart_widget.dart';
import '../../components/statistics/stock_ratio_chart_widget.dart';
import '../../components/statistics/category_chart_widget.dart';
import '../../components/statistics/value_trend_widget.dart';
import '../../components/statistics/transaction_chart_widget.dart';
import '../../components/reports/inventory_report_widget.dart';
import '../../components/reports/value_analysis_widget.dart';
import '../../components/filters/date_range_filter.dart';
import 'add_edit_material_screen.dart';
import 'material_detail_screen.dart';
import 'import_material_screen.dart';
import 'export_material_screen.dart';
import 'transaction_history_screen.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({super.key});

  @override
  State<MaterialManagementScreen> createState() => _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen>
    with TickerProviderStateMixin {
  List<ConstructionMaterial> _materials = const [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedCategory = 'Tất cả';
  late TabController _tabController;
  String? _currentUserId; // Thêm biến để lưu userId hiện tại
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _categories = [
    'Tất cả',
    'Vật liệu kết dính',
    'Vật liệu cốt liệu',
    'Vật liệu xây',
    'Vật liệu cốt thép',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUserAndLoad();
  }

  Future<void> _initializeUserAndLoad() async {
    // Lấy userId hiện tại từ session
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser != null) {
      _currentUserId = currentUser['userId']?.toString();
      if (_currentUserId != null) {
        _load();
        // listen realtime cho user hiện tại
        MaterialService.listenByUserId(_currentUserId!).listen((items) {
          if (!mounted) return;
          setState(() {
            _materials = items;
            _loading = false;
          });
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
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
        title: const Text(
          'Quản lý vật liệu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToTransactionHistory(),
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử giao dịch',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = null;
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Đặt lại',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Danh sách', icon: Icon(Icons.list)),
            Tab(text: 'Thống kê', icon: Icon(Icons.analytics)),
            Tab(text: 'Báo cáo', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaterialListTab(),
          _buildStatisticsTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMaterialActions,
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thao tác',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMaterialListTab() {
    final filteredMaterials = _getFilteredMaterials();

    return Column(
      children: [
        _buildSearchAndFilter(),
        _buildSummaryCards(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filteredMaterials.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                  itemCount: filteredMaterials.length,
                  itemBuilder: (context, index) {
                    final material = filteredMaterials[index];
                    return MaterialCard(
                      material: material,
                      onTap: () => _navigateToDetail(material),
                      onEdit: () => _navigateToEditMaterial(material),
                      onDelete: () => _showDeleteDialog(material),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _load() async {
    if (_currentUserId == null) return;
    
    setState(() => _loading = true);
    final list = await MaterialService.getByUserId(_currentUserId!);
    if (!mounted) return;
    setState(() {
      _materials = list;
      _loading = false;
    });
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm vật liệu...',
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
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[700],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalMaterials = _materials.length;
    final lowStockCount = _materials.where((m) => m.stockStatus == StockStatus.low).length;
    final totalValue = _materials.fold(0.0, (sum, m) => sum + m.totalValue);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Tổng vật liệu',
              '$totalMaterials',
              Icons.inventory,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Thiếu hàng',
              '$lowStockCount',
              Icons.warning,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Tổng giá trị',
              '${_formatPrice(totalValue)}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy vật liệu nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi từ khóa tìm kiếm hoặc thêm vật liệu mới',
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

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateRangeFilter(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: (start, end) {
              setState(() {
                _startDate = start;
                _endDate = end;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Thống kê tồn kho',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StockChartWidget(materials: _materials),
          const SizedBox(height: 16),
          // Biểu đồ tỉ lệ đảm bảo tồn kho (độc lập đơn vị)
          StockRatioChartWidget(materials: _materials),
          const SizedBox(height: 24),
          const Text(
            'Phân bố theo loại',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CategoryChartWidget(materials: _materials),
          const SizedBox(height: 24),
          const Text(
            'Xu hướng giá trị',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ValueTrendWidget(materials: _materials),
          const SizedBox(height: 24),
          const Text(
            'Thống kê giao dịch',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_currentUserId != null)
            TransactionChartWidget(
              userId: _currentUserId!,
              startDate: _startDate,
              endDate: _endDate,
            ),
        ],
      ),
    );
  }


  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateRangeFilter(
            startDate: _startDate,
            endDate: _endDate,
            onDateRangeChanged: (start, end) {
              setState(() {
                _startDate = start;
                _endDate = end;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Báo cáo tồn kho',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          InventoryReportWidget(materials: _materials),
          const SizedBox(height: 24),
          const Text(
            'Phân tích giá trị',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ValueAnalysisWidget(materials: _materials),
        ],
      ),
    );
  }

  List<ConstructionMaterial> _getFilteredMaterials() {
    var filtered = _materials;

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'Tất cả') {
      filtered = filtered.where((m) => m.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) =>
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.supplier.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
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

  void _navigateToAddMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditMaterialScreen(),
      ),
    );
  }

  void _navigateToImportMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImportMaterialScreen(),
      ),
    ).then((refresh) {
      if (refresh == true) {
        _load(); // Reload materials after import
        // Force refresh the materials list
        _load();
      }
    });
  }

  void _navigateToExportMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExportMaterialScreen(),
      ),
    ).then((refresh) {
      if (refresh == true) {
        _load(); // Reload materials after export
        // Force refresh the materials list
        _load();
      }
    });
  }

  void _showMaterialActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text('Thêm vật liệu'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddMaterial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.green),
                title: const Text('Nhập kho'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToImportMaterial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                title: const Text('Xuất kho'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToExportMaterial();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _navigateToTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
    );
  }

  void _navigateToEditMaterial(ConstructionMaterial material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMaterialScreen(material: material),
      ),
    );
  }

  void _navigateToDetail(ConstructionMaterial material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialDetailScreen(material: material),
      ),
    );
  }

  void _showDeleteDialog(ConstructionMaterial material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vật liệu'),
        content: Text('Bạn có chắc chắn muốn xóa "${material.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await MaterialService.delete(material.id);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Đã xóa "${material.name}"' : 'Xóa thất bại'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
