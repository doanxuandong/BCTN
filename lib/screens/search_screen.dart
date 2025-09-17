import 'package:flutter/material.dart';
import '../models/search_models.dart';
import '../components/account_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  AccountType _selectedType = AccountType.contractor;
  double _radiusKm = 10;
  Province? _selectedProvince;
  Region? _selectedRegion;
  final Set<Specialty> _selectedSpecialties = {};
  String _keyword = '';

  List<SearchAccount> _results = SearchData.accounts;

  @override
  void initState() {
    super.initState();
    _selectedProvince = null;
    _selectedRegion = null;
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
          _buildFilters(),
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
      child: Row(
        children: [
          _typeChip(AccountType.contractor, 'Chủ thầu', Icons.engineering),
          const SizedBox(width: 8),
          _typeChip(AccountType.store, 'Cửa hàng VLXD', Icons.storefront),
        ],
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
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
          const SizedBox(height: 8),
          _buildSpecialtiesWrap(),
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

  Widget _buildSpecialtiesWrap() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: SearchData.specialties.map((s) {
          final selected = _selectedSpecialties.contains(s);
          return FilterChip(
            label: Text(s.name),
            selected: selected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _selectedSpecialties.add(s);
                } else {
                  _selectedSpecialties.remove(s);
                }
                _applyFilters();
              });
            },
            selectedColor: Colors.blue[100],
            checkmarkColor: Colors.blue[700],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeywordBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, địa chỉ, chuyên ngành...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _keyword.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _keyword = '';
                      _applyFilters();
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (v) {
          setState(() {
            _keyword = v;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildResultHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Kết quả',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text('(${_results.length})', style: TextStyle(color: Colors.grey[600])),
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
              children: const [
                Icon(Icons.sort, size: 18),
                SizedBox(width: 4),
                Text('Sắp xếp'),
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
    var data = SearchData.accounts;

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

    // Specialties
    if (_selectedSpecialties.isNotEmpty) {
      data = data.where((a) => a.specialties.any((s) => _selectedSpecialties.contains(s))).toList();
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
      _selectedType = AccountType.contractor;
      _radiusKm = 10;
      _selectedProvince = null;
      _selectedRegion = null;
      _selectedSpecialties.clear();
      _keyword = '';
      _applyFilters();
    });
  }
}
