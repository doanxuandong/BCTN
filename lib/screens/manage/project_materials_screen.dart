import 'package:flutter/material.dart';
import '../../models/project_pipeline.dart';
import '../../services/manage/transaction_service.dart';
import '../../services/manage/material_service.dart';
import '../../models/material_transaction.dart' as mt;

class ProjectMaterialsScreen extends StatefulWidget {
  final ProjectPipeline project;

  const ProjectMaterialsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectMaterialsScreen> createState() => _ProjectMaterialsScreenState();
}

class _ProjectMaterialsScreenState extends State<ProjectMaterialsScreen> {
  List<Map<String, dynamic>> _projectMaterials = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjectMaterials();
  }

  Future<void> _loadProjectMaterials() async {
    setState(() => _loading = true);
    
    try {
      // Lấy tất cả transactions export của project (vật liệu đã được chuyển cho owner/contractor)
      final transactions = await TransactionService.getTransactionsByProjectId(widget.project.id);
      
      // Convert ownerId và contractorId sang String để so sánh (vì toUserId là String?)
      final ownerIdStr = widget.project.ownerId.toString();
      final contractorIdStr = widget.project.contractorId?.toString() ?? '';
      
      print('🔍 Loading materials for project: ${widget.project.id}');
      print('  - ownerId: $ownerIdStr');
      print('  - contractorId: $contractorIdStr');
      print('  - Total transactions: ${transactions.length}');
      
      // Phân loại transactions export thành 2 nhóm:
      // 1. Transactions NHẬN VẬT LIỆU vào dự án (từ store/owner → contractor/owner)
      // 2. Transactions BÁO CÁO SỬ DỤNG (contractor báo đã dùng) - cần TRỪ đi
      final allExportTransactions = transactions.where((t) {
        final isExport = t.type == mt.TransactionType.export;
        final isCompleted = t.status == mt.TransactionStatus.completed;
        final toUserIdStr = t.toUserId?.toString() ?? '';
        final matchesOwner = toUserIdStr == ownerIdStr;
        final matchesContractor = contractorIdStr.isNotEmpty && toUserIdStr == contractorIdStr;
        final matches = matchesOwner || matchesContractor;
        
        return isExport && isCompleted && matches;
      }).toList();
      
      // Phân biệt transactions báo cáo sử dụng (có reason/note/description chứa "báo cáo")
      final usageReportTransactions = allExportTransactions.where((t) {
        final reason = (t.reason ?? '').toLowerCase();
        final note = (t.note ?? '').toLowerCase();
        final description = (t.description ?? '').toLowerCase();
        return reason.contains('báo cáo') || 
               note.contains('báo cáo sử dụng') || 
               description.contains('báo cáo sử dụng');
      }).toList();
      
      // Transactions nhận vật liệu = tất cả export - báo cáo sử dụng
      final receivedTransactions = allExportTransactions.where((t) {
        final reason = (t.reason ?? '').toLowerCase();
        final note = (t.note ?? '').toLowerCase();
        final description = (t.description ?? '').toLowerCase();
        return !(reason.contains('báo cáo') || 
                 note.contains('báo cáo sử dụng') || 
                 description.contains('báo cáo sử dụng'));
      }).toList();
      
      print('  - Total export transactions: ${allExportTransactions.length}');
      print('  - Received transactions (nhận vật liệu): ${receivedTransactions.length}');
      print('  - Usage report transactions (báo cáo sử dụng): ${usageReportTransactions.length}');
      
      // Tạo map để tổng hợp vật liệu
      // QUAN TRỌNG: Group theo materialName đã normalize để tránh trùng lặp
      // Tính số lượng CÒN LẠI = Tổng đã NHẬN - Tổng đã SỬ DỤNG
      final Map<String, Map<String, dynamic>> materialsMap = {};
      
      // Lấy danh sách tất cả materialNames unique từ cả 2 nhóm transactions
      final allMaterialNames = <String>{};
      for (var txn in allExportTransactions) {
        allMaterialNames.add(txn.materialName.trim().toLowerCase());
      }
      
      for (var normalizedName in allMaterialNames) {
        // Tổng số lượng ĐÃ NHẬN (từ receivedTransactions)
        final receivedSameName = receivedTransactions.where((t) => 
          t.materialName.trim().toLowerCase() == normalizedName
        ).toList();
        double totalReceived = receivedSameName.fold(0.0, (sum, t) => sum + t.quantity);
        
        // Tổng số lượng ĐÃ SỬ DỤNG (từ usageReportTransactions)
        final usedSameName = usageReportTransactions.where((t) => 
          t.materialName.trim().toLowerCase() == normalizedName
        ).toList();
        double totalUsed = usedSameName.fold(0.0, (sum, t) => sum + t.quantity);
        
        // Số lượng CÒN LẠI = Đã nhận - Đã sử dụng
        double remainingQuantity = totalReceived - totalUsed;
        
        // Chỉ hiển thị vật liệu có số lượng > 0 (còn lại trong dự án)
        if (remainingQuantity > 0) {
          // Lấy transaction đầu tiên để lấy thông tin chi tiết
          final firstTxn = receivedSameName.isNotEmpty 
              ? receivedSameName.first 
              : allExportTransactions.firstWhere(
                  (t) => t.materialName.trim().toLowerCase() == normalizedName,
                );
          
          // Lấy materialId và thông tin chi tiết từ material service
          // Ưu tiên lấy từ owner's materials để đảm bảo consistency
          String? materialId;
          String? materialUnit = 'cái';
          double? materialPrice = firstTxn.unitPrice;
          
          try {
            // Tìm material trong kho owner dựa trên materialName
            final ownerMaterials = await MaterialService.getByUserId(widget.project.ownerId);
            final ownerMaterial = ownerMaterials.firstWhere(
              (m) => m.name.trim().toLowerCase() == normalizedName,
              orElse: () => ownerMaterials.firstWhere(
                (m) => m.id == firstTxn.materialId,
                orElse: () => ownerMaterials.firstWhere(
                  (m) => m.name.toLowerCase().contains(normalizedName) || 
                         normalizedName.contains(m.name.toLowerCase()),
                  orElse: () => ownerMaterials.first,
                ),
              ),
            );
            
            if (ownerMaterial.id.isNotEmpty) {
              materialId = ownerMaterial.id;
              materialUnit = ownerMaterial.unit.isNotEmpty ? ownerMaterial.unit : 'cái';
              materialPrice = ownerMaterial.price;
            } else {
              // Fallback: dùng materialId từ transaction đầu tiên
              materialId = firstTxn.materialId;
              try {
                final material = await MaterialService.getById(firstTxn.materialId);
                if (material != null) {
                  materialUnit = material.unit.isNotEmpty ? material.unit : 'cái';
                  materialPrice = material.price;
                }
              } catch (e) {
                print('⚠️ Error getting material details: $e');
              }
            }
          } catch (e) {
            print('⚠️ Error getting owner material: $e');
            // Fallback: dùng materialId từ transaction đầu tiên
            materialId = firstTxn.materialId;
            try {
              final material = await MaterialService.getById(firstTxn.materialId);
              if (material != null) {
                materialUnit = material.unit.isNotEmpty ? material.unit : 'cái';
                materialPrice = material.price;
              }
            } catch (e2) {
              print('⚠️ Error getting material details: $e2');
            }
          }
          
          // Lấy materialName gốc từ transaction đầu tiên (giữ nguyên format)
          final originalMaterialName = firstTxn.materialName;
          
          materialsMap[normalizedName] = {
            'materialName': originalMaterialName,
            'materialId': materialId ?? firstTxn.materialId,
            'unit': materialUnit,
            'price': materialPrice ?? firstTxn.unitPrice,
            'totalQuantity': remainingQuantity, // Số lượng CÒN LẠI
            'ownerId': widget.project.ownerId,
          };
          
          print('  - Material: $originalMaterialName (normalized: $normalizedName)');
          print('    - Đã nhận: $totalReceived ${materialUnit}');
          print('    - Đã sử dụng: $totalUsed ${materialUnit}');
          print('    - Còn lại: $remainingQuantity ${materialUnit}');
        }
      }
      
      setState(() {
        _projectMaterials = materialsMap.values.toList();
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading project materials: $e');
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
              'Vật liệu trong dự án',
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
            onPressed: _loadProjectMaterials,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
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
          ),
          // Materials list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredMaterials().isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProjectMaterials,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _getFilteredMaterials().length,
                          itemBuilder: (context, index) {
                            final material = _getFilteredMaterials()[index];
                            return _buildMaterialCard(material);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredMaterials() {
    if (_searchQuery.isEmpty) {
      return _projectMaterials;
    }
    
    final query = _searchQuery.toLowerCase();
    return _projectMaterials.where((m) =>
      (m['materialName'] as String).toLowerCase().contains(query)
    ).toList();
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material['materialName'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số lượng: ${(material['totalQuantity'] as double).toStringAsFixed(2)} ${material['unit']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Text(
                    _formatPrice((material['price'] as double) * (material['totalQuantity'] as double)),
                    style: TextStyle(
                      color: Colors.green[900],
                      fontSize: 12,
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
                    'Đơn giá',
                    _formatPrice(material['price'] as double),
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Tổng giá trị',
                    _formatPrice((material['price'] as double) * (material['totalQuantity'] as double)),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
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
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có vật liệu nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các vật liệu trong dự án này sẽ hiển thị ở đây',
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

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(2)}B VNĐ';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M VNĐ';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(2)}K VNĐ';
    } else {
      return '${price.toStringAsFixed(0)} VNĐ';
    }
  }
}

