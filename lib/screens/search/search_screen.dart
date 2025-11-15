import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/search_models.dart';
import '../../constants/vn_provinces.dart';
import '../../models/user_profile.dart';
import '../../components/account_card.dart';
import '../../services/search/search_notification_service.dart';
import '../../services/user/user_profile_service.dart';
import '../../services/location/location_service.dart';
import '../../utils/migrate_user_profiles.dart';
import '../../utils/province_coordinates.dart';
import 'search_results_screen.dart';
import 'search_notifications_screen.dart';
import 'smart_search_screen.dart';
import '../profile/public_profile_screen.dart';
import '../../services/friends/friends_service.dart';
import '../../services/user/user_session.dart';
import '../../services/project/pipeline_service.dart';
import '../../models/project_pipeline.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabIndex = 0;
  AccountType _selectedType = AccountType.designer;
  double _radiusKm = 10;
  bool _enableRadius = false;
  Province? _selectedProvince;
  Region? _selectedRegion;
  final Set<Specialty> _selectedSpecialties = {};
  String _keyword = '';
  String _customSpecialties = ''; // Chuyên ngành tự nhập
  late TextEditingController _specialtiesController;
  final Set<Specialty> _selectedCustomSpecialties = {}; // Chuyên ngành đã chọn

  // Bộ lọc riêng cho nhà thiết kế
  String? _selectedDesignStyle;
  String? _selectedPriceRange;

  // Bộ lọc riêng cho chủ thầu
  String? _selectedLicense;
  String? _selectedProjectCapacity;

  // Bộ lọc riêng cho cửa hàng VLXD
  String? _selectedBusinessType;
  bool _hasDelivery = false;
  bool _hasWarranty = false;

  List<SearchAccount> _results = [];
  List<UserProfile> _realUsers = []; // Dữ liệu thật từ Firebase
  bool _showFilters = true; // Điều khiển hiển thị bộ lọc
  int _unreadNotificationsCount = 0;
  bool _isLoadingRealUsers = false;
  final Map<String, bool> _friendRequestsPending = {}; // userId -> true nếu đã gửi
  double? _cachedUserLat; // Cache user location để tránh gọi location service nhiều lần
  double? _cachedUserLng;
  
  // Phase 1: Project selection
  List<ProjectPipeline> _userProjects = []; // Danh sách dự án của user
  String? _selectedProjectId; // Dự án đã chọn khi tìm kiếm

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _selectedProvince = null;
    _selectedRegion = null;
    _specialtiesController = TextEditingController(text: _customSpecialties);
    _listenToNotifications();
    
    // Phase 1: Load user projects
    _loadUserProjects();
    
    // FIX ANR: Chỉ load users, KHÔNG gọi location service ngay
    // Location sẽ chỉ được gọi khi user thực sự cần (click search button hoặc sau khi screen ổn định)
    _loadRealUsersWithoutLocation();
    
    // FIX ANR: KHÔNG gọi location service ngay trong initState
    // Location sẽ được load sau khi UI đã render hoàn toàn (delay lâu hơn)
    // HOẶC chỉ load khi user click "Tìm kiếm"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay rất lâu (5 giây) để đảm bảo UI đã hoàn toàn render và ổn định
      // Điều này cho phép user xem kết quả trước, location sẽ được load ở background
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _realUsers.isNotEmpty && (_cachedUserLat == null || _cachedUserLng == null)) {
          print('📍 Background: Loading location after UI is stable...');
          _loadLocationAsync();
        }
      });
    });
  }
  
  /// Phase 1: Load user projects (chỉ load projects của owner)
  Future<void> _loadUserProjects() async {
    try {
      final projects = await PipelineService.getUserPipelines();
      final currentUser = await UserSession.getCurrentUser();
      if (currentUser == null) return;
      
      final userId = currentUser['userId']?.toString();
      if (userId == null) return;
      
      if (mounted) {
        setState(() {
          // Chỉ lấy projects mà user là owner
          _userProjects = projects.where((p) => p.ownerId == userId).toList();
        });
      }
    } catch (e) {
      print('❌ Error loading user projects: $e');
    }
  }

  /// Load users mà không cần location (để tránh ANR)
  Future<void> _loadRealUsersWithoutLocation() async {
    setState(() {
      _isLoadingRealUsers = true;
    });

    try {
      print('Loading real users from Firebase (without location)...');
      
      // Lấy tất cả user profiles có thể tìm kiếm (không tính distance)
      final users = await UserProfileService.searchProfiles();
      
      print('Loaded ${users.length} real users from Firebase');
      
      setState(() {
        _realUsers = users;
        _isLoadingRealUsers = false;
      });
      
      // Convert users to search accounts (không có distance, sẽ tính sau)
      if (mounted) {
        _updateResultsWithoutDistance();
      }
    } catch (e) {
      print('Error loading real users: $e');
      setState(() {
        _isLoadingRealUsers = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Update results mà không tính distance (để tránh ANR)
  /// Hiển thị users ngay, distance sẽ được tính sau khi có location
  void _updateResultsWithoutDistance() {
    if (_realUsers.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }
    
    // Filter users theo type
    final filteredUsers = _realUsers.where((user) {
      switch (_selectedType) {
        case AccountType.designer:
          return user.accountType == UserAccountType.designer;
        case AccountType.contractor:
          return user.accountType == UserAccountType.contractor;
        case AccountType.store:
          return user.accountType == UserAccountType.store;
      }
    }).toList();
    
    // Convert to SearchAccount (không tính distance, set -1.0)
    final results = filteredUsers.map((user) {
      // Map UserAccountType sang AccountType
      AccountType accountType;
      switch (user.accountType) {
        case UserAccountType.designer:
          accountType = AccountType.designer;
          break;
        case UserAccountType.contractor:
          accountType = AccountType.contractor;
          break;
        case UserAccountType.store:
          accountType = AccountType.store;
          break;
        case UserAccountType.general:
          // Bỏ qua tài khoản general
          return null;
      }

      // Map province
      Province province = user.province.isNotEmpty
          ? Province(code: user.province, name: user.province, region: Region.central)
          : Province(code: 'TP. Hồ Chí Minh', name: 'TP. Hồ Chí Minh', region: Region.south);

      // Map specialties
      List<Specialty> specialties = user.specialties.map((s) {
        return SearchData.specialties.firstWhere(
          (sp) => sp.name.toLowerCase().contains(s.toLowerCase()) || s.toLowerCase().contains(sp.name.toLowerCase()),
          orElse: () => SearchData.specialties.first,
        );
      }).toList();

      // Tính khoảng cách: -1.0 = chưa có, sẽ tính sau
      double distance = -1.0;

      return SearchAccount(
        id: user.id,
        name: user.name,
        type: accountType,
        address: user.address.isNotEmpty ? user.address : user.location,
        province: province,
        specialties: specialties.isNotEmpty ? specialties : [SearchData.specialties.first],
        rating: user.rating,
        reviewCount: user.reviewCount,
        distanceKm: distance, // Chưa có distance, sẽ tính sau
        avatarUrl: user.displayAvatar,
        additionalInfo: user.additionalInfo,
      );
    }).where((account) => account != null).cast<SearchAccount>().toList();
    
    setState(() {
      _results = results;
    });
    
    print('✅ Updated results without distance: ${results.length} accounts');
  }
  
  /// Load location async (không block main thread)
  /// FIX ANR: Chỉ dùng cached location, KHÔNG request GPS mới
  Future<void> _loadLocationAsync() async {
    try {
      print('📍 Loading user location (async, non-blocking, cached only)...');
      
      // FIX ANR: CHỈ dùng cached location (getLastKnownPosition - không block)
      // KHÔNG gọi getCurrentLocation để tránh block main thread
      try {
        final lastKnown = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 2), // Timeout ngắn để không block
          onTimeout: () {
            print('⏱️ getLastKnownPosition timeout');
            return null;
          },
        );
        
        if (lastKnown != null && LocationService.isValidLocation(
            lastKnown.latitude, lastKnown.longitude)) {
          print('✅ Using cached location: (${lastKnown.latitude}, ${lastKnown.longitude})');
          // Apply filters với cached location
          await _applyFiltersWithLocation(
            lastKnown.latitude, 
            lastKnown.longitude,
          );
          return;
        }
      } catch (e) {
        print('⚠️ Error getting cached location: $e');
      }
      
      // FIX ANR: Nếu không có cached, dùng default location ngay (KHÔNG request GPS mới)
      print('⚠️ No cached location, using default location (TP.HCM)');
      await _applyFiltersWithLocation(10.8231, 106.6297);
    } catch (e) {
      print('❌ Error loading location: $e');
      // Dùng default location nếu có lỗi
      await _applyFiltersWithLocation(10.8231, 106.6297);
    }
  }
  
  /// Apply filters với location cụ thể
  Future<void> _applyFiltersWithLocation(double userLat, double userLng) async {
    if (!mounted) return;
    
    // Cache location để dùng cho các lần filter sau (tránh gọi location service)
    _cachedUserLat = userLat;
    _cachedUserLng = userLng;
    
    // Convert users với location
    final results = _convertUserProfilesToSearchAccounts(
      _realUsers, 
      userLat, 
      userLng,
    );
    
    if (mounted) {
      setState(() {
        _results = results;
        _isLoadingRealUsers = false;
      });
    }
  }
  
  void _initializeTabController() {
    _tabController?.dispose(); // Dispose nếu đã tồn tại (trong trường hợp hot reload)
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _specialtiesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Khi quay lại màn hình tìm kiếm, tải lại dữ liệu để cập nhật account mới đăng ký
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadRealUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nếu TabController chưa được khởi tạo (trường hợp hot reload), khởi tạo ngay
    _tabController ??= TabController(length: 2, vsync: this, initialIndex: _currentTabIndex)
      ..addListener(_handleTabChange);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController!,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Tìm kiếm',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Tìm kiếm thông minh',
            ),
          ],
        ),
        actions: [
          // Chỉ hiển thị actions ở tab 0 (tìm kiếm thông thường)
          if (_currentTabIndex == 0) ...[
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _openNotifications,
                tooltip: 'Thông báo tìm kiếm',
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: _showFilters ? 'Ẩn bộ lọc' : 'Hiện bộ lọc',
          ),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            tooltip: 'Đặt lại',
          ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          // Tab 1: Tìm kiếm thông thường
          _buildNormalSearch(),
          // Tab 2: Tìm kiếm thông minh
          const SmartSearchScreen(),
        ],
      ),
    );
  }

  /// Tab 1: Tìm kiếm thông thường (SearchScreen hiện tại)
  Widget _buildNormalSearch() {
    return RefreshIndicator(
        onRefresh: () async {
          await _loadRealUsers();
        },
        child: Column(
          children: [
            // Phase 1: Banner hiển thị dự án đã chọn
            if (_selectedProjectId != null) _buildProjectBanner(),
            _buildTypeSelector(),
            if (_showFilters) ...[
              Flexible(
                child: SingleChildScrollView(
                  child: _buildFilters(),
                ),
              ),
            ],
            _buildKeywordBar(),
            const SizedBox(height: 8),
            _buildResultHeader(),
            Expanded(child: _buildResults()),
          ],
      ),
    );
  }

  /// Phase 1: Build banner hiển thị dự án đã chọn
  Widget _buildProjectBanner() {
    final selectedProject = _userProjects.firstWhere(
      (p) => p.id == _selectedProjectId,
      orElse: () => _userProjects.first,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_special, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang tìm kiếm cho:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedProject.projectName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.blue[700], size: 20),
            onPressed: () {
              setState(() {
                _selectedProjectId = null;
              });
            },
            tooltip: 'Bỏ chọn dự án',
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _typeChip(AccountType.designer, 'Nhà thiết kế', Icons.design_services),
            const SizedBox(width: 8),
            _typeChip(AccountType.contractor, 'Chủ thầu', Icons.engineering),
            const SizedBox(width: 8),
            _typeChip(AccountType.store, 'Cửa hàng VLXD', Icons.storefront),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(AccountType type, String label, IconData icon) {
    final bool selected = _selectedType == type;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.blue),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) async {
        setState(() {
          _selectedType = type;
        });
        await _applyFilters();
      },
      selectedColor: Colors.blue[600],
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.blue[800]),
    );
  }

  Widget _buildFilters() {
    return Container(
      key: const ValueKey('filters'),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phase 1: Project selection dropdown
          _buildProjectSelector(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildProvinceDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildRegionDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _enableRadius,
                  onChanged: (v) async {
                    setState(() {
                      _enableRadius = v;
                    });
                    await _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 2),
              const Text('Lọc theo bán kính'),
              const SizedBox(width: 6),
              Expanded(
                child: Opacity(
                  opacity: _enableRadius ? 1.0 : 0.4,
                  child: IgnorePointer(
                    ignoring: !_enableRadius,
                    child: Slider(
                      min: 1,
                      max: 100,
                      divisions: 99,
                      value: _radiusKm,
                      label: '${_radiusKm.toStringAsFixed(0)} km',
                      onChanged: (v) {
                        setState(() {
                          _radiusKm = v;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text('${_radiusKm.toStringAsFixed(0)} km', textAlign: TextAlign.right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSpecialtiesSelector(),
          const SizedBox(height: 12),
          _buildTypeSpecificFilters(),
        ],
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    // Build items from full VN provinces list
    final provinceItems = vnProvinces
        .map((name) => Province(code: name, name: name, region: Region.south))
        .toList();

    // Make sure currently selected value exists within items to avoid assertion
    final Province? selected = _selectedProvince == null
        ? null
        : provinceItems.firstWhere(
            (p) => p.name == _selectedProvince!.name,
            orElse: () => provinceItems.first,
          );

    return DropdownButtonFormField<Province?>(
      value: _selectedProvince == null ? null : selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tỉnh/Thành',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_city),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        ...provinceItems.map((item) => DropdownMenuItem(value: item, child: Text(item.name))),
      ],
      onChanged: (v) {
        setState(() {
          _selectedProvince = v;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildRegionDropdown() {
    final items = <DropdownMenuItem<Region?>>[
      const DropdownMenuItem(value: null, child: Text('Tất cả miền')),
      const DropdownMenuItem(value: Region.north, child: Text('Miền Bắc')),
      const DropdownMenuItem(value: Region.central, child: Text('Miền Trung')),
      const DropdownMenuItem(value: Region.south, child: Text('Miền Nam')),
    ];

    return DropdownButtonFormField<Region?>(
      value: _selectedRegion,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Miền',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.public),
      ),
      items: items,
      onChanged: (v) {
        setState(() {
          _selectedRegion = v;
          _applyFilters();
        });
      },
    );
  }

  /// Phase 1: Build project selector dropdown
  Widget _buildProjectSelector() {
    return DropdownButtonFormField<String?>(
      value: _selectedProjectId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Chọn dự án (tùy chọn)',
        hintText: 'Tìm kiếm chung',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.folder_special),
        helperText: 'Chọn dự án để liên kết với kết quả tìm kiếm',
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Tìm kiếm chung (không chọn dự án)'),
        ),
        ..._userProjects.map((project) {
          return DropdownMenuItem(
            value: project.id,
            child: Text(
              project.projectName,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (v) {
        setState(() {
          _selectedProjectId = v;
        });
      },
    );
  }

  Widget _buildSpecialtiesSelector() {
    final availableSpecialties = SearchData.specialties
        .where((s) => s.type == _selectedType && !_selectedCustomSpecialties.contains(s))
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<Specialty>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return availableSpecialties;
            }
            return availableSpecialties.where((specialty) =>
                specialty.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (Specialty specialty) => specialty.name,
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Chọn chuyên ngành',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                helperText: 'Gõ để tìm chuyên ngành',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                // Tìm và thêm chuyên ngành nếu có
                try {
                  final found = availableSpecialties.firstWhere(
                    (s) => s.name.toLowerCase() == value.toLowerCase(),
                  );
                  setState(() {
                    _selectedCustomSpecialties.add(found);
                    textEditingController.clear();
                  });
                } catch (e) {
                  // Không tìm thấy chuyên ngành phù hợp
                  textEditingController.clear();
                }
              },
            );
          },
          onSelected: (Specialty selectedSpecialty) {
            setState(() {
              _selectedCustomSpecialties.add(selectedSpecialty);
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final specialty = options.elementAt(index);
                      return ListTile(
                        title: Text(specialty.name),
                        onTap: () {
                          onSelected(specialty);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (_selectedCustomSpecialties.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Chuyên ngành đã chọn:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCustomSpecialties.map((specialty) {
                return Chip(
                  label: Text(
                    specialty.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedCustomSpecialties.remove(specialty);
                    });
                  },
                  backgroundColor: Colors.blue[100],
                  deleteIconColor: Colors.blue[700],
                  labelStyle: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSpecificFilters() {
    switch (_selectedType) {
      case AccountType.designer:
        return _buildDesignerFilters();
      case AccountType.contractor:
        return _buildContractorFilters();
      case AccountType.store:
        return _buildStoreFilters();
    }
  }

  Widget _buildDesignerFilters() {
    return Column(
      children: [
        DropdownButtonFormField<String?>(
          value: _selectedDesignStyle,
          decoration: const InputDecoration(
            labelText: 'Phong cách thiết kế',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Tất cả')),
            DropdownMenuItem(value: 'Hiện đại', child: Text('Hiện đại')),
            DropdownMenuItem(value: 'Xanh & Bền vững', child: Text('Xanh & Bền vững')),
            DropdownMenuItem(value: '3D & Hiện đại', child: Text('3D & Hiện đại')),
          ],
          onChanged: (v) {
            setState(() {
              _selectedDesignStyle = v;
              _applyFilters();
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _selectedPriceRange,
          decoration: const InputDecoration(
            labelText: 'Khoảng giá',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Tất cả')),
            DropdownMenuItem(value: '5-30 triệu', child: Text('5-30 triệu')),
            DropdownMenuItem(value: '10-50 triệu', child: Text('10-50 triệu')),
            DropdownMenuItem(value: '20-80 triệu', child: Text('20-80 triệu')),
          ],
          onChanged: (v) {
            setState(() {
              _selectedPriceRange = v;
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildContractorFilters() {
    return Column(
      children: [
        DropdownButtonFormField<String?>(
          value: _selectedLicense,
          decoration: const InputDecoration(
            labelText: 'Cấp phép',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.verified),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Tất cả')),
            DropdownMenuItem(value: 'A1', child: Text('A1 - Hạng cao nhất')),
            DropdownMenuItem(value: 'A2', child: Text('A2 - Hạng trung bình')),
          ],
          onChanged: (v) {
            setState(() {
              _selectedLicense = v;
              _applyFilters();
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _selectedProjectCapacity,
          decoration: const InputDecoration(
            labelText: 'Quy mô dự án',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Tất cả')),
            DropdownMenuItem(value: 'Lớn', child: Text('Lớn')),
            DropdownMenuItem(value: 'Trung bình', child: Text('Trung bình')),
          ],
          onChanged: (v) {
            setState(() {
              _selectedProjectCapacity = v;
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildStoreFilters() {
    return Column(
      children: [
        DropdownButtonFormField<String?>(
          value: _selectedBusinessType,
          decoration: const InputDecoration(
            labelText: 'Loại hình',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Tất cả')),
            DropdownMenuItem(value: 'Bán buôn & Bán lẻ', child: Text('Bán buôn & Bán lẻ')),
            DropdownMenuItem(value: 'Chuyên thép', child: Text('Chuyên thép')),
            DropdownMenuItem(value: 'Chuyên gạch men', child: Text('Chuyên gạch men')),
          ],
          onChanged: (v) {
            setState(() {
              _selectedBusinessType = v;
              _applyFilters();
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Giao hàng', style: TextStyle(fontSize: 12)),
                value: _hasDelivery,
                onChanged: (v) {
                  setState(() {
                    _hasDelivery = v ?? false;
                    _applyFilters();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Bảo hành', style: TextStyle(fontSize: 12)),
                value: _hasWarranty,
                onChanged: (v) {
                  setState(() {
                    _hasWarranty = v ?? false;
                    _applyFilters();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeywordBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, địa chỉ, chuyên ngành...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _keyword.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _keyword = '';
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 20),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) {
              setState(() {
                _keyword = v;
              });
            },
            onSubmitted: (value) {
              setState(() {
                _keyword = value;
                _applyFilters();
                // Ẩn bộ lọc sau khi tìm kiếm
                _showFilters = false;
              });
            },
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _performRealTimeSearch();
                // Ẩn bộ lọc sau khi tìm kiếm
                setState(() {
                  _showFilters = false;
                });
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Tìm kiếm thực', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text(
            'Kết quả',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text('(${_results.length})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                if (v == 'near') {
                  _results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
                } else if (v == 'rate') {
                  _results.sort((b, a) => a.rating.compareTo(b.rating));
                } else if (v == 'review') {
                  _results.sort((b, a) => a.reviewCount.compareTo(b.reviewCount));
                }
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'near', child: Text('Gần nhất')),
              PopupMenuItem(value: 'rate', child: Text('Đánh giá cao')),
              PopupMenuItem(value: 'review', child: Text('Nhiều đánh giá')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.sort, size: 16),
                SizedBox(width: 4),
                Text('Sắp xếp', style: TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text('Không tìm thấy kết quả phù hợp'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final acc = _results[index];
        final isRequested = _friendRequestsPending[acc.id] == true;

        return AccountCard(
          account: acc,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PublicProfileScreen(userId: acc.id),
              ),
            );
          },
          onSendFriendRequest: () async {
            final currentUser = await UserSession.getCurrentUser();
            if (currentUser == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn cần đăng nhập!')));
              }
              return;
            }
            final myId = currentUser['userId']?.toString();
            final toId = acc.id;
            if (myId == null || myId == toId) return;
            
            setState(() {
              _friendRequestsPending[toId] = true;
            });

            final result = await FriendsService().sendFriendRequest(myId, toId);
            setState(() {
              _friendRequestsPending[toId] = result;
            });
            if (mounted && result) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã gửi lời mời kết bạn cho ${acc.name}!'),
                  backgroundColor: Colors.green,
                )
              );
            } else if (mounted && !result) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã gửi rồi hoặc có lỗi!'),
                  backgroundColor: Colors.orange,
                )
              );
            }
          },
          isFriendRequestPending: isRequested,
        );
      },
    );
  }

  Future<void> _applyFilters() async {
    // Hiển thị loading indicator
    if (mounted) {
      setState(() {
        _isLoadingRealUsers = true;
      });
    }

    try {
      // FIX ANR: KHÔNG gọi location service trong _applyFilters()
      // Dùng location đã cache hoặc default location
      double userLat;
      double userLng;
      
      if (_cachedUserLat != null && _cachedUserLng != null) {
        // Dùng location đã cache (từ _loadLocationAsync)
        userLat = _cachedUserLat!;
        userLng = _cachedUserLng!;
        print('✅ _applyFilters: Dùng cached location: ($userLat, $userLng)');
    } else {
        // Chưa có cached location, dùng default (TP.HCM)
        userLat = 10.8231;
        userLng = 106.6297;
        print('⚠️ _applyFilters: Chưa có cached location, dùng default (TP.HCM)');
      }

      // TỐI ƯU: Chuyển việc convert sang isolate/compute để không block UI thread
      // Tạm thời vẫn chạy trên main thread nhưng đã tối ưu trong _convertUserProfilesToSearchAccounts
      var data = _realUsers.isNotEmpty 
          ? _convertUserProfilesToSearchAccounts(_realUsers, userLat, userLng) 
          : SearchData.accounts;
      
      print('📊 Processing ${data.length} search accounts');

    data = data.where((a) => a.type == _selectedType).toList();

    // Province
    if (_selectedProvince != null) {
      data = data.where((a) => a.province.code == _selectedProvince!.code).toList();
    }

    // Region
    if (_selectedRegion != null) {
      data = data.where((a) => a.province.region == _selectedRegion!).toList();
    }

    // Radius (chỉ áp dụng khi bật)
    if (_enableRadius) {
      data = data.where((a) => a.distanceKm <= _radiusKm).toList();
    }

    // Specialties - xử lý chuyên ngành đã chọn
    if (_selectedCustomSpecialties.isNotEmpty) {
      data = data.where((a) => 
        a.specialties.any((s) => _selectedCustomSpecialties.contains(s))
      ).toList();
    }

    // Type-specific filters
    switch (_selectedType) {
      case AccountType.designer:
        if (_selectedDesignStyle != null) {
          data = data.where((a) => a.additionalInfo['design_style'] == _selectedDesignStyle).toList();
        }
        if (_selectedPriceRange != null) {
          data = data.where((a) => a.additionalInfo['price_range'] == _selectedPriceRange).toList();
        }
        break;
      case AccountType.contractor:
        if (_selectedLicense != null) {
          data = data.where((a) => a.additionalInfo['license'] == _selectedLicense).toList();
        }
        if (_selectedProjectCapacity != null) {
          data = data.where((a) => a.additionalInfo['project_capacity'] == _selectedProjectCapacity).toList();
        }
        break;
      case AccountType.store:
        if (_selectedBusinessType != null) {
          data = data.where((a) => a.additionalInfo['business_type'] == _selectedBusinessType).toList();
        }
        if (_hasDelivery) {
          data = data.where((a) => a.additionalInfo['delivery'] != 'Không giao hàng').toList();
        }
        if (_hasWarranty) {
          data = data.where((a) => a.additionalInfo['warranty'] != 'Không bảo hành').toList();
        }
        break;
    }

    // Keyword
    if (_keyword.isNotEmpty) {
      final kw = _keyword.toLowerCase();
      data = data.where((a) =>
        a.name.toLowerCase().contains(kw) ||
        a.address.toLowerCase().contains(kw) ||
        a.specialties.any((s) => s.name.toLowerCase().contains(kw))
      ).toList();
    }

    setState(() {
      _results = data;
        _isLoadingRealUsers = false;
      });
      
      print('✅ Filter applied: ${_results.length} results');
    } catch (e) {
      print('❌ Error in _applyFilters: $e');
      if (mounted) {
        setState(() {
          _isLoadingRealUsers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi áp dụng bộ lọc: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetFilters() async {
    setState(() {
      _selectedType = AccountType.designer;
      _radiusKm = 10;
      _selectedProvince = null;
      _selectedRegion = null;
      _selectedSpecialties.clear();
      _selectedCustomSpecialties.clear();
      _customSpecialties = '';
      _specialtiesController.text = '';
      _keyword = '';
      
      // Reset type-specific filters
      _selectedDesignStyle = null;
      _selectedPriceRange = null;
      _selectedLicense = null;
      _selectedProjectCapacity = null;
      _selectedBusinessType = null;
      _hasDelivery = false;
      _hasWarranty = false;
      
      // Hiện lại bộ lọc khi reset
      _showFilters = true;
    });
    
    await _applyFilters();
  }

  /// Lắng nghe thông báo tìm kiếm
  void _listenToNotifications() {
    print('🔍 SearchScreen._listenToNotifications() called');
    SearchNotificationService.getUnreadCount().listen((count) {
      print('🔍 SearchScreen - Unread count updated: $count');
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  /// Mở màn hình thông báo
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchNotificationsScreen(),
      ),
    );
  }

  /// Thực hiện tìm kiếm thời gian thực
  Future<void> _performRealTimeSearch() async {
    // Hiển thị loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Lấy vị trí hiện tại của người dùng với LocationService đã cải thiện
      final position = await LocationService.getCurrentLocation(
        requireAccurateLocation: false, // Không yêu cầu quá chính xác để nhanh hơn
      );
      double userLat = 10.8231; // Default: TP.HCM
      double userLng = 106.6297;

      if (position != null && LocationService.isValidLocation(position.latitude, position.longitude)) {
        userLat = position.latitude;
        userLng = position.longitude;
        print('✅ Got user location: $userLat, $userLng (accuracy: ${position.accuracy}m)');
      } else {
        print('⚠️ Could not get location, using default (TP.HCM)');
        if (position != null) {
          print('   Location from GPS was invalid: (${position.latitude}, ${position.longitude})');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không lấy được vị trí. Sử dụng vị trí mặc định.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Chuyển đổi AccountType sang UserAccountType
      UserAccountType? userAccountType;
      switch (_selectedType) {
        case AccountType.designer:
          userAccountType = UserAccountType.designer;
          break;
        case AccountType.contractor:
          userAccountType = UserAccountType.contractor;
          break;
        case AccountType.store:
          userAccountType = UserAccountType.store;
          break;
      }

      // Chuyển đổi specialties
      List<String> specialties = _selectedCustomSpecialties.map((s) => s.name).toList();

      // Đóng loading
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to search results
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsScreen(
              accountType: userAccountType,
              province: _selectedProvince?.name,
              region: _selectedRegion?.toString().split('.').last,
              specialties: specialties,
              minRating: 0.0, // Có thể thêm filter rating sau
              userLat: userLat,
              userLng: userLng,
              maxDistanceKm: _enableRadius ? _radiusKm : null,
              keyword: _keyword.isNotEmpty ? _keyword : null,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _performRealTimeSearch: $e');
      // Đóng loading nếu có lỗi
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Migrate user profiles để thêm các trường search mới
  void _migrateUserProfiles() async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật dữ liệu tài khoản'),
        content: const Text(
          'Thao tác này sẽ cập nhật tất cả tài khoản để hỗ trợ tìm kiếm. '
          'Bạn có chắc muốn tiếp tục?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang cập nhật dữ liệu...'),
            ],
          ),
        ),
      );

      try {
        await UserProfileMigration.migrateAllUserProfiles();
        
        // Đóng loading dialog
        Navigator.pop(context);
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật dữ liệu tài khoản thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Đóng loading dialog
        Navigator.pop(context);
        
        // Hiển thị thông báo lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load dữ liệu thật từ Firebase
  Future<void> _loadRealUsers() async {
    // FIX ANR: Không gọi _applyFilters() ngay (sẽ gọi sau khi có location)
    // Redirect to _loadRealUsersWithoutLocation
    await _loadRealUsersWithoutLocation();
  }

  /// Debug search notifications
  void _debugSearchNotifications() async {
    await SearchNotificationService.debugSearchNotifications();
  }

  /// Convert UserProfile sang SearchAccount để hiển thị
  /// TỐI ƯU: Giảm log và chỉ tính khoảng cách cho profiles hợp lệ
  List<SearchAccount> _convertUserProfilesToSearchAccounts(
    List<UserProfile> profiles, 
    double userLat, 
    double userLng
  ) {
    // Validate user location trước
    final hasValidUserLocation = LocationService.isValidLocation(userLat, userLng);
    
    if (!hasValidUserLocation) {
      print('⚠️ User location không hợp lệ: ($userLat, $userLng) - Sử dụng distance mặc định');
    }
    
    // Giới hạn số lượng profiles để xử lý (tránh ANR)
    final profilesToProcess = profiles.length > 200 
        ? profiles.take(200).toList() 
        : profiles;
    
    if (profiles.length > 200) {
      print('⚠️ Quá nhiều profiles (${profiles.length}), chỉ xử lý 200 đầu tiên');
    }
    
    return profilesToProcess.map((profile) {
      // Map UserAccountType sang AccountType
      // Chỉ map các loại designer, contractor, store
      // Bỏ qua general và các loại khác
      AccountType accountType;
      switch (profile.accountType) {
        case UserAccountType.designer:
          accountType = AccountType.designer;
          break;
        case UserAccountType.contractor:
          accountType = AccountType.contractor;
          break;
        case UserAccountType.store:
          accountType = AccountType.store;
          break;
        case UserAccountType.general:
          // Bỏ qua tài khoản general - không hiển thị trong search
          return null;
      }

      // Map province: dùng trực tiếp tên tỉnh từ hồ sơ để đồng bộ với dropdown 63 tỉnh
      Province province = profile.province.isNotEmpty
          ? Province(code: profile.province, name: profile.province, region: Region.central)
          : Province(code: 'TP. Hồ Chí Minh', name: 'TP. Hồ Chí Minh', region: Region.south);

      // Map specialties
      List<Specialty> specialties = profile.specialties.map((s) {
        return SearchData.specialties.firstWhere(
          (sp) => sp.name.toLowerCase().contains(s.toLowerCase()) || s.toLowerCase().contains(sp.name.toLowerCase()),
          orElse: () => SearchData.specialties.first,
        );
      }).toList();

      // Tính khoảng cách dùng LocationService (chính xác hơn)
      // TỐI ƯU: Chỉ tính nếu có location hợp lệ và user location hợp lệ
      double distance = -1.0; // -1.0 = Không có GPS, hiển thị "N/A" hoặc ẩn distance
      
      // Kiểm tra profile có location hợp lệ không
      bool profileHasValidLocation = LocationService.isValidLocation(profile.latitude, profile.longitude);
      double profileLat = profile.latitude;
      double profileLng = profile.longitude;
      
      // QUAN TRỌNG: Ưu tiên sử dụng tọa độ từ province nếu profile location không ở Việt Nam
      // Việt Nam nằm trong khoảng: latitude 8.5-23.4, longitude 102.1-109.5
      // Location mặc định từ emulator: 37.4219983, -122.084 (California, Mỹ)
      // Nếu profile có province name, LUÔN kiểm tra và thay thế nếu cần
      if (profile.province.isNotEmpty) {
        final isInVietnam = profileLat >= 8.5 && profileLat <= 23.4 && 
                            profileLng >= 102.1 && profileLng <= 109.5;
        final isLikelyDefaultLocation = (profileLat == 37.4219983 && profileLng == -122.084) ||
                                        (profileLat >= 37.0 && profileLat <= 38.0 && 
                                         profileLng >= -123.0 && profileLng <= -122.0);
        
        // DEBUG: Log để kiểm tra
        print('🔍 Profile ${profile.name}: location=($profileLat, $profileLng), province="${profile.province}", isInVietnam=$isInVietnam, isLikelyDefault=$isLikelyDefaultLocation, hasValidLocation=$profileHasValidLocation');
        
        // Nếu location không ở Việt Nam HOẶC là location mặc định từ emulator
        // HOẶC không có location hợp lệ, thay thế bằng tọa độ từ province
        if (!isInVietnam || isLikelyDefaultLocation || !profileHasValidLocation) {
          print('   ⚠️ Profile location không hợp lệ, thử lấy tọa độ từ province: "${profile.province}"');
          final provinceCoords = ProvinceCoordinates.getCoordinates(profile.province);
          print('   Province coordinates result: $provinceCoords');
          if (provinceCoords != null) {
            final oldLat = profileLat;
            final oldLng = profileLng;
            profileLat = provinceCoords['lat']!;
            profileLng = provinceCoords['lng']!;
            profileHasValidLocation = true;
            print('📍 Profile ${profile.name}: Thay thế location từ ($oldLat, $oldLng) -> ($profileLat, $profileLng) (từ province: ${profile.province})');
          } else {
            print('❌ Profile ${profile.name}: Không tìm thấy tọa độ từ province "${profile.province}"');
          }
        } else {
          print('   ✅ Profile location hợp lệ và ở Việt Nam, không cần thay thế');
        }
      } else {
        print('⚠️ Profile ${profile.name}: Không có province name, không thể thay thế location');
      }
      
      // Tính khoảng cách nếu cả user và profile đều có location hợp lệ
      if (hasValidUserLocation && profileHasValidLocation) {
        // DEBUG: Log để kiểm tra
        print('🔍 Calculating distance for ${profile.name}:');
        print('   User: ($userLat, $userLng)');
        print('   Profile: ($profileLat, $profileLng)');
        
        distance = LocationService.calculateDistance(
          userLat,
          userLng,
          profileLat,
          profileLng,
          silent: false, // Tạm thời false để debug
        );
        
        print('   Distance calculated: $distance km');
        
        // Nếu distance quá lớn (có thể là lỗi data), sử dụng -1.0 (không hiển thị)
        if (distance >= 20000 || distance.isInfinite || distance.isNaN) {
          distance = -1.0;
          print('   ⚠️ Distance không hợp lệ, set to -1.0');
        } else if (distance == 0.0) {
          // Nếu distance = 0, có thể là 2 điểm trùng nhau hoặc rất gần
          print('   ⚠️ Distance = 0.0 km (có thể user và profile ở cùng vị trí)');
        }
      } else {
        // Log để debug
        if (!hasValidUserLocation) {
          print('⚠️ User location không hợp lệ: ($userLat, $userLng) - Không thể tính distance');
        }
        if (!profileHasValidLocation) {
          print('⚠️ Profile ${profile.name} không có location hợp lệ và không tìm thấy tọa độ từ province: ${profile.province}');
        }
      }

      return SearchAccount(
        id: profile.id,
        name: profile.name,
        type: accountType,
        address: profile.address.isNotEmpty ? profile.address : profile.location,
        province: province,
        specialties: specialties.isNotEmpty ? specialties : [SearchData.specialties.first],
        rating: profile.rating,
        reviewCount: profile.reviewCount,
        distanceKm: distance,
        avatarUrl: profile.displayAvatar,
        additionalInfo: profile.additionalInfo,
      );
    }).whereType<SearchAccount>().toList(); // Lọc bỏ null
  }

  // (legacy) kept no-op helpers removed to simplify mapping to 63-tinh dropdown
}
