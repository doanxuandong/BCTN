import 'package:flutter/material.dart';
import '../../models/chat_model.dart';

class TimelineDetailScreen extends StatelessWidget {
  final Message message;

  const TimelineDetailScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final businessData = message.businessData ?? {};
    final projectName = businessData['projectName'] as String?;
    final milestones = (businessData['milestones'] as List?) ?? [];
    final expectedStartDate = businessData['expectedStartDate'] as int?;
    final expectedEndDate = businessData['expectedEndDate'] as int?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline dự án'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Info Card
            Card(
              color: Colors.teal[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (projectName != null) ...[
                      Text(
                        projectName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (expectedStartDate != null && expectedEndDate != null) ...[
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.teal[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Từ ${_formatDate(DateTime.fromMillisecondsSinceEpoch(expectedStartDate))} đến ${_formatDate(DateTime.fromMillisecondsSinceEpoch(expectedEndDate))}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.teal[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (expectedStartDate != null) ...[
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.teal[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Bắt đầu: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(expectedStartDate))}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.teal[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Milestones
            Text(
              'Các mốc thời gian (${milestones.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
            const SizedBox(height: 16),
            if (milestones.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Chưa có mốc thời gian nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...milestones.asMap().entries.map((entry) {
                final index = entry.key;
                final milestone = entry.value as Map<String, dynamic>;
                final name = milestone['name'] as String? ?? 'Mốc ${index + 1}';
                final date = milestone['date'] as int?;
                final description = milestone['description'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[100],
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(DateTime.fromMillisecondsSinceEpoch(date)),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

