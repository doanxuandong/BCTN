import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onEditProfile;
  final VoidCallback? onEditCover;
  final VoidCallback? onEditAvatar;

  const ProfileHeader({
    super.key,
    required this.user,
    this.onEditProfile,
    this.onEditCover,
    this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildCoverImage(),
          _buildProfileInfo(context),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: user.coverImageUrl != null
                ? Image.network(
                    user.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultCover();
                    },
                  )
                : _buildDefaultCover(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: onEditCover,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.landscape,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAvatarAndActions(),
          const SizedBox(height: 16),
          _buildUserInfo(),
          const SizedBox(height: 16),
          if (user.hasBio) _buildBio(),
          const SizedBox(height: 16),
          _buildUserDetails(),
          const SizedBox(height: 16),
          _buildDetailedInfo(),
        ],
      ),
    );
  }

  Widget _buildAvatarAndActions() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user.hasPosition ? user.position : 'Thành viên',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              // Badge loại tài khoản
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: user.typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: user.typeColor, width: 1),
                ),
                child: Text(
                  user.typeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: user.typeColor,
                  ),
                ),
              ),
              if (user.hasCompany) ...[
                const SizedBox(height: 2),
                Text(
                  user.company,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: onEditAvatar,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
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
              radius: 36,
              backgroundColor: Colors.blue[100],
            child: user.displayAvatar != null
                ? ClipOval(
                    child: Image.network(
                      user.displayAvatar!,
                      width: 72,
                      height: 72,
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      user.initials,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit, size: 20, color: Colors.white),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue[700]!, width: 2),
          ),
          child: IconButton(
            onPressed: () {
              // Share profile functionality
            },
            icon: Icon(Icons.share, size: 20, color: Colors.blue[700]),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoItem('Tham gia', _formatDate(user.joinDate)),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[300],
        ),
        _buildInfoItem('Hoạt động cuối', _formatLastActive()),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[300],
        ),
        _buildInfoItem('Vị trí', user.hasLocation ? user.location : 'Chưa cập nhật'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Giới thiệu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.bio,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    return Row(
      children: [
        if (user.skills.isNotEmpty)
          Expanded(
            child: _buildDetailSection('Kỹ năng', user.skills.take(3).toList()),
          ),
        if (user.skills.isNotEmpty && user.interests.isNotEmpty)
          const SizedBox(width: 16),
        if (user.interests.isNotEmpty)
          Expanded(
            child: _buildDetailSection('Sở thích', user.interests.take(3).toList()),
          ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
    ];
    return '${date.day}/${months[date.month - 1]}/${date.year}';
  }

  String _formatLastActive() {
    if (user.lastActive == null) return 'Chưa biết';
    
    final now = DateTime.now();
    final difference = now.difference(user.lastActive!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
  
  Widget _buildDetailedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông tin chi tiết',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Số điện thoại', user.hasPhone ? user.phone : 'Chưa cập nhật', Icons.phone),
          _buildInfoRow('Địa chỉ', user.hasAddress ? user.address : 'Chưa cập nhật', Icons.location_on),
          _buildInfoRow('Giới tính', user.genderText, Icons.person),
          if (user.hasSkills) _buildInfoRow('Kỹ năng', user.skills.take(3).join(', '), Icons.star),
          if (user.hasInterests) _buildInfoRow('Sở thích', user.interests.take(3).join(', '), Icons.favorite),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    bool isEmpty = value == 'Chưa cập nhật' || value.isEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: isEmpty ? Colors.grey[500] : Colors.grey[800],
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (user.isOwnProfile && isEmpty)
            GestureDetector(
              onTap: () => _onEditField(label),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.blue[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _onEditField(String fieldName) {
    // Navigate to edit profile with specific field focus
    if (onEditProfile != null) {
      onEditProfile!();
    }
  }
}
