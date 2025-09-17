import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../components/profile_header.dart';
import '../components/profile_stats.dart';
import '../components/profile_menu.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = SampleUserData.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _showSettings,
                icon: const Icon(Icons.settings),
              ),
              IconButton(
                onPressed: _showMoreOptions,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ProfileHeader(
                user: _currentUser,
                onEditProfile: _navigateToEditProfile,
                onEditCover: _editCoverImage,
              ),
              const SizedBox(height: 16),
              ProfileStatsWidget(
                stats: _currentUser.stats,
                onPostsTap: () => _showPosts(),
                onFollowersTap: () => _showFollowers(),
                onFollowingTap: () => _showFollowing(),
                onProjectsTap: () => _showProjects(),
                onMaterialsTap: () => _showMaterials(),
                onTransactionsTap: () => _showTransactions(),
              ),
              const SizedBox(height: 8),
              _buildMenuSections(),
              const SizedBox(height: 100), // Bottom padding for FAB
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEditProfile,
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMenuSections() {
    return Column(
      children: [
        ProfileMenuSection(
          title: 'Tài khoản',
          items: MenuItemFactory.createAccountMenuItems(context),
        ),
        ProfileMenuSection(
          title: 'Ứng dụng',
          items: MenuItemFactory.createAppMenuItems(context),
        ),
        ProfileMenuSection(
          title: 'Kinh doanh',
          items: MenuItemFactory.createBusinessMenuItems(context),
        ),
        ProfileMenuSection(
          title: 'Hỗ trợ',
          items: MenuItemFactory.createSupportMenuItems(context),
        ),
        ProfileMenuSection(
          title: 'Hệ thống',
          items: MenuItemFactory.createSystemMenuItems(context),
        ),
      ],
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser),
      ),
    ).then((result) {
      if (result != null && result is UserProfile) {
        setState(() {
          _currentUser = result;
        });
      }
    });
  }

  void _editCoverImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thay đổi ảnh bìa',
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
              title: const Text('Xóa ảnh bìa'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Đã xóa ảnh bìa');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Chủ đề'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng thay đổi chủ đề đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Ngôn ngữ'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng thay đổi ngôn ngữ đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Thông báo'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng cài đặt thông báo đang phát triển');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tùy chọn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ hồ sơ'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Đã chia sẻ hồ sơ');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Mã QR hồ sơ'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Chức năng mã QR đang phát triển');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép liên kết'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Đã sao chép liên kết hồ sơ');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPosts() {
    _showSnackBar('Hiển thị ${_currentUser.stats.posts} bài đăng');
  }

  void _showFollowers() {
    _showSnackBar('Hiển thị ${_currentUser.stats.followers} người theo dõi');
  }

  void _showFollowing() {
    _showSnackBar('Hiển thị ${_currentUser.stats.following} người đang theo dõi');
  }

  void _showProjects() {
    _showSnackBar('Hiển thị ${_currentUser.stats.projects} dự án');
  }

  void _showMaterials() {
    _showSnackBar('Hiển thị ${_currentUser.stats.materials} vật liệu');
  }

  void _showTransactions() {
    _showSnackBar('Hiển thị ${_currentUser.stats.transactions} giao dịch');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
      ),
    );
  }
}
