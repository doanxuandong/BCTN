import 'package:flutter/material.dart';
import '../../models/construction_material.dart';

class AddEditMaterialScreen extends StatefulWidget {
  final ConstructionMaterial? material;

  const AddEditMaterialScreen({super.key, this.material});

  @override
  State<AddEditMaterialScreen> createState() => _AddEditMaterialScreenState();
}

class _AddEditMaterialScreenState extends State<AddEditMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _unitController;
  late TextEditingController _currentStockController;
  late TextEditingController _minStockController;
  late TextEditingController _maxStockController;
  late TextEditingController _priceController;
  late TextEditingController _supplierController;
  late TextEditingController _descriptionController;

  final List<String> _categories = [
    'Vật liệu kết dính',
    'Vật liệu cốt liệu',
    'Vật liệu xây',
    'Vật liệu cốt thép',
    'Vật liệu hoàn thiện',
    'Vật liệu cách nhiệt',
  ];

  final List<String> _units = [
    'Bao',
    'm³',
    'Viên',
    'Cây',
    'Tấm',
    'm²',
    'kg',
    'Lít',
  ];

  String _selectedCategory = '';
  String _selectedUnit = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.material?.name ?? '');
    _categoryController = TextEditingController(text: widget.material?.category ?? '');
    _unitController = TextEditingController(text: widget.material?.unit ?? '');
    _currentStockController = TextEditingController(text: widget.material?.currentStock.toString() ?? '');
    _minStockController = TextEditingController(text: widget.material?.minStock.toString() ?? '');
    _maxStockController = TextEditingController(text: widget.material?.maxStock.toString() ?? '');
    _priceController = TextEditingController(text: widget.material?.price.toString() ?? '');
    _supplierController = TextEditingController(text: widget.material?.supplier ?? '');
    _descriptionController = TextEditingController(text: widget.material?.description ?? '');

    _selectedCategory = widget.material?.category ?? '';
    _selectedUnit = widget.material?.unit ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.material == null ? 'Thêm vật liệu mới' : 'Chỉnh sửa vật liệu',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveMaterial,
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildStockInfoCard(),
            const SizedBox(height: 16),
            _buildAdditionalInfoCard(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên vật liệu *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.construction),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên vật liệu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Loại vật liệu *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                  _categoryController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn loại vật liệu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUnit.isEmpty ? null : _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Đơn vị tính *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              items: _units.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value ?? '';
                  _unitController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn đơn vị tính';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoCard() {
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
                  child: TextFormField(
                    controller: _currentStockController,
                    decoration: const InputDecoration(
                      labelText: 'Tồn kho hiện tại *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng tồn kho';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá (VNĐ) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Tồn kho tối thiểu *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tồn kho tối thiểu';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxStockController,
                    decoration: const InputDecoration(
                      labelText: 'Tồn kho tối đa *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warehouse),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tồn kho tối đa';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Vui lòng nhập số hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin bổ sung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Nhà cung cấp',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveMaterial,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.material == null ? 'Thêm vật liệu' : 'Cập nhật vật liệu',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveMaterial() {
    if (_formKey.currentState!.validate()) {
      // Simulate save
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.material == null
                ? 'Đã thêm vật liệu "${_nameController.text}"'
                : 'Đã cập nhật vật liệu "${_nameController.text}"',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
