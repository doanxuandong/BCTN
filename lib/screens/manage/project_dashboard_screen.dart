import 'package:flutter/material.dart';
import '../../models/project_pipeline.dart';
import '../../services/project/pipeline_service.dart';
import '../../services/user/user_session.dart';
import '../chat/chat_detail_screen.dart';

class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  List<ProjectPipeline> _pipelines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPipelines();
  }

  Future<void> _loadPipelines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pipelines = await PipelineService.getUserPipelines();
      if (!mounted) return;
      
      print('✅ Loaded ${pipelines.length} pipelines');
      for (var pipeline in pipelines) {
        print('  - Pipeline: ${pipeline.projectName}, ID: ${pipeline.id}');
        print('    Stage: ${pipeline.currentStage}');
        print('    Designer: ${pipeline.designerName ?? "null"}, Status: ${pipeline.designStatus}');
        print('    Contractor: ${pipeline.contractorName ?? "null"}, Status: ${pipeline.constructionStatus}');
        print('    Store: ${pipeline.storeName ?? "null"}, Status: ${pipeline.materialsStatus}');
        print('    OwnerId: ${pipeline.ownerId}');
      }
      
      setState(() {
        _pipelines = pipelines;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading pipelines: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      // Hiển thị lỗi cho user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dự án: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý dự án',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPipelines,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pipelines.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPipelines,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pipelines.length,
                    itemBuilder: (context, index) {
                      return _buildPipelineCard(_pipelines[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dự án nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu bằng cách tìm kiếm nhà thiết kế',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(ProjectPipeline pipeline) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPipelineDetails(pipeline),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pipeline.projectName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStageBadge(pipeline.currentStage),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusDescription(pipeline),
              const SizedBox(height: 16),
              _buildProgressIndicator(pipeline),
              const SizedBox(height: 16),
              _buildCollaborators(pipeline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageBadge(PipelineStage stage) {
    String label;
    Color color;

    switch (stage) {
      case PipelineStage.design:
        label = 'Thiết kế';
        color = Colors.purple;
        break;
      case PipelineStage.construction:
        label = 'Thi công';
        color = Colors.orange;
        break;
      case PipelineStage.materials:
        label = 'Vật liệu';
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusDescription(ProjectPipeline pipeline) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pipeline.getStatusDescription(),
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ProjectPipeline pipeline) {
    // Đếm số giai đoạn đã bắt đầu (requested, accepted, inProgress, completed)
    // và số giai đoạn đã hoàn thành
    int activeStages = 0;
    int completedStages = 0;
    
    // Kiểm tra giai đoạn thiết kế
    if (pipeline.designStatus != CollaborationStatus.none) {
      activeStages++;
      if (pipeline.designStatus == CollaborationStatus.completed) completedStages++;
    }
    
    // Kiểm tra giai đoạn thi công
    if (pipeline.constructionStatus != CollaborationStatus.none) {
      activeStages++;
      if (pipeline.constructionStatus == CollaborationStatus.completed) completedStages++;
    }
    
    // Kiểm tra giai đoạn vật liệu
    if (pipeline.materialsStatus != CollaborationStatus.none) {
      activeStages++;
      if (pipeline.materialsStatus == CollaborationStatus.completed) completedStages++;
    }

    // Tính tổng số giai đoạn có thể có (tối đa 3)
    final totalPossibleStages = 3;
    
    // Hiển thị: "X/3 giai đoạn" với X là số giai đoạn đã hoàn thành
    // Hoặc có thể hiển thị: "Đang thực hiện: X/3" và "Hoàn thành: Y/3"

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tiến độ dự án',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '$completedStages/$totalPossibleStages giai đoạn đã hoàn thành',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (activeStages > 0 && activeStages != completedStages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Đang thực hiện: $activeStages giai đoạn',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        LinearProgressIndicator(
          value: completedStages / totalPossibleStages,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
        ),
      ],
    );
  }

  Widget _buildCollaborators(ProjectPipeline pipeline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đối tác',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (pipeline.designerName != null)
          _buildCollaboratorItem(
            'Nhà thiết kế',
            pipeline.designerName!,
            pipeline.designStatus,
            () => _openChatWithDesigner(pipeline),
          ),
        if (pipeline.contractorName != null)
          _buildCollaboratorItem(
            'Chủ thầu',
            pipeline.contractorName!,
            pipeline.constructionStatus,
            () => _openChatWithContractor(pipeline),
          ),
        if (pipeline.storeName != null)
          _buildCollaboratorItem(
            'Cửa hàng VLXD',
            pipeline.storeName!,
            pipeline.materialsStatus,
            () => _openChatWithStore(pipeline),
          ),
      ],
    );
  }

  Widget _buildCollaboratorItem(
    String role,
    String name,
    CollaborationStatus status,
    VoidCallback onTap,
  ) {
    Color statusColor;
    String statusText;

    switch (status) {
      case CollaborationStatus.none:
        statusColor = Colors.grey;
        statusText = 'Chưa hợp tác';
        break;
      case CollaborationStatus.requested:
        statusColor = Colors.orange;
        statusText = 'Đã yêu cầu';
        break;
      case CollaborationStatus.accepted:
      case CollaborationStatus.inProgress:
        statusColor = Colors.green;
        statusText = 'Đang hợp tác';
        break;
      case CollaborationStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Đã hoàn thành';
        break;
      case CollaborationStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChatWithDesigner(ProjectPipeline pipeline) async {
    if (pipeline.designerId == null) return;
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser == null) return;

    final userId = currentUser['userId']?.toString();
    if (userId == null) return;

    final participants = [userId, pipeline.designerId!]..sort();
    final chatId = participants.join('_');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatId: chatId),
      ),
    );
  }

  Future<void> _openChatWithContractor(ProjectPipeline pipeline) async {
    if (pipeline.contractorId == null) return;
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser == null) return;

    final userId = currentUser['userId']?.toString();
    if (userId == null) return;

    final participants = [userId, pipeline.contractorId!]..sort();
    final chatId = participants.join('_');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatId: chatId),
      ),
    );
  }

  Future<void> _openChatWithStore(ProjectPipeline pipeline) async {
    if (pipeline.storeId == null) return;
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser == null) return;

    final userId = currentUser['userId']?.toString();
    if (userId == null) return;

    final participants = [userId, pipeline.storeId!]..sort();
    final chatId = participants.join('_');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatId: chatId),
      ),
    );
  }

  void _showPipelineDetails(ProjectPipeline pipeline) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pipeline.projectName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giai đoạn hiện tại: ${_getStageName(pipeline.currentStage)}'),
              const SizedBox(height: 16),
              Text('Trạng thái: ${pipeline.getStatusDescription()}'),
              if (pipeline.designerName != null) ...[
                const SizedBox(height: 16),
                Text('Nhà thiết kế: ${pipeline.designerName}'),
                Text('Trạng thái: ${_getStatusName(pipeline.designStatus)}'),
              ],
              if (pipeline.contractorName != null) ...[
                const SizedBox(height: 16),
                Text('Chủ thầu: ${pipeline.contractorName}'),
                Text('Trạng thái: ${_getStatusName(pipeline.constructionStatus)}'),
              ],
              if (pipeline.storeName != null) ...[
                const SizedBox(height: 16),
                Text('Cửa hàng VLXD: ${pipeline.storeName}'),
                Text('Trạng thái: ${_getStatusName(pipeline.materialsStatus)}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _getStageName(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.design:
        return 'Thiết kế';
      case PipelineStage.construction:
        return 'Thi công';
      case PipelineStage.materials:
        return 'Vật liệu';
    }
  }

  String _getStatusName(CollaborationStatus status) {
    switch (status) {
      case CollaborationStatus.none:
        return 'Chưa hợp tác';
      case CollaborationStatus.requested:
        return 'Đã yêu cầu';
      case CollaborationStatus.accepted:
        return 'Đã chấp nhận';
      case CollaborationStatus.inProgress:
        return 'Đang hợp tác';
      case CollaborationStatus.completed:
        return 'Đã hoàn thành';
      case CollaborationStatus.cancelled:
        return 'Đã hủy';
    }
  }
}


