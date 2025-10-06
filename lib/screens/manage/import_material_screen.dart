import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/construction_material.dart';
import '../../models/material_transaction.dart' as transaction;
import '../../services/manage/material_service.dart';
import '../../services/manage/transaction_service.dart';
import '../../services/user/user_session.dart';

class ImportMaterialScreen extends StatefulWidget {
  final ConstructionMaterial? material;

  const ImportMaterialScreen({super.key, this.material});

  @override
  State<ImportMaterialScreen> createState() => _ImportMaterialScreenState();
}

class _ImportMaterialScreenState extends State<ImportMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _supplierController;
  late TextEditingController _reasonController;
  late TextEditingController _noteController;
  bool _isLoading = false;

  ConstructionMaterial? _selectedMaterial;
  List<ConstructionMaterial> _materials = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _supplierController = TextEditingController();
    _reasonController = TextEditingController(text: 'Nhập kho mới');
    _noteController = TextEditingController();
    
    if (widget.material != null) {
      _selectedMaterial = widget.material;
    }
    
    _loadMaterials();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser == null) return;
    
    final userId = currentUser['userId']?.toString();
    if (userId == null) return;
    
    setState(() => _loading = true);
    
    try {
      final materials = await MaterialService.getByUserId(userId);
      setState(() {
        _materials = materials;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nhập hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _submitImport,
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMaterialSelector(),
                  const SizedBox(height: 16),
                  _buildQuantityAndPrice(),
                  const SizedBox(height: 16),
                  _buildSupplierField(),
                  const SizedBox(height: 16),
                  _buildReasonField(),
                  const SizedBox(height: 16),
                  _buildNoteField(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildMaterialSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn vật liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm vật liệu...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildMaterialList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialList() {
    final filteredMaterials = _materials.where((material) =>
        material.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        material.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filteredMaterials.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy vật liệu'),
      );
    }

    return ListView.builder(
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index];
        final isSelected = _selectedMaterial?.id == material.id;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected ? Colors.green : Colors.grey[300],
            child: Icon(
              Icons.inventory,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
          title: Text(material.name),
          subtitle: Text('${material.currentStock.toInt()} ${material.unit}'),
          trailing: Text(
            '${_formatPrice(material.price)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedMaterial = material;
              _unitPriceController.text = material.price.toString();
            });
          },
        );
      },
    );
  }

  Widget _buildQuantityAndPrice() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Số lượng và giá',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Số lượng phải lớn hơn 0';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _calculateTotal();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá (VNĐ) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập đơn giá';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Đơn giá phải lớn hơn 0';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _calculateTotal();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatPrice(_getTotalAmount()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhà cung cấp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Tên nhà cung cấp *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                hintText: 'Nhập tên nhà cung cấp',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên nhà cung cấp';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lý do nhập hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _reasonController.text.isNotEmpty ? _reasonController.text : null,
              decoration: const InputDecoration(
                labelText: 'Lý do *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'Nhập kho mới', child: Text('Nhập kho mới')),
                DropdownMenuItem(value: 'Bổ sung tồn kho', child: Text('Bổ sung tồn kho')),
                DropdownMenuItem(value: 'Nhập hàng khuyến mãi', child: Text('Nhập hàng khuyến mãi')),
                DropdownMenuItem(value: 'Nhập hàng trả lại', child: Text('Nhập hàng trả lại')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (value) {
                _reasonController.text = value ?? '';
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn lý do nhập hàng';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thêm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Nhập ghi chú (tùy chọn)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_selectedMaterial == null) return const SizedBox.shrink();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tóm tắt giao dịch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vật liệu: ${_selectedMaterial!.name}'),
                      Text('Tồn kho hiện tại: ${_selectedMaterial!.currentStock.toInt()} ${_selectedMaterial!.unit}'),
                      Text('Số lượng nhập: ${_quantityController.text.isNotEmpty ? _quantityController.text : "0"} ${_selectedMaterial!.unit}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tồn kho sau nhập: ${_getNewStock()} ${_selectedMaterial!.unit}'),
                    Text(
                      'Tổng tiền: ${_formatPrice(_getTotalAmount())}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitImport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Đang xử lý...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Text(
                'Xác nhận nhập hàng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _calculateTotal() {
    setState(() {
      // Trigger rebuild to update total
    });
  }

  double _getTotalAmount() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    return quantity * unitPrice;
  }

  double _getNewStock() {
    if (_selectedMaterial == null) return 0;
    final currentStock = _selectedMaterial!.currentStock;
    final importQuantity = double.tryParse(_quantityController.text) ?? 0;
    return currentStock + importQuantity;
  }


  Future<void> _submitImport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vật liệu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy thông tin người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userId = currentUser['userId']?.toString();
      if (userId == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy ID người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final quantity = double.parse(_quantityController.text);
      final unitPrice = double.parse(_unitPriceController.text);
      final totalAmount = quantity * unitPrice;

      final materialTransaction = transaction.MaterialTransaction(
        id: '', // Will be generated by Firestore
        materialId: _selectedMaterial!.id,
        materialName: _selectedMaterial!.name,
        userId: userId,
        type: transaction.TransactionType.import,
        status: transaction.TransactionStatus.completed,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: totalAmount,
        supplier: _supplierController.text.trim(),
        reason: _reasonController.text.trim(),
        note: _noteController.text.trim(),
        description: 'Nhập hàng: ${_selectedMaterial!.name}',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        createdBy: currentUser['name'] ?? 'Unknown',
      );

      print('Submitting import transaction...');
      final success = await TransactionService.createTransaction(materialTransaction);
      print('Transaction result: $success');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nhập hàng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          // Return to previous screen
          Navigator.pop(context, true);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nhập hàng thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _submitImport: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
