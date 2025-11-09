import 'package:flutter/material.dart';
import '../../components/bottom_navbar.dart';
import '../../components/story_section.dart';
import '../../components/post_card.dart';
import '../../components/notification_widget.dart';
import '../../services/social/post_service.dart';
import '../../models/post_model.dart';
import '../manage/material_management_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../chat/chat_conversations_screen.dart';
import '../auth/login.dart';
import '../social/create_post_screen.dart';
import '../../services/user/user_session.dart';
import '../../services/user/user_profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _updateUserLocation(); // Cập nhật location khi app mở
  }

  /// Cập nhật vị trí người dùng khi app mở
  /// Chạy ở background, không chặn UI
  Future<void> _updateUserLocation() async {
    try {
      // Update location ở background (không require accurate để nhanh hơn)
      UserProfileService.updateCurrentUserLocation(
        requireAccurateLocation: false,
      ).then((success) {
        if (success) {
          debugPrint('[Home] User location updated successfully');
        } else {
          debugPrint('[Home] Failed to update user location');
        }
      }).catchError((e) {
        debugPrint('[Home] Error updating location: $e');
      });
    } catch (e) {
      debugPrint('[Home] Error in _updateUserLocation: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('[Home] Loading posts...');
      final posts = await PostService.getPosts();
      debugPrint('[Home] Loaded ${posts.length} posts');
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Home] Error loading posts: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _posts = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'BuilderConnect',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          const NotificationWidget(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () async {
              await UserSession.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildChatTab();
      case 2:
        return _buildSearchTab();
      case 3:
        return _buildManageTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildCreatePost(),
                const StorySection(),
                ..._posts.map((post) => PostCard(post: post)),
              ],
            ),
    );
  }

  Widget _buildCreatePost() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue[100],
            child: const Text(
              'U',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openCreatePost(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Bạn đang nghĩ gì?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.photo_camera, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return const ChatConversationsScreen();
  }

  Widget _buildSearchTab() {
    return const SearchScreen();
  }

  Widget _buildManageTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const MaterialManagementScreen(),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  void _openCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    if (result == true) {
      _loadPosts(); // Reload posts after creating new one
    }
  }
}
