import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class FriendCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onFollow;
  final bool showRemoveButton;
  final bool isFollowing;

  const FriendCard({
    super.key,
    required this.user,
    this.onTap,
    this.onRemove,
    this.onFollow,
    this.showRemoveButton = false,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 8),
              _buildName(),
              const SizedBox(height: 4),
              _buildType(),
              const SizedBox(height: 8),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue[100],
            child: user.displayAvatar != null
                ? ClipOval(
                    child: Image.network(
                      user.displayAvatar!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        if (user.type != '1')
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: user.typeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                user.type == '2' ? Icons.star : Icons.admin_panel_settings,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      user.initials,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildName() {
    return Text(
      user.displayName,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildType() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: user.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showRemoveButton)
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.person_remove,
                size: 16,
                color: Colors.red[700],
              ),
            ),
          ),
        if (onFollow != null)
          GestureDetector(
            onTap: onFollow,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.grey[200] : Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isFollowing ? Icons.person_remove : Icons.person_add,
                size: 16,
                color: isFollowing ? Colors.grey[700] : Colors.blue[700],
              ),
            ),
          ),
      ],
    );
  }
}

class FriendListTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onFollow;
  final bool showRemoveButton;
  final bool isFollowing;

  const FriendListTile({
    super.key,
    required this.user,
    this.onTap,
    this.onRemove,
    this.onFollow,
    this.showRemoveButton = false,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildAvatar(),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.typeText),
            if (user.hasPosition) Text(user.position),
          ],
        ),
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          child: user.displayAvatar != null
              ? ClipOval(
                  child: Image.network(
                    user.displayAvatar!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  user.initials,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
        ),
        if (user.type != '1')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: user.typeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                user.type == '2' ? Icons.star : Icons.admin_panel_settings,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing() {
    if (showRemoveButton) {
      return IconButton(
        onPressed: onRemove,
        icon: Icon(Icons.person_remove, color: Colors.red[700]),
      );
    }
    
    if (onFollow != null) {
      return IconButton(
        onPressed: onFollow,
        icon: Icon(
          isFollowing ? Icons.person_remove : Icons.person_add,
          color: isFollowing ? Colors.grey[700] : Colors.blue[700],
        ),
      );
    }
    
    return const Icon(Icons.arrow_forward_ios, size: 16);
  }
}
