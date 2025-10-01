import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileStatsWidget extends StatelessWidget {
  final ProfileStats stats;
  final VoidCallback? onPostsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onProjectsTap;
  final VoidCallback? onMaterialsTap;
  final VoidCallback? onTransactionsTap;

  const ProfileStatsWidget({
    super.key,
    required this.stats,
    this.onPostsTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onFriendsTap,
    this.onProjectsTap,
    this.onMaterialsTap,
    this.onTransactionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Thống kê hoạt động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Bài đăng',
                  stats.posts,
                  Icons.article_outlined,
                  Colors.blue,
                  onPostsTap,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  'Bạn bè',
                  stats.friends,
                  Icons.people_outline,
                  Colors.green,
                  onFriendsTap,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  'Theo dõi',
                  stats.following,
                  Icons.person_add_outlined,
                  Colors.orange,
                  onFollowingTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Người theo dõi',
                  stats.followers,
                  Icons.favorite_outline,
                  Colors.pink,
                  onFollowersTap,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  'Dự án',
                  stats.projects,
                  Icons.work_outline,
                  Colors.purple,
                  onProjectsTap,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem(
                  'Vật liệu',
                  stats.materials,
                  Icons.inventory_2_outlined,
                  Colors.red,
                  onMaterialsTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    int value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatNumber(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
