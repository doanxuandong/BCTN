import 'package:flutter/material.dart';
import '../../models/construction_material.dart';
import '../../components/material_card.dart';
import 'add_edit_material_screen.dart';
import 'material_detail_screen.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({super.key});

  @override
  State<MaterialManagementScreen> createState() => _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen>
    with TickerProviderStateMixin {
  List<ConstructionMaterial> _materials = SampleData.materials;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  late TabController _tabController;

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
        onPressed: () => _navigateToAddMaterial(),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm vật liệu',
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
          child: filteredMaterials.isEmpty
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
          const Text(
            'Thống kê tồn kho',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStockChart(),
          const SizedBox(height: 24),
          const Text(
            'Phân bố theo loại',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryChart(),
        ],
      ),
    );
  }

  Widget _buildStockChart() {
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
        child: Text(
          'Biểu đồ tồn kho\n(Chức năng đang phát triển)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
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
        child: Text(
          'Biểu đồ phân loại\n(Chức năng đang phát triển)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text(
        'Trang báo cáo\n(Đang phát triển)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  List<ConstructionMaterial> _getFilteredMaterials() {
    var filtered = _materials;

    // Filter by category
    if (_selectedCategory != 'Tất cả') {
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
            onPressed: () {
              setState(() {
                _materials.removeWhere((m) => m.id == material.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa "${material.name}"'),
                  backgroundColor: Colors.green,
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
