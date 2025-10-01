import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../components/profile_header.dart';
import '../../components/profile_stats.dart';
import '../../components/profile_menu.dart';
import '../../components/image_source_dialog.dart';
import '../friends/friends_screen.dart';
import 'edit_profile_screen.dart';
import '../../services/user/user_session.dart';
import '../../services/profile/profile_service.dart';
import '../../services/friends/friends_service.dart';
import '../../services/storage/image_service.dart';
import '../../services/social/post_service.dart';
import '../../models/post_model.dart';
import '../../components/post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final FriendsService _friendsService = FriendsService();
  UserProfile? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Refresh profile khi có thay đổi
  Future<void> _refreshProfile() async {
    await _loadUserProfile();
  }

  // Xử lý chọn ảnh avatar
  Future<void> _handleAvatarSelection() async {
    if (_currentUser == null) return;
    
    final result = await ImageSourceDialog.show(
      context: context,
      title: 'Chọn ảnh đại diện',
      currentImageUrl: _currentUser!.displayAvatar,
    );
    
    print('Avatar selection result: $result');
    print('Result type: ${result.runtimeType}');
    
    if (result != null && result is File) {
      print('Uploading avatar file: ${result.path}');
      print('File exists: ${await result.exists()}');
      print('File size: ${await result.length()}');
      await _uploadAvatar(result);
    } else if (result == 'delete') {
      print('Deleting avatar');
      await _deleteAvatar();
    } else {
      print('No action taken for result: $result');
    }
  }

  // Xử lý chọn ảnh bìa
  Future<void> _handleCoverSelection() async {
    if (_currentUser == null) return;
    
    final result = await ImageSourceDialog.show(
      context: context,
      title: 'Chọn ảnh bìa',
      currentImageUrl: _currentUser!.coverImageUrl,
    );
    
    if (result != null && result is File) {
      await _uploadCover(result);
    } else if (result == 'delete') {
      await _deleteCover();
    }
  }

  // Upload ảnh avatar
  Future<void> _uploadAvatar(File imageFile) async {
    if (_currentUser == null) return;
    
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Upload ảnh lên Firebase Storage
      final imageUrl = await ImageService.uploadImage(
        imageFile: imageFile,
        userId: _currentUser!.id,
        type: 'avatar',
      );
      
      if (imageUrl != null) {
        // Cập nhật profile trong Firebase
        await _profileService.updateProfile(_currentUser!.id, {
          'pic': imageUrl,
        });
        
        // Cập nhật UI
        setState(() {
          _currentUser = _currentUser!.copyWith(pic: imageUrl);
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi tải ảnh lên. Vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại!')),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Đóng loading dialog
      }
    }
  }

  // Upload ảnh bìa
  Future<void> _uploadCover(File imageFile) async {
    if (_currentUser == null) return;
    
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Upload ảnh lên Firebase Storage
      final imageUrl = await ImageService.uploadImage(
        imageFile: imageFile,
        userId: _currentUser!.id,
        type: 'cover',
      );
      
      if (imageUrl != null) {
        // Cập nhật profile trong Firebase
        await _profileService.updateProfile(_currentUser!.id, {
          'coverImageUrl': imageUrl,
        });
        
        // Cập nhật UI
        setState(() {
          _currentUser = _currentUser!.copyWith(coverImageUrl: imageUrl);
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh bìa thành công!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi tải ảnh lên. Vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      print('Error uploading cover: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại!')),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Đóng loading dialog
      }
    }
  }

  // Xóa ảnh avatar
  Future<void> _deleteAvatar() async {
    if (_currentUser == null || _currentUser!.displayAvatar == null) return;
    
    try {
      // Xóa ảnh từ Firebase Storage
      await ImageService.deleteImage(_currentUser!.displayAvatar!);
      
      // Cập nhật profile trong Firebase
      await _profileService.updateProfile(_currentUser!.id, {
        'pic': null,
      });
      
      // Cập nhật UI
      setState(() {
        _currentUser = _currentUser!.copyWith(pic: null);
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa ảnh đại diện thành công!')),
        );
      }
    } catch (e) {
      print('Error deleting avatar: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại!')),
        );
      }
    }
  }

  // Xóa ảnh bìa
  Future<void> _deleteCover() async {
    if (_currentUser == null || _currentUser!.coverImageUrl == null) return;
    
    try {
      // Xóa ảnh từ Firebase Storage
      await ImageService.deleteImage(_currentUser!.coverImageUrl!);
      
      // Cập nhật profile trong Firebase
      await _profileService.updateProfile(_currentUser!.id, {
        'coverImageUrl': null,
      });
      
      // Cập nhật UI
      setState(() {
        _currentUser = _currentUser!.copyWith(coverImageUrl: null);
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa ảnh bìa thành công!')),
        );
      }
    } catch (e) {
      print('Error deleting cover: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại!')),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin user đang đăng nhập
      final currentUserData = await UserSession.getCurrentUser();
      
      if (currentUserData == null) {
        print('No user logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('Current user data from session: $currentUserData');
      
      final userId = currentUserData['userId']?.toString();
      if (userId == null) {
        print('No userId found in session');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('Loading profile for logged in user: $userId');
      
      // Thử lấy profile từ Firebase
      final profile = await _profileService.getProfile(userId, isOwnProfile: true);
      
      if (profile != null) {
        print('Profile loaded from Firebase: ${profile.name}');
        // Cập nhật số lượng bạn bè thực tế
        final friends = await _friendsService.getFriends(userId);
        final myPosts = await PostService.getPostsByUser(userId);
        final updatedProfile = profile.copyWith(
          stats: profile.stats.copyWith(friends: friends.length, posts: myPosts.length),
        );
        setState(() {
          _currentUser = updatedProfile;
          _isLoading = false;
        });
      } else {
        print('Profile not found in Firebase, creating from session data');
        // Tạo profile từ dữ liệu session nếu không tìm thấy trong Firebase
        // Load số lượng bạn bè thực tế
        final friends = await _friendsService.getFriends(userId);
        setState(() {
          _currentUser = UserProfile(
            id: userId,
            name: currentUserData['name'] ?? 'Người dùng',
            email: currentUserData['email'] ?? '',
            phone: currentUserData['phone'] ?? '',
            joinDate: DateTime.now(),
            stats: ProfileStats(
              posts: 0,
              followers: 0,
              following: 0,
              friends: friends.length, // Số lượng bạn bè thực tế
              projects: 0,
              materials: 0,
              transactions: 0,
            ),
            privacy: PrivacySettings(),
            sex: currentUserData['sex'] ?? true,
            type: currentUserData['type'] ?? '1',
            address: currentUserData['address'] ?? '',
            isOwnProfile: true,
            friends: friends.map((f) => f.id).toList(),
            followers: [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Fallback to sample data on error
      setState(() {
        _currentUser = SampleUserData.currentUser.copyWith(
          isOwnProfile: true,
          friends: ['friend1', 'friend2', 'friend3'],
          followers: ['follower1', 'follower2'],
          stats: SampleUserData.currentUser.stats.copyWith(friends: 3),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                user: _currentUser!,
                onEditProfile: _navigateToEditProfile,
                onEditCover: _handleCoverSelection,
                onEditAvatar: _handleAvatarSelection,
              ),
              const SizedBox(height: 16),
              ProfileStatsWidget(
                stats: _currentUser!.stats,
                onPostsTap: () => _showPosts(),
                onFollowersTap: () => _showFollowers(),
                onFollowingTap: () => _showFollowing(),
                onFriendsTap: () => _showFriends(),
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
      floatingActionButton: _currentUser!.isOwnProfile
          ? FloatingActionButton.extended(
        onPressed: _navigateToEditProfile,
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: Colors.white),
        ),
            )
          : null,
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
    if (_currentUser == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    ).then((result) {
      if (result != null && result is UserProfile) {
        setState(() {
          _currentUser = result;
        });
      }
    });
  }

  void _showFriends() {
    if (_currentUser == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsScreen(userId: _currentUser!.id),
      ),
    ).then((_) {
      // Refresh profile sau khi quay lại từ FriendsScreen
      _refreshProfile();
    });
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
    if (_currentUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UserPostsScreen(userId: _currentUser!.id, userName: _currentUser!.displayName),
      ),
    );
  }

  void _showFollowers() {
    if (_currentUser == null) return;
    _showSnackBar('Hiển thị ${_currentUser!.stats.followers} người theo dõi');
  }

  void _showFollowing() {
    if (_currentUser == null) return;
    _showSnackBar('Hiển thị ${_currentUser!.stats.following} người đang theo dõi');
  }

  void _showProjects() {
    if (_currentUser == null) return;
    _showSnackBar('Hiển thị ${_currentUser!.stats.projects} dự án');
  }

  void _showMaterials() {
    if (_currentUser == null) return;
    _showSnackBar('Hiển thị ${_currentUser!.stats.materials} vật liệu');
  }

  void _showTransactions() {
    if (_currentUser == null) return;
    _showSnackBar('Hiển thị ${_currentUser!.stats.transactions} giao dịch');
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

class _UserPostsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const _UserPostsScreen({required this.userId, required this.userName});

  @override
  State<_UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<_UserPostsScreen> {
  bool _loading = true;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await PostService.getPostsByUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _posts = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bài đăng của ${widget.userName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Chưa có bài đăng nào'))
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) => PostCard(post: _posts[index]),
      ),
    );
  }
}
