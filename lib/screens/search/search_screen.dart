import 'package:flutter/material.dart';
import '../../models/search_models.dart';
import '../../models/user_profile.dart';
import '../../components/account_card.dart';
import '../../services/search/search_notification_service.dart';
import '../../services/user/user_profile_service.dart';
import '../../utils/migrate_user_profiles.dart';
import 'search_results_screen.dart';
import 'search_notifications_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  AccountType _selectedType = AccountType.designer;
  double _radiusKm = 10;
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

  @override
  void initState() {
    super.initState();
    _selectedProvince = null;
    _selectedRegion = null;
    _specialtiesController = TextEditingController(text: _customSpecialties);
    _listenToNotifications();
    _loadRealUsers(); // Load dữ liệu thật từ Firebase
  }

  @override
  void dispose() {
    _specialtiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
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
      ),
      body: Column(
        children: [
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
      onSelected: (_) {
        setState(() {
          _selectedType = type;
          _applyFilters();
        });
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
              const Text('Bán kính:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
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
    return DropdownButtonFormField<Province?>(
      value: _selectedProvince,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tỉnh/Thành',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_city),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        ...SearchData.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
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
        return AccountCard(account: acc, onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mở hồ sơ: ${acc.name}')),
          );
        });
      },
    );
  }

  void _applyFilters() {
    // Sử dụng dữ liệu thật từ Firebase nếu có, nếu không thì dùng dữ liệu tĩnh
    var data = _realUsers.isNotEmpty ? _convertUserProfilesToSearchAccounts(_realUsers) : SearchData.accounts;

    data = data.where((a) => a.type == _selectedType).toList();

    // Province
    if (_selectedProvince != null) {
      data = data.where((a) => a.province.code == _selectedProvince!.code).toList();
    }

    // Region
    if (_selectedRegion != null) {
      data = data.where((a) => a.province.region == _selectedRegion!).toList();
    }

    // Radius (giả lập)
    data = data.where((a) => a.distanceKm <= _radiusKm).toList();

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
    });
  }

  void _resetFilters() {
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
      
      _applyFilters();
    });
  }

  /// Lắng nghe thông báo tìm kiếm
  void _listenToNotifications() {
    SearchNotificationService.getUnreadCount().listen((count) {
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
  void _performRealTimeSearch() {
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

    // Vị trí giả lập (TP.HCM)
    const double userLat = 10.8231;
    const double userLng = 106.6297;

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
          maxDistanceKm: _radiusKm,
          keyword: _keyword.isNotEmpty ? _keyword : null,
        ),
      ),
    );
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
  void _loadRealUsers() async {
    setState(() {
      _isLoadingRealUsers = true;
    });

    try {
      print('Loading real users from Firebase...');
      
      // Lấy tất cả user profiles có thể tìm kiếm
      final users = await UserProfileService.searchProfiles();
      
      print('Loaded ${users.length} real users from Firebase');
      for (var user in users) {
        print('- ${user.name} (${user.accountType}) - ${user.province}');
      }
      
      setState(() {
        _realUsers = users;
        _isLoadingRealUsers = false;
      });

      // Apply filters với dữ liệu mới
      _applyFilters();
      
      // Hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải ${users.length} tài khoản thật từ Firebase'),
            backgroundColor: Colors.green,
          ),
        );
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

  /// Debug search notifications
  void _debugSearchNotifications() async {
    await SearchNotificationService.debugSearchNotifications();
  }

  /// Convert UserProfile sang SearchAccount để hiển thị
  List<SearchAccount> _convertUserProfilesToSearchAccounts(List<UserProfile> profiles) {
    return profiles.map((profile) {
      // Map UserAccountType sang AccountType
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
        default:
          accountType = AccountType.designer; // Default
      }

      // Map province
      Province? province;
      if (profile.province.isNotEmpty) {
        province = SearchData.provinces.firstWhere(
          (p) => p.name.contains(profile.province) || profile.province.contains(p.name),
          orElse: () => SearchData.provinces.first,
        );
      } else {
        province = SearchData.provinces.first;
      }

      // Map specialties
      List<Specialty> specialties = profile.specialties.map((s) {
        return SearchData.specialties.firstWhere(
          (sp) => sp.name.toLowerCase().contains(s.toLowerCase()) || s.toLowerCase().contains(sp.name.toLowerCase()),
          orElse: () => SearchData.specialties.first,
        );
      }).toList();

      return SearchAccount(
        id: profile.id,
        name: profile.name,
        type: accountType,
        address: profile.address.isNotEmpty ? profile.address : profile.location,
        province: province,
        specialties: specialties.isNotEmpty ? specialties : [SearchData.specialties.first],
        rating: profile.rating,
        reviewCount: profile.reviewCount,
        distanceKm: profile.latitude != 0.0 && profile.longitude != 0.0 
            ? profile.calculateDistance(10.8231, 106.6297) // TP.HCM coordinates
            : 5.0, // Default distance
        avatarUrl: profile.displayAvatar,
        additionalInfo: profile.additionalInfo,
      );
    }).toList();
  }
}
