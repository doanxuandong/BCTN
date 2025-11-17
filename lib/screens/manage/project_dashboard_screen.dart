import 'package:flutter/material.dart';
import '../../models/project_pipeline.dart';
import '../../services/project/pipeline_service.dart';
import '../../services/project/completed_project_service.dart';
import '../../services/manage/transaction_service.dart';
import '../../services/user/user_session.dart';
import '../chat/chat_detail_screen.dart';
import 'create_project_screen.dart';
import 'project_transactions_screen.dart';
import 'project_materials_screen.dart';

class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  List<ProjectPipeline> _pipelines = [];
  bool _isLoading = true;
  String? _currentUserId; // Cache current user ID để kiểm tra owner
  // Phase 6 Enhancement: Cache project costs để tránh tính toán lại nhiều lần
  Map<String, double> _projectCosts = {}; // projectId -> totalCost

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadPipelines();
  }

  Future<void> _loadCurrentUserId() async {
    final currentUser = await UserSession.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser['userId']?.toString();
      });
    }
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
      
      // Phase 6 Enhancement: Load project costs for budget warnings
      final projectCosts = <String, double>{};
      for (var pipeline in pipelines) {
        // Chỉ tính cost nếu có materialsBudget
        if (pipeline.materialsBudget != null && pipeline.materialsBudget! > 0) {
          try {
            final totalCost = await TransactionService.getProjectTotalCost(pipeline.id);
            projectCosts[pipeline.id] = totalCost;
            print('  - Project ${pipeline.projectName}: Total cost = ${totalCost.toStringAsFixed(0)}, Budget = ${pipeline.materialsBudget}');
          } catch (e) {
            print('⚠️ Error calculating cost for project ${pipeline.id}: $e');
          }
        }
      }
      
      setState(() {
        _pipelines = pipelines;
        _projectCosts = projectCosts;
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
            icon: const Icon(Icons.add),
            onPressed: () async {
              final projectId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProjectScreen(),
                ),
              );
              
              // Reload pipelines sau khi tạo dự án mới
              if (projectId != null && mounted) {
                await _loadPipelines();
              }
            },
            tooltip: 'Tạo dự án mới',
          ),
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
            'Tạo dự án mới để bắt đầu quản lý',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final projectId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProjectScreen(),
                ),
              );
              
              // Reload pipelines sau khi tạo dự án mới
              if (projectId != null && mounted) {
                await _loadPipelines();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo dự án mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
              const SizedBox(height: 16),
              // Phase 6 Enhancement: Budget warning
              _buildBudgetWarning(pipeline),
              const SizedBox(height: 16),
              // Phase 7 Enhancement: Button to view project materials
              _buildViewMaterialsButton(pipeline),
              const SizedBox(height: 12),
              // Phase 4 Enhancement: Button to view project transactions
              _buildViewTransactionsButton(pipeline),
            ],
          ),
        ),
      ),
    );
  }

  // Phase 6 Enhancement: Build budget warning widget
  Widget _buildBudgetWarning(ProjectPipeline pipeline) {
    // Chỉ hiển thị cảnh báo nếu có materialsBudget
    if (pipeline.materialsBudget == null || pipeline.materialsBudget! <= 0) {
      return const SizedBox.shrink();
    }

    final totalCost = _projectCosts[pipeline.id] ?? 0;
    final budget = pipeline.materialsBudget!;
    final percentage = budget > 0 ? (totalCost / budget) * 100 : 0;
    final isOverBudget = totalCost > budget;

    // Chỉ hiển thị cảnh báo nếu vượt quá 80% ngân sách hoặc vượt quá ngân sách
    if (percentage < 80 && !isOverBudget) {
      return const SizedBox.shrink();
    }

    Color warningColor;
    IconData warningIcon;
    String warningText;

    if (isOverBudget) {
      warningColor = Colors.red;
      warningIcon = Icons.warning;
      warningText = '⚠️ VƯỢT QUÁ NGÂN SÁCH!';
    } else if (percentage >= 90) {
      warningColor = Colors.orange;
      warningIcon = Icons.warning_amber;
      warningText = '⚠️ GẦN VƯỢT NGÂN SÁCH';
    } else {
      warningColor = Colors.orange[700]!;
      warningIcon = Icons.info_outline;
      warningText = 'ℹ️ Đã sử dụng ${percentage.toStringAsFixed(1)}% ngân sách';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warningColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(warningIcon, color: warningColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warningText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: warningColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã chi: ${_formatPrice(totalCost)} / Ngân sách: ${_formatPrice(budget)}',
                  style: TextStyle(
                    color: warningColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                if (isOverBudget)
                  Text(
                    'Vượt quá: ${_formatPrice(totalCost - budget)}',
                    style: TextStyle(
                      color: warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(2)}B VNĐ';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M VNĐ';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(2)}K VNĐ';
    } else {
      return '${price.toStringAsFixed(0)} VNĐ';
    }
  }

  // Phase 7 Enhancement: Button to view project materials (for contractor/owner/store)
  Widget _buildViewMaterialsButton(ProjectPipeline pipeline) {
    // Chỉ hiển thị nếu có store (có thể có vật liệu)
    if (pipeline.storeId == null) {
      return const SizedBox.shrink();
    }
    
    // Kiểm tra xem currentUser có phải là owner, contractor, hoặc store không
    final isOwner = _currentUserId != null && pipeline.ownerId == _currentUserId;
    final isContractor = _currentUserId != null && pipeline.contractorId == _currentUserId;
    final isStore = _currentUserId != null && pipeline.storeId == _currentUserId;
    
    // Chỉ hiển thị cho owner, contractor, hoặc store
    if (!isOwner && !isContractor && !isStore) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectMaterialsScreen(project: pipeline),
            ),
          );
        },
        icon: const Icon(Icons.inventory_2),
        label: const Text('Xem vật liệu trong dự án'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.green[400]!),
        ),
      ),
    );
  }

  // Phase 4 Enhancement: Button to view project transactions (for contractor/owner)
  Widget _buildViewTransactionsButton(ProjectPipeline pipeline) {
    // Chỉ hiển thị nếu có store (có thể có transactions)
    if (pipeline.storeId == null) {
      return const SizedBox.shrink();
    }
    
    // Kiểm tra xem currentUser có phải là owner, contractor, hoặc store không
    final isOwner = _currentUserId != null && pipeline.ownerId == _currentUserId;
    final isContractor = _currentUserId != null && pipeline.contractorId == _currentUserId;
    final isStore = _currentUserId != null && pipeline.storeId == _currentUserId;
    
    // Chỉ hiển thị cho owner, contractor, hoặc store
    if (!isOwner && !isContractor && !isStore) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectTransactionsScreen(project: pipeline),
            ),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Xem giao dịch vật liệu'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.blue[400]!),
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
            pipeline,
            PipelineStage.design,
          ),
        if (pipeline.contractorName != null)
          _buildCollaboratorItem(
            'Chủ thầu',
            pipeline.contractorName!,
            pipeline.constructionStatus,
            () => _openChatWithContractor(pipeline),
            pipeline,
            PipelineStage.construction,
          ),
        if (pipeline.storeName != null)
          _buildCollaboratorItem(
            'Cửa hàng VLXD',
            pipeline.storeName!,
            pipeline.materialsStatus,
            () => _openChatWithStore(pipeline),
            pipeline,
            PipelineStage.materials,
          ),
      ],
    );
  }

  Widget _buildCollaboratorItem(
    String role,
    String name,
    CollaborationStatus status,
    VoidCallback onTap,
    ProjectPipeline pipeline,
    PipelineStage stageType, // Giai đoạn tương ứng (design, construction, materials)
  ) {
    Color statusColor;
    String statusText;
    bool canMarkComplete = false; // Chỉ owner mới được đánh dấu hoàn thành

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
        canMarkComplete = true; // Có thể đánh dấu hoàn thành
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            // Phần thông tin đối tác
            InkWell(
              onTap: onTap,
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
            // Button đánh dấu hoàn thành (chỉ hiển thị nếu đang hợp tác và là owner)
            if (canMarkComplete && _currentUserId != null && pipeline.ownerId == _currentUserId) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCompleteStageDialog(pipeline, stageType, role),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Đánh dấu hoàn thành'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    side: BorderSide(color: Colors.green[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog xác nhận đánh dấu hoàn thành giai đoạn
  Future<void> _showCompleteStageDialog(
    ProjectPipeline pipeline,
    PipelineStage stageType,
    String roleName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Expanded(child: Text('Xác nhận hoàn thành')),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đánh dấu giai đoạn "$roleName" là hoàn thành không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _completeStage(pipeline, stageType, roleName);
    }
  }

  /// Thực hiện đánh dấu hoàn thành giai đoạn
  Future<void> _completeStage(
    ProjectPipeline pipeline,
    PipelineStage stageType,
    String roleName,
  ) async {
    try {
      bool success = false;
      String? completedByUserId;
      String? completedByName;

      // Xác định người hoàn thành
      switch (stageType) {
        case PipelineStage.design:
          completedByUserId = pipeline.designerId;
          completedByName = pipeline.designerName;
          success = await PipelineService.completeDesign(
            pipelineId: pipeline.id,
            designFileUrl: pipeline.designFileUrl, // Sử dụng file URL đã có (nếu có)
          );
          break;
        case PipelineStage.construction:
          completedByUserId = pipeline.contractorId;
          completedByName = pipeline.contractorName;
          success = await PipelineService.completeConstruction(
            pipelineId: pipeline.id,
            constructionPlanUrl: pipeline.constructionPlanUrl,
          );
          break;
        case PipelineStage.materials:
          completedByUserId = pipeline.storeId;
          completedByName = pipeline.storeName;
          success = await PipelineService.completeMaterials(
            pipelineId: pipeline.id,
            quoteUrl: pipeline.materialQuoteUrl,
          );
          break;
      }

      if (!mounted) return;

      if (success) {
        // Lưu completed project vào profile của người thực hiện
        if (completedByUserId != null && completedByName != null) {
          // Reload pipeline để lấy thông tin mới nhất (completedAt, etc.)
          final updatedPipeline = await PipelineService.getPipeline(pipeline.id);
          if (updatedPipeline != null) {
            await CompletedProjectService.saveCompletedProject(
              pipeline: updatedPipeline,
              completedStage: stageType,
              completedByUserId: completedByUserId,
              completedByName: completedByName,
            );
            print('✅ Saved completed project to profile: $completedByName');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đánh dấu giai đoạn "$roleName" hoàn thành'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload pipelines
        await _loadPipelines();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi đánh dấu hoàn thành'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error completing stage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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


