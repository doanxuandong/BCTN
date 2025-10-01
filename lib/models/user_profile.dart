import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String bio;
  final String position;
  final String company;
  final String location;
  final DateTime joinDate;
  final DateTime? lastActive;
  final List<String> skills;
  final List<String> interests;
  final ProfileStats stats;
  final PrivacySettings privacy;
  
  // Thêm các trường từ Firebase
  final String? pic; // URL ảnh đại diện từ Firebase
  final bool sex; // true = nam, false = nữ
  final String type; // 1=thường, 2=VIP, 3=admin
  final String address;
  final bool isOwnProfile; // true = profile của mình, false = profile người khác
  final List<String> friends; // Danh sách userId bạn bè
  final List<String> followers; // Danh sách userId người theo dõi

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.coverImageUrl,
    this.bio = '',
    this.position = '',
    this.company = '',
    this.location = '',
    required this.joinDate,
    this.lastActive,
    this.skills = const [],
    this.interests = const [],
    required this.stats,
    required this.privacy,
    this.pic,
    this.sex = true, // Mặc định là nam
    this.type = '1', // Mặc định là người dùng thường
    this.address = '',
    this.isOwnProfile = false,
    this.friends = const [],
    this.followers = const [],
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? coverImageUrl,
    String? bio,
    String? position,
    String? company,
    String? location,
    DateTime? joinDate,
    DateTime? lastActive,
    List<String>? skills,
    List<String>? interests,
    ProfileStats? stats,
    PrivacySettings? privacy,
    String? pic,
    bool? sex,
    String? type,
    String? address,
    bool? isOwnProfile,
    List<String>? friends,
    List<String>? followers,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bio: bio ?? this.bio,
      position: position ?? this.position,
      company: company ?? this.company,
      location: location ?? this.location,
      joinDate: joinDate ?? this.joinDate,
      lastActive: lastActive ?? this.lastActive,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      stats: stats ?? this.stats,
      privacy: privacy ?? this.privacy,
      pic: pic ?? this.pic,
      sex: sex ?? this.sex,
      type: type ?? this.type,
      address: address ?? this.address,
      isOwnProfile: isOwnProfile ?? this.isOwnProfile,
      friends: friends ?? this.friends,
      followers: followers ?? this.followers,
    );
  }

  String get displayName => name.isNotEmpty ? name : 'Người dùng';
  String get initials => displayName.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase();
  
  // Getter methods cho các trường mới
  String get genderText => sex ? 'Nam' : 'Nữ';
  String get typeText {
    switch (type) {
      case '1': return 'Người dùng thường';
      case '2': return 'Chủ thầu';
      case '3': return 'Cửa hàng vật liệu';
      case '4': return 'Nhà thiết kế';
      default: return 'Người dùng thường';
    }
  }
  
  Color get typeColor {
    switch (type) {
      case '1': return Colors.grey; // Người dùng thường
      case '2': return Colors.blue; // Chủ thầu
      case '3': return Colors.green; // Cửa hàng vật liệu
      case '4': return Colors.purple; // Nhà thiết kế
      default: return Colors.grey;
    }
  }
  
  // Kiểm tra các trường có dữ liệu hay không
  bool get hasPhone => phone.isNotEmpty;
  bool get hasAddress => address.isNotEmpty;
  bool get hasBio => bio.isNotEmpty;
  bool get hasPosition => position.isNotEmpty;
  bool get hasCompany => company.isNotEmpty;
  bool get hasLocation => location.isNotEmpty;
  bool get hasSkills => skills.isNotEmpty;
  bool get hasInterests => interests.isNotEmpty;
  bool get hasAvatar => (avatarUrl?.isNotEmpty ?? false) || (pic?.isNotEmpty ?? false);
  
  // Lấy ảnh đại diện (ưu tiên pic từ Firebase)
  String? get displayAvatar => pic?.isNotEmpty == true ? pic : avatarUrl;
}

class ProfileStats {
  final int posts;
  final int followers;
  final int following;
  final int friends; // Thêm số lượng bạn bè
  final int projects;
  final int materials;
  final int transactions;

  ProfileStats({
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.friends = 0,
    this.projects = 0,
    this.materials = 0,
    this.transactions = 0,
  });

  ProfileStats copyWith({
    int? posts,
    int? followers,
    int? following,
    int? friends,
    int? projects,
    int? materials,
    int? transactions,
  }) {
    return ProfileStats(
      posts: posts ?? this.posts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      friends: friends ?? this.friends,
      projects: projects ?? this.projects,
      materials: materials ?? this.materials,
      transactions: transactions ?? this.transactions,
    );
  }
}

class PrivacySettings {
  final bool showEmail;
  final bool showPhone;
  final bool showLocation;
  final bool showLastActive;
  final bool allowMessages;

  PrivacySettings({
    this.showEmail = true,
    this.showPhone = false,
    this.showLocation = true,
    this.showLastActive = true,
    this.allowMessages = true,
  });

  PrivacySettings copyWith({
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showLastActive,
    bool? allowMessages,
  }) {
    return PrivacySettings(
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showLocation: showLocation ?? this.showLocation,
      showLastActive: showLastActive ?? this.showLastActive,
      allowMessages: allowMessages ?? this.allowMessages,
    );
  }
}

class MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });
}

// Dữ liệu mẫu
class SampleUserData {
  static UserProfile get currentUser => UserProfile(
    id: '1',
    name: 'Nguyễn Văn A',
    email: 'nguyenvana@email.com',
    phone: '0123456789',
    avatarUrl: 'https://picsum.photos/200/200?random=user',
    coverImageUrl: 'https://picsum.photos/400/200?random=cover',
    bio: 'Kỹ sư xây dựng với 5 năm kinh nghiệm trong quản lý dự án và vật liệu xây dựng. Yêu thích công nghệ và luôn tìm cách cải thiện hiệu quả công việc.',
    position: 'Kỹ sư xây dựng',
    company: 'Công ty TNHH Xây dựng ABC',
    location: 'TP. Hồ Chí Minh, Việt Nam',
    joinDate: DateTime(2023, 1, 15),
    lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    skills: [
      'Quản lý dự án',
      'Quản lý vật liệu',
      'AutoCAD',
      'BIM',
      'Teamwork',
      'Leadership',
    ],
    interests: [
      'Xây dựng',
      'Công nghệ',
      'Du lịch',
      'Thể thao',
      'Âm nhạc',
    ],
    stats: ProfileStats(
      posts: 45,
      followers: 128,
      following: 89,
      projects: 12,
      materials: 156,
      transactions: 324,
    ),
    privacy: PrivacySettings(),
  );
}
