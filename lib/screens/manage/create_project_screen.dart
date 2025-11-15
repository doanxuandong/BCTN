import 'package:flutter/material.dart';
import '../../models/project_pipeline.dart';
import '../../services/project/pipeline_service.dart';
import '../../constants/vn_provinces.dart' as vn;

class CreateProjectScreen extends StatefulWidget {
  final ProjectPipeline? existingProject; // Nếu có, sẽ edit thay vì create

  const CreateProjectScreen({
    super.key,
    this.existingProject,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _designBudgetController = TextEditingController();
  final _constructionBudgetController = TextEditingController();
  final _materialsBudgetController = TextEditingController();
  
  String? _selectedLocation;
  DateTime? _startDate;
  DateTime? _endDate;
  ProjectStatus _status = ProjectStatus.planning;
  ProjectType? _selectedProjectType;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProject != null) {
      _loadExistingProject();
    }
  }

  void _loadExistingProject() {
    final project = widget.existingProject!;
    _projectNameController.text = project.projectName;
    _descriptionController.text = project.description ?? '';
    _designBudgetController.text = project.designBudget?.toStringAsFixed(0) ?? '';
    _constructionBudgetController.text = project.constructionBudget?.toStringAsFixed(0) ?? '';
    _materialsBudgetController.text = project.materialsBudget?.toStringAsFixed(0) ?? '';
    _selectedLocation = project.location;
    _startDate = project.startDate;
    _endDate = project.endDate;
    _status = project.status;
    _selectedProjectType = project.projectType;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _designBudgetController.dispose();
    _constructionBudgetController.dispose();
    _materialsBudgetController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final projectName = _projectNameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();
      
      // Parse budget breakdown
      double? designBudget;
      if (_designBudgetController.text.trim().isNotEmpty) {
        designBudget = double.tryParse(_designBudgetController.text.trim().replaceAll(',', ''));
        if (designBudget == null || designBudget < 0) {
          _showError('Ngân sách cho nhà thiết kế không hợp lệ');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      double? constructionBudget;
      if (_constructionBudgetController.text.trim().isNotEmpty) {
        constructionBudget = double.tryParse(_constructionBudgetController.text.trim().replaceAll(',', ''));
        if (constructionBudget == null || constructionBudget < 0) {
          _showError('Ngân sách cho chủ thầu không hợp lệ');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      double? materialsBudget;
      if (_materialsBudgetController.text.trim().isNotEmpty) {
        materialsBudget = double.tryParse(_materialsBudgetController.text.trim().replaceAll(',', ''));
        if (materialsBudget == null || materialsBudget < 0) {
          _showError('Ngân sách cho cửa hàng VLXD không hợp lệ');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      // Tính tổng ngân sách tự động (optional)
      double? totalBudget;
      double tempTotal = 0;
      if (designBudget != null) tempTotal += designBudget;
      if (constructionBudget != null) tempTotal += constructionBudget;
      if (materialsBudget != null) tempTotal += materialsBudget;
      if (tempTotal > 0) totalBudget = tempTotal;

      String? projectId;
      
      if (widget.existingProject != null) {
        // TODO: Implement update project
        _showError('Tính năng cập nhật dự án sẽ được thêm sau');
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        // Tạo dự án mới
        projectId = await PipelineService.createEmptyProject(
          projectName: projectName,
          description: description,
          budget: totalBudget,
          location: _selectedLocation,
          startDate: _startDate,
          endDate: _endDate,
          status: _status,
          projectType: _selectedProjectType,
          designBudget: designBudget,
          constructionBudget: constructionBudget,
          materialsBudget: materialsBudget,
        );
      }

      if (!mounted) return;

      if (projectId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo dự án thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, projectId); // Return projectId để có thể sử dụng ngay
      } else {
        _showError('Không thể tạo dự án. Vui lòng thử lại.');
      }
    } catch (e) {
      _showError('Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      // Locale sẽ được lấy tự động từ MaterialApp
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Nếu endDate < startDate, cập nhật endDate
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      // Locale sẽ được lấy tự động từ MaterialApp
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.existingProject != null ? 'Chỉnh sửa dự án' : 'Tạo dự án mới',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên dự án
              TextFormField(
                controller: _projectNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên dự án *',
                  hintText: 'Nhập tên dự án',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên dự án';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Loại dự án
              DropdownButtonFormField<ProjectType>(
                value: _selectedProjectType,
                decoration: const InputDecoration(
                  labelText: 'Loại dự án',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ProjectType.values.map((type) {
                  String label;
                  switch (type) {
                    case ProjectType.residential:
                      label = 'Nhà ở';
                      break;
                    case ProjectType.office:
                      label = 'Văn phòng';
                      break;
                    case ProjectType.commercial:
                      label = 'Thương mại';
                      break;
                    case ProjectType.industrial:
                      label = 'Công nghiệp';
                      break;
                    case ProjectType.other:
                      label = 'Khác';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProjectType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả dự án',
                  hintText: 'Nhập mô tả chi tiết về dự án',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Budget Breakdown Section
              const Text(
                'Phân bổ ngân sách (triệu VNĐ)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập ngân sách dự kiến cho từng giai đoạn (tùy chọn)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              
              // Ngân sách cho nhà thiết kế
              TextFormField(
                controller: _designBudgetController,
                decoration: const InputDecoration(
                  labelText: 'Ngân sách cho nhà thiết kế (triệu VNĐ)',
                  hintText: 'Ví dụ: 50',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette),
                  helperText: 'Số tiền dự kiến chi cho thiết kế',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              
              // Ngân sách cho chủ thầu
              TextFormField(
                controller: _constructionBudgetController,
                decoration: const InputDecoration(
                  labelText: 'Ngân sách cho chủ thầu (triệu VNĐ)',
                  hintText: 'Ví dụ: 200',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                  helperText: 'Số tiền dự kiến chi cho thi công',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              
              // Ngân sách cho cửa hàng VLXD
              TextFormField(
                controller: _materialsBudgetController,
                decoration: const InputDecoration(
                  labelText: 'Ngân sách cho cửa hàng VLXD (triệu VNĐ)',
                  hintText: 'Ví dụ: 100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                  helperText: 'Số tiền dự kiến chi cho vật liệu',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Địa điểm
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: vn.vnProvinces.map((provinceName) {
                  return DropdownMenuItem(
                    value: provinceName,
                    child: Text(provinceName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Ngày bắt đầu
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày bắt đầu dự kiến',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: _startDate != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ngày hoàn thành
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày hoàn thành dự kiến',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_available),
                  ),
                  child: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: _endDate != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Button lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Lưu dự án',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

