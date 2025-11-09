import 'package:flutter/material.dart';
import '../../models/chat_model.dart';

class PortfolioGalleryScreen extends StatelessWidget {
  final Message message;

  const PortfolioGalleryScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final businessData = message.businessData ?? {};
    final imageUrls = (businessData['imageUrls'] as List?)?.cast<String>() ?? [];
    final projectTitle = businessData['projectTitle'] as String?;
    final projectDescription = businessData['projectDescription'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(projectTitle ?? 'Portfolio'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: imageUrls.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có hình ảnh',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (projectTitle != null || projectDescription != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.purple[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (projectTitle != null) ...[
                          Text(
                            projectTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (projectDescription != null)
                          Text(
                            projectDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple[800],
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = imageUrls[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _FullScreenImageViewer(
                                imageUrls: imageUrls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
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
                                color: Colors.grey[300],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Không thể tải ảnh',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.white),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

