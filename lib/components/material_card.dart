import 'package:flutter/material.dart';
import '../models/construction_material.dart';

class MaterialCard extends StatelessWidget {
  final ConstructionMaterial material;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MaterialCard({
    super.key,
    required this.material,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildMaterialImage(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          material.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStockIndicator(),
                            const SizedBox(width: 8),
                            _buildPriceChip(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(),
                ],
              ),
              const SizedBox(height: 12),
              _buildStockInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: material.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                material.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultIcon();
                },
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (material.category) {
      case 'Vật liệu kết dính':
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'Vật liệu cốt liệu':
        iconData = Icons.landscape;
        iconColor = Colors.brown;
        break;
      case 'Vật liệu xây':
        iconData = Icons.crop_square;
        iconColor = Colors.red;
        break;
      case 'Vật liệu cốt thép':
        iconData = Icons.straighten;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.construction;
        iconColor = Colors.orange;
    }

    return Icon(iconData, color: iconColor, size: 30);
  }

  Widget _buildStockIndicator() {
    Color color;
    String status;
    
    switch (material.stockStatus) {
      case StockStatus.low:
        color = Colors.red;
        status = 'Thiếu';
        break;
      case StockStatus.high:
        color = Colors.orange;
        status = 'Dư';
        break;
      case StockStatus.normal:
        color = Colors.green;
        status = 'Đủ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_formatPrice(material.price)}/${material.unit}',
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, color: Colors.blue),
          iconSize: 20,
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, color: Colors.red),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStockDetail(
              'Tồn kho',
              '${material.currentStock.toStringAsFixed(1)} ${material.unit}',
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStockDetail(
              'Tối thiểu',
              '${material.minStock.toStringAsFixed(1)} ${material.unit}',
              Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStockDetail(
              'Giá trị',
              '${_formatPrice(material.totalValue)}',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDetail(String label, String value, Color color) {
    return Column(
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
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }
}
