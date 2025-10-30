import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/user/user_profile_service.dart';
import '../../services/social/post_service.dart';
import '../../models/post_model.dart';
import '../../components/post_card.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await UserProfileService.getProfile(widget.userId);
    final posts = await PostService.getPostsByUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _profile = p;
      _posts = posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_profile == null)
              ? const Center(child: Text('Không tìm thấy hồ sơ'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: (_profile!.displayAvatar != null)
                            ? NetworkImage(_profile!.displayAvatar!)
                            : null,
                        child: _profile!.displayAvatar == null
                            ? Text(
                                _profile!.initials,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile!.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profile!.typeText,
                        style: TextStyle(color: _profile!.typeColor),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(Icons.location_on, _profile!.address.isNotEmpty ? _profile!.address : _profile!.location),
                      const SizedBox(height: 8),
                      if (_profile!.specialties.isNotEmpty)
                        _infoRow(Icons.category, _profile!.specialties.join(', ')),
                      const SizedBox(height: 8),
                      _summaryChips(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bài đăng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_posts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('Chưa có bài đăng nào')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => PostCard(post: _posts[index]),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _summaryChips() {
    final items = <Widget>[];
    if (_profile!.rating > 0) {
      items.add(_chip(Icons.star, '${_profile!.rating.toStringAsFixed(1)}★'));
    }
    items.add(_chip(Icons.reviews, '${_profile!.reviewCount} đánh giá'));
    if (_profile!.province.isNotEmpty) items.add(_chip(Icons.location_city, _profile!.province));
    return Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: items);
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.blue[800])),
        ],
      ),
    );
  }
}


