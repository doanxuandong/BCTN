import 'package:flutter/material.dart';
import '../models/search_models.dart';

class AccountCard extends StatelessWidget {
  final SearchAccount account;
  final VoidCallback? onTap;

  const AccountCard({super.key, required this.account, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo()),
              const SizedBox(width: 8),
              _buildTrailing(),
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: account.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      account.avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    account.name.isNotEmpty ? account.name[0] : '?',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: account.type == AccountType.designer 
                  ? Colors.purple 
                  : account.type == AccountType.contractor 
                      ? Colors.green 
                      : Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              account.type == AccountType.designer 
                  ? 'Nhà thiết kế' 
                  : account.type == AccountType.contractor 
                      ? 'Chủ thầu' 
                      : 'Cửa hàng',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          account.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.place, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${account.address}, ${account.province.name}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: account.specialties.take(3).map((s) => _chip(s.name)).toList(),
        ),
        const SizedBox(height: 6),
        _buildAdditionalInfo(),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.blue[700], fontSize: 11),
      ),
    );
  }

  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              account.rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(' (${account.reviewCount})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${account.distanceKm.toStringAsFixed(1)} km', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    String info = '';
    
    switch (account.type) {
      case AccountType.designer:
        info = '${account.additionalInfo['experience'] ?? 'N/A'} • ${account.additionalInfo['price_range'] ?? 'N/A'}';
        break;
      case AccountType.contractor:
        info = '${account.additionalInfo['license'] ?? 'N/A'} • ${account.additionalInfo['experience'] ?? 'N/A'}';
        break;
      case AccountType.store:
        info = '${account.additionalInfo['business_type'] ?? 'N/A'} • ${account.additionalInfo['delivery'] ?? 'N/A'}';
        break;
    }
    
    return Text(
      info,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
