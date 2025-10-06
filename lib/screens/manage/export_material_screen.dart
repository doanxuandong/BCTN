import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/construction_material.dart';
import '../../models/material_transaction.dart' as transaction;
import '../../services/manage/material_service.dart';
import '../../services/manage/transaction_service.dart';
import '../../services/user/user_session.dart';

class ExportMaterialScreen extends StatefulWidget {
  final ConstructionMaterial? material;

  const ExportMaterialScreen({super.key, this.material});

  @override
  State<ExportMaterialScreen> createState() => _ExportMaterialScreenState();
}

class _ExportMaterialScreenState extends State<ExportMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _receiverController;
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
    _receiverController = TextEditingController();
    _reasonController = TextEditingController(text: 'Sử dụng cho dự án');
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
    _receiverController.dispose();
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
          'Xuất hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _submitExport,
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
                  _buildReceiverField(),
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
        final canExport = material.currentStock > 0;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected 
                ? Colors.red 
                : canExport 
                    ? Colors.grey[300] 
                    : Colors.grey[200],
            child: Icon(
              Icons.inventory,
              color: isSelected 
                  ? Colors.white 
                  : canExport 
                      ? Colors.grey[600] 
                      : Colors.grey[400],
            ),
          ),
          title: Text(
            material.name,
            style: TextStyle(
              color: canExport ? null : Colors.grey[500],
            ),
          ),
          subtitle: Text(
            '${material.currentStock.toInt()} ${material.unit}',
            style: TextStyle(
              color: canExport ? null : Colors.grey[500],
            ),
          ),
          trailing: Text(
            '${_formatPrice(material.price)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: canExport ? null : Colors.grey[500],
            ),
          ),
          selected: isSelected,
          enabled: canExport,
          onTap: canExport ? () {
            setState(() {
              _selectedMaterial = material;
              _unitPriceController.text = material.price.toString();
            });
          } : null,
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
                    decoration: InputDecoration(
                      labelText: 'Số lượng *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.scale),
                      suffixText: _selectedMaterial?.unit ?? '',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Số lượng phải lớn hơn 0';
                      }
                      if (_selectedMaterial != null && quantity > _selectedMaterial!.currentStock) {
                        return 'Số lượng không được vượt quá tồn kho hiện tại (${_selectedMaterial!.currentStock.toInt()})';
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
            if (_selectedMaterial != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tồn kho hiện tại: ${_selectedMaterial!.currentStock.toInt()} ${_selectedMaterial!.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
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
                      color: Colors.red[700],
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

  Widget _buildReceiverField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Người nhận',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _receiverController,
              decoration: const InputDecoration(
                labelText: 'Tên người nhận *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Nhập tên người nhận',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên người nhận';
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
              'Lý do xuất hàng',
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
                DropdownMenuItem(value: 'Sử dụng cho dự án', child: Text('Sử dụng cho dự án')),
                DropdownMenuItem(value: 'Bán hàng', child: Text('Bán hàng')),
                DropdownMenuItem(value: 'Chuyển kho', child: Text('Chuyển kho')),
                DropdownMenuItem(value: 'Hỏng hóc', child: Text('Hỏng hóc')),
                DropdownMenuItem(value: 'Trả lại nhà cung cấp', child: Text('Trả lại nhà cung cấp')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (value) {
                _reasonController.text = value ?? '';
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn lý do xuất hàng';
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
      color: Colors.red[50],
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
                      Text('Số lượng xuất: ${_quantityController.text.isNotEmpty ? _quantityController.text : "0"} ${_selectedMaterial!.unit}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tồn kho sau xuất: ${_getNewStock()} ${_selectedMaterial!.unit}'),
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
        onPressed: _isLoading ? null : _submitExport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
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
                'Xác nhận xuất hàng',
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
    final exportQuantity = double.tryParse(_quantityController.text) ?? 0;
    return (currentStock - exportQuantity).clamp(0, double.infinity);
  }

  Future<void> _submitExport() async {
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

    final quantity = double.parse(_quantityController.text);
    if (quantity > _selectedMaterial!.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng xuất không được vượt quá tồn kho hiện tại'),
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
          Navigator.of(context).pop(); // Close loading dialog
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
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy ID người dùng'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final unitPrice = double.parse(_unitPriceController.text);
      final totalAmount = quantity * unitPrice;

      final materialTransaction = transaction.MaterialTransaction(
        id: '', // Will be generated by Firestore
        materialId: _selectedMaterial!.id,
        materialName: _selectedMaterial!.name,
        userId: userId,
        type: transaction.TransactionType.export,
        status: transaction.TransactionStatus.completed,
        quantity: quantity,
        unitPrice: unitPrice,
        totalAmount: totalAmount,
        supplier: _receiverController.text.trim(),
        reason: _reasonController.text.trim(),
        note: _noteController.text.trim(),
        description: 'Xuất hàng: ${_selectedMaterial!.name}',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        createdBy: currentUser['name'] ?? 'Unknown',
      );

      print('Submitting export transaction...');
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
              content: Text('Xuất hàng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          // Return to previous screen
          Navigator.pop(context, true);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xuất hàng thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _submitExport: $e');
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
