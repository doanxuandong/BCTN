import 'package:flutter/material.dart';
import '../components/bottom_navbar.dart';
import '../components/story_section.dart';
import '../components/post_card.dart';
import 'material_management_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<PostCard> _posts = [
    PostCard(
      username: 'Nguyễn Văn A',
      timeAgo: '2 giờ trước',
      content: 'Hôm nay trời đẹp quá! Đi dạo phố và chụp ảnh cùng bạn bè. Cuộc sống thật tuyệt vời! 😊',
      imageUrl: 'https://picsum.photos/400/300?random=1',
      likes: 24,
      comments: 8,
      isLiked: true,
    ),
    PostCard(
      username: 'Trần Thị B',
      timeAgo: '4 giờ trước',
      content: 'Vừa hoàn thành dự án mới! Cảm ơn team đã hỗ trợ rất nhiều. Học được rất nhiều điều hay ho trong quá trình làm việc.',
      likes: 45,
      comments: 12,
      isLiked: false,
    ),
    PostCard(
      username: 'Lê Văn C',
      timeAgo: '6 giờ trước',
      content: 'Chia sẻ một số tips học lập trình hiệu quả:\n\n1. Thực hành mỗi ngày\n2. Đọc code của người khác\n3. Tham gia cộng đồng\n4. Không ngại hỏi khi gặp khó khăn',
      likes: 67,
      comments: 23,
      isLiked: true,
    ),
    PostCard(
      username: 'Phạm Thị D',
      timeAgo: '1 ngày trước',
      content: 'Đi du lịch Đà Lạt với gia đình. Cảnh đẹp, không khí trong lành, và những kỷ niệm đáng nhớ!',
      imageUrl: 'https://picsum.photos/400/300?random=2',
      likes: 89,
      comments: 15,
      isLiked: false,
    ),
  ];

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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message_outlined, color: Colors.black),
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
      onRefresh: () async {
        // Simulate refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        children: [
          _buildCreatePost(),
          const StorySection(),
          ..._posts,
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
    return const ChatListScreen();
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
}
