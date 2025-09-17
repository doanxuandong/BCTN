import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileMenu extends StatelessWidget {
  final List<MenuItem> menuItems;

  const ProfileMenu({
    super.key,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == menuItems.length - 1;
            
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (item.iconColor ?? Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.iconColor ?? Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: item.onTap,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                    indent: 72,
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<MenuItem> items;

  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        ProfileMenu(menuItems: items),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Helper class to create menu items
class MenuItemFactory {
  static List<MenuItem> createAccountMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: 'Chỉnh sửa hồ sơ',
        subtitle: 'Cập nhật thông tin cá nhân',
        icon: Icons.edit_outlined,
        onTap: () {
          // Navigate to edit profile
        },
      ),
      MenuItem(
        title: 'Thay đổi mật khẩu',
        subtitle: 'Cập nhật mật khẩu bảo mật',
        icon: Icons.lock_outline,
        onTap: () {
          // Navigate to change password
        },
      ),
      MenuItem(
        title: 'Cài đặt riêng tư',
        subtitle: 'Quản lý quyền riêng tư',
        icon: Icons.privacy_tip_outlined,
        onTap: () {
          // Navigate to privacy settings
        },
      ),
    ];
  }

  static List<MenuItem> createAppMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: 'Thông báo',
        subtitle: 'Quản lý thông báo',
        icon: Icons.notifications_outlined,
        iconColor: Colors.orange,
        onTap: () {
          // Navigate to notifications
        },
      ),
      MenuItem(
        title: 'Tin nhắn',
        subtitle: 'Hộp thư của bạn',
        icon: Icons.message_outlined,
        iconColor: Colors.green,
        onTap: () {
          // Navigate to messages
        },
      ),
      MenuItem(
        title: 'Lịch sử hoạt động',
        subtitle: 'Xem lịch sử đăng nhập',
        icon: Icons.history,
        iconColor: Colors.purple,
        onTap: () {
          // Navigate to activity history
        },
      ),
    ];
  }

  static List<MenuItem> createBusinessMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: 'Quản lý dự án',
        subtitle: 'Theo dõi và quản lý dự án',
        icon: Icons.work_outline,
        iconColor: Colors.blue,
        onTap: () {
          // Navigate to project management
        },
      ),
      MenuItem(
        title: 'Báo cáo & Thống kê',
        subtitle: 'Xem báo cáo chi tiết',
        icon: Icons.analytics_outlined,
        iconColor: Colors.teal,
        onTap: () {
          // Navigate to reports
        },
      ),
      MenuItem(
        title: 'Xuất dữ liệu',
        subtitle: 'Xuất dữ liệu ra Excel/PDF',
        icon: Icons.download_outlined,
        iconColor: Colors.indigo,
        onTap: () {
          // Navigate to export data
        },
      ),
    ];
  }

  static List<MenuItem> createSupportMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: 'Trung tâm trợ giúp',
        subtitle: 'Hướng dẫn sử dụng',
        icon: Icons.help_outline,
        iconColor: Colors.blue,
        onTap: () {
          // Navigate to help center
        },
      ),
      MenuItem(
        title: 'Liên hệ hỗ trợ',
        subtitle: 'Gửi phản hồi và yêu cầu',
        icon: Icons.support_agent,
        iconColor: Colors.green,
        onTap: () {
          // Navigate to support contact
        },
      ),
      MenuItem(
        title: 'Đánh giá ứng dụng',
        subtitle: 'Đánh giá trên App Store/Play Store',
        icon: Icons.star_outline,
        iconColor: Colors.amber,
        onTap: () {
          // Navigate to app rating
        },
      ),
    ];
  }

  static List<MenuItem> createSystemMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: 'Cài đặt chung',
        subtitle: 'Cài đặt ứng dụng',
        icon: Icons.settings_outlined,
        iconColor: Colors.grey,
        onTap: () {
          // Navigate to general settings
        },
      ),
      MenuItem(
        title: 'Đăng xuất',
        subtitle: 'Đăng xuất khỏi tài khoản',
        icon: Icons.logout,
        iconColor: Colors.red,
        onTap: () {
          _showLogoutDialog(context);
        },
      ),
    ];
  }

  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đăng xuất thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
