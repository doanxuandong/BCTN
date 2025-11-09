import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../screens/chat/material_catalog_detail_screen.dart';
import '../screens/chat/portfolio_gallery_screen.dart';
import '../screens/chat/timeline_detail_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: message.isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromMe) ...[
            _buildSenderAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isFromMe) _buildSenderName(),
                const SizedBox(height: 2),
                _buildMessageContent(),
                const SizedBox(height: 2),
                _buildMessageTime(),
              ],
            ),
          ),
          if (message.isFromMe) ...[
            const SizedBox(width: 8),
            _buildMessageStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue[100],
        child: Text(
          message.senderName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        message.senderName,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.voice:
        return _buildVoiceMessage();
      case MessageType.sticker:
        return _buildStickerMessage();
      // Business message types
      case MessageType.quoteRequest:
        return _buildQuoteRequestMessage();
      case MessageType.quoteResponse:
        return _buildQuoteResponseMessage();
      case MessageType.portfolioShare:
        return _buildPortfolioMessage();
      case MessageType.projectTimeline:
        return _buildTimelineMessage();
      case MessageType.materialCatalog:
        return _buildMaterialCatalogMessage();
      case MessageType.appointmentRequest:
      case MessageType.appointmentConfirm:
        return _buildAppointmentMessage();
    }
  }

  Widget _buildTextMessage() {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: message.isFromMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: message.isFromMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isFromMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    final imageUrl = message.fileUrl ?? message.content; // Ưu tiên fileUrl
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          // TODO: Mở ảnh full screen
          print('View image: $imageUrl');
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            maxHeight: 200,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Không thể tải hình ảnh',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileMessage() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          // TODO: Mở file khi tap (cần package open_file hoặc url_launcher)
          if (message.fileUrl != null) {
            // Có thể dùng url_launcher để mở URL
            print('Open file: ${message.fileUrl}');
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFileIcon(),
                color: message.isFromMe ? Colors.white : Colors.grey[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.fileName ?? message.content,
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.fileSize != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(message.fileSize!),
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.download,
                color: message.isFromMe ? Colors.white70 : Colors.grey[600],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    if (message.fileName == null) return Icons.insert_drive_file;
    final ext = message.fileName!.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildVoiceMessage() {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: message.isFromMe ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '0:15',
              style: TextStyle(
                color: message.isFromMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        '😊',
        style: const TextStyle(fontSize: 48),
      ),
    );
  }

  Widget _buildMessageTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        message.timeFormatted,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  // ==================== BUSINESS MESSAGE WIDGETS ====================

  Widget _buildQuoteRequestMessage() {
    final businessData = message.businessData ?? {};
    final projectType = businessData['projectType'] as String?;
    final estimatedBudget = businessData['estimatedBudget'] as double?;
    final projectDescription = businessData['projectDescription'] as String?;

    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: message.isFromMe ? Colors.blue[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromMe
                    ? Colors.blue[700]
                    : Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.request_quote,
                    color: message.isFromMe ? Colors.white : Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu báo giá',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (projectType != null) ...[
                    _buildInfoRow('Loại dự án', projectType),
                    const SizedBox(height: 8),
                  ],
                  if (estimatedBudget != null) ...[
                    _buildInfoRow(
                      'Ngân sách dự kiến',
                      '${estimatedBudget.toStringAsFixed(0)} triệu VNĐ',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (projectDescription != null) ...[
                    Text(
                      'Mô tả:',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white70 : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      projectDescription,
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteResponseMessage() {
    final businessData = message.businessData ?? {};
    final price = businessData['price'] as double?;
    final notes = businessData['notes'] as String?;
    final estimatedCompletionDate = businessData['estimatedCompletionDate'] as int?;

    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.green[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: message.isFromMe ? Colors.green[700]! : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromMe
                    ? Colors.green[700]
                    : Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: message.isFromMe ? Colors.white : Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Báo giá',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (price != null) ...[
                    Text(
                      '${price.toStringAsFixed(0)} triệu VNĐ',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (estimatedCompletionDate != null) ...[
                    _buildInfoRow(
                      'Dự kiến hoàn thành',
                      _formatDate(DateTime.fromMillisecondsSinceEpoch(estimatedCompletionDate)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (notes != null && notes.isNotEmpty) ...[
                    Text(
                      'Ghi chú:',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white70 : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCatalogMessage() {
    final businessData = message.businessData ?? {};
    final materialCount = businessData['materialCount'] as int? ?? 0;
    final category = businessData['category'] as String?;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialCatalogDetailScreen(message: message),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.orange[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.isFromMe ? Colors.orange[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isFromMe
                      ? Colors.orange[700]
                      : Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: message.isFromMe ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catalog vật liệu',
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$materialCount sản phẩm',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Danh mục: $category',
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: message.isFromMe ? Colors.white70 : Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nhấn để xem chi tiết',
                          style: TextStyle(
                            color: message.isFromMe ? Colors.white70 : Colors.blue[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioMessage() {
    final businessData = message.businessData ?? {};
    final imageCount = businessData['imageCount'] as int? ?? 0;
    final projectTitle = businessData['projectTitle'] as String?;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PortfolioGalleryScreen(message: message),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.purple[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.isFromMe ? Colors.purple[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isFromMe
                      ? Colors.purple[700]
                      : Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: message.isFromMe ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Portfolio',
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (projectTitle != null) ...[
                      Text(
                        projectTitle,
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '$imageCount hình ảnh',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: message.isFromMe ? Colors.white70 : Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nhấn để xem gallery',
                          style: TextStyle(
                            color: message.isFromMe ? Colors.white70 : Colors.blue[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineMessage() {
    final businessData = message.businessData ?? {};
    final projectName = businessData['projectName'] as String?;
    final milestones = businessData['milestones'] as List?;
    final milestoneCount = milestones?.length ?? 0;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimelineDetailScreen(message: message),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.teal[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.isFromMe ? Colors.teal[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isFromMe
                      ? Colors.teal[700]
                      : Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: message.isFromMe ? Colors.white : Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Timeline dự án',
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (projectName != null) ...[
                      Text(
                        projectName,
                        style: TextStyle(
                          color: message.isFromMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '$milestoneCount mốc thời gian',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: message.isFromMe ? Colors.white70 : Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nhấn để xem chi tiết',
                          style: TextStyle(
                            color: message.isFromMe ? Colors.white70 : Colors.blue[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentMessage() {
    final businessData = message.businessData ?? {};
    final isConfirmed = message.type == MessageType.appointmentConfirm;
    final requestedDate = businessData['requestedDate'] as int?;
    final confirmedDate = businessData['confirmedDate'] as int?;
    final location = businessData['location'] as String?;
    final purpose = businessData['purpose'] as String?;

    final date = requestedDate != null
        ? DateTime.fromMillisecondsSinceEpoch(requestedDate)
        : confirmedDate != null
            ? DateTime.fromMillisecondsSinceEpoch(confirmedDate)
            : null;

    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isFromMe
              ? (isConfirmed ? Colors.green[600] : Colors.blue[600])
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: message.isFromMe
                ? (isConfirmed ? Colors.green[700]! : Colors.blue[700]!)
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromMe
                    ? (isConfirmed ? Colors.green[700] : Colors.blue[700])
                    : Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isConfirmed ? Icons.check_circle : Icons.calendar_today,
                    color: message.isFromMe ? Colors.white : Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isConfirmed ? 'Xác nhận hẹn gặp' : 'Yêu cầu hẹn gặp',
                      style: TextStyle(
                        color: message.isFromMe ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null) ...[
                    _buildInfoRow('Thời gian', _formatDateTime(date)),
                    const SizedBox(height: 8),
                  ],
                  if (location != null) ...[
                    _buildInfoRow('Địa điểm', location),
                    const SizedBox(height: 8),
                  ],
                  if (purpose != null) ...[
                    _buildInfoRow('Mục đích', purpose),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              color: message.isFromMe ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: message.isFromMe ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
