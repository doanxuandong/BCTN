import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/profile/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isMale = true; // true = nam, false = nữ
  String _userType = '1'; // 1 = thường, 2 = vip, 3 = admin

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _positionController = TextEditingController(text: widget.user.position);
    _companyController = TextEditingController(text: widget.user.company);
    _locationController = TextEditingController(text: widget.user.location);
    _bioController = TextEditingController(text: widget.user.bio);
    _addressController = TextEditingController(text: widget.user.address);
    
    // Khởi tạo giới tính và loại tài khoản
    _isMale = widget.user.sex;
    _userType = widget.user.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
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
            _buildAvatarSection(),
            const SizedBox(height: 24),
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildPersonalInfoCard(),
            const SizedBox(height: 16),
            _buildProfessionalInfoCard(),
            const SizedBox(height: 16),
            _buildAdditionalInfoCard(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.blue[100],
                  child: widget.user.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.user.avatarUrl!,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _changeAvatar,
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Thay đổi ảnh đại diện'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      widget.user.initials,
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
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
                labelText: 'Họ và tên *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            
            // Giới tính
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Giới tính",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Nam"),
                          value: true,
                          groupValue: _isMale,
                          onChanged: (value) {
                            setState(() {
                              _isMale = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Nữ"),
                          value: false,
                          groupValue: _isMale,
                          onChanged: (value) {
                            setState(() {
                              _isMale = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Loại tài khoản
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Loại tài khoản",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  DropdownButtonFormField<String>(
                    value: _userType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text("Người dùng thường")),
                      DropdownMenuItem(value: '2', child: Text("Chủ thầu")),
                      DropdownMenuItem(value: '3', child: Text("Cửa hàng vật liệu")),
                      DropdownMenuItem(value: '4', child: Text("Nhà thiết kế")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _userType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin nghề nghiệp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Chức vụ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Công ty',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
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
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Giới thiệu bản thân',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
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
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Lưu thay đổi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thay đổi ảnh đại diện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng chụp ảnh đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng chọn ảnh đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Xóa ảnh đại diện'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Đã xóa ảnh đại diện');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Chuẩn bị dữ liệu cập nhật
      Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'position': _positionController.text,
        'company': _companyController.text,
        'location': _locationController.text,
        'bio': _bioController.text,
        'address': _addressController.text,
        'sex': _isMale,
        'type': _userType,
        'userName': _nameController.text.split(' ').last,
      };

      print('Updating profile with data: $updateData');

      // Lưu lên Firebase
      bool success = await _profileService.updateProfile(widget.user.id, updateData);
      
      if (success) {
        print('Profile updated successfully');
        
        // Tạo updated user object để trả về
        final updatedUser = widget.user.copyWith(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          position: _positionController.text,
          company: _companyController.text,
          location: _locationController.text,
          bio: _bioController.text,
          address: _addressController.text,
          sex: _isMale,
          type: _userType,
        );

        setState(() {
          _isLoading = false;
        });

        Navigator.pop(context, updatedUser);
        _showSnackBar('Đã cập nhật hồ sơ thành công');
      } else {
        print('Failed to update profile');
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Có lỗi xảy ra khi cập nhật hồ sơ');
      }
    } catch (e) {
      print('Error updating profile: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Có lỗi xảy ra: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
