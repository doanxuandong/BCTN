enum AccountType {
  designer,   // Nhà thiết kế
  contractor, // Chủ thầu
  store,      // Cửa hàng VLXD
}

enum Region {
  north,
  central,
  south,
}

class Province {
  final String code;
  final String name;
  final Region region;

  const Province({required this.code, required this.name, required this.region});
}

class Specialty {
  final String code;
  final String name;
  final AccountType type;

  const Specialty({required this.code, required this.name, required this.type});
}

class SearchAccount {
  final String id;
  final String name;
  final AccountType type;
  final String address;
  final Province province;
  final List<Specialty> specialties;
  final double rating; // 0..5
  final int reviewCount;
  final double distanceKm; // khoảng cách giả lập
  final String? avatarUrl;
  final Map<String, dynamic> additionalInfo; // Thông tin bổ sung theo loại

  const SearchAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.province,
    required this.specialties,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    this.avatarUrl,
    this.additionalInfo = const {},
  });
}

class SearchData {
  static const List<Province> provinces = [
    Province(code: 'HN', name: 'Hà Nội', region: Region.north),
    Province(code: 'HP', name: 'Hải Phòng', region: Region.north),
    Province(code: 'DN', name: 'Đà Nẵng', region: Region.central),
    Province(code: 'KH', name: 'Khánh Hòa', region: Region.central),
    Province(code: 'HCM', name: 'TP. Hồ Chí Minh', region: Region.south),
    Province(code: 'BD', name: 'Bình Dương', region: Region.south),
  ];

  static const List<Specialty> specialties = [
    // Nhà thiết kế
    Specialty(code: 'residential', name: 'Nhà ở', type: AccountType.designer),
    Specialty(code: 'commercial', name: 'Thương mại', type: AccountType.designer),
    Specialty(code: 'interior', name: 'Nội thất', type: AccountType.designer),
    Specialty(code: 'landscape', name: 'Cảnh quan', type: AccountType.designer),
    Specialty(code: '3d', name: '3D Visualization', type: AccountType.designer),
    Specialty(code: 'sustainable', name: 'Xanh & Bền vững', type: AccountType.designer),
    
    // Chủ thầu
    Specialty(code: 'arch', name: 'Kiến trúc', type: AccountType.contractor),
    Specialty(code: 'struct', name: 'Kết cấu', type: AccountType.contractor),
    Specialty(code: 'mep', name: 'Cơ điện (MEP)', type: AccountType.contractor),
    Specialty(code: 'fin', name: 'Hoàn thiện', type: AccountType.contractor),
    Specialty(code: 'water', name: 'Cấp thoát nước', type: AccountType.contractor),
    Specialty(code: 'steel_contractor', name: 'Kết cấu thép', type: AccountType.contractor),
    Specialty(code: 'roof', name: 'Mái & Chống thấm', type: AccountType.contractor),
    
    // Cửa hàng VLXD
    Specialty(code: 'cement', name: 'Xi măng', type: AccountType.store),
    Specialty(code: 'steel_store', name: 'Thép', type: AccountType.store),
    Specialty(code: 'brick', name: 'Gạch', type: AccountType.store),
    Specialty(code: 'sand', name: 'Cát & Đá', type: AccountType.store),
    Specialty(code: 'tile', name: 'Gạch men', type: AccountType.store),
    Specialty(code: 'paint', name: 'Sơn & Vật liệu phủ', type: AccountType.store),
    Specialty(code: 'electrical', name: 'Điện & Nước', type: AccountType.store),
  ];

  static List<SearchAccount> get accounts => [
    // Nhà thiết kế
    SearchAccount(
      id: 'd1',
      name: 'Kiến trúc sư Nguyễn Văn A',
      type: AccountType.designer,
      address: '123 Nguyễn Huệ, Q.1',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[0], specialties[1], specialties[2]], // Nhà ở, Thương mại, Nội thất
      rating: 4.8,
      reviewCount: 45,
      distanceKm: 2.3,
      avatarUrl: 'https://picsum.photos/200/200?random=40',
      additionalInfo: {
        'experience': '8 năm',
        'education': 'Đại học Kiến trúc TP.HCM',
        'projects_completed': 156,
        'design_style': 'Hiện đại',
        'price_range': '10-50 triệu',
      },
    ),
    SearchAccount(
      id: 'd2',
      name: 'Studio Thiết kế Xanh',
      type: AccountType.designer,
      address: '456 Lê Lợi, Q.3',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[5], specialties[1]], // Xanh & Bền vững, Thương mại
      rating: 4.6,
      reviewCount: 32,
      distanceKm: 4.1,
      avatarUrl: 'https://picsum.photos/200/200?random=41',
      additionalInfo: {
        'experience': '12 năm',
        'education': 'Thạc sĩ Kiến trúc',
        'projects_completed': 89,
        'design_style': 'Xanh & Bền vững',
        'price_range': '20-80 triệu',
      },
    ),
    SearchAccount(
      id: 'd3',
      name: '3D Designer Pro',
      type: AccountType.designer,
      address: '789 Điện Biên Phủ, Q.Bình Thạnh',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[4], specialties[2]], // 3D Visualization, Nội thất
      rating: 4.9,
      reviewCount: 67,
      distanceKm: 6.8,
      avatarUrl: 'https://picsum.photos/200/200?random=42',
      additionalInfo: {
        'experience': '6 năm',
        'education': 'Cử nhân Thiết kế',
        'projects_completed': 234,
        'design_style': '3D & Hiện đại',
        'price_range': '5-30 triệu',
      },
    ),

    // Chủ thầu
    SearchAccount(
      id: 'c1',
      name: 'Công ty Xây dựng An Phát',
      type: AccountType.contractor,
      address: '12 Lê Duẩn, Q.1',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[6], specialties[7], specialties[9]], // Kiến trúc, Kết cấu, Hoàn thiện
      rating: 4.6,
      reviewCount: 128,
      distanceKm: 3.4,
      avatarUrl: 'https://picsum.photos/200/200?random=30',
      additionalInfo: {
        'license': 'A1',
        'experience': '15 năm',
        'employees': 120,
        'project_capacity': 'Lớn',
        'price_range': '500 triệu - 10 tỷ',
      },
    ),
    SearchAccount(
      id: 'c2',
      name: 'Nhà thầu cơ điện Hòa Bình',
      type: AccountType.contractor,
      address: 'Ngũ Hành Sơn',
      province: provinces.firstWhere((p) => p.code == 'DN'),
      specialties: [specialties[8], specialties[10]], // Cơ điện (MEP), Cấp thoát nước
      rating: 4.8,
      reviewCount: 45,
      distanceKm: 2.1,
      avatarUrl: 'https://picsum.photos/200/200?random=32',
      additionalInfo: {
        'license': 'A2',
        'experience': '8 năm',
        'employees': 45,
        'project_capacity': 'Trung bình',
        'price_range': '100 triệu - 2 tỷ',
      },
    ),
    SearchAccount(
      id: 'c3',
      name: 'Xây dựng Miền Trung',
      type: AccountType.contractor,
      address: 'Nha Trang',
      province: provinces.firstWhere((p) => p.code == 'KH'),
      specialties: [specialties[6], specialties[9], specialties[12]], // Kiến trúc, Hoàn thiện, Mái & Chống thấm
      rating: 4.7,
      reviewCount: 96,
      distanceKm: 5.6,
      avatarUrl: 'https://picsum.photos/200/200?random=34',
      additionalInfo: {
        'license': 'A1',
        'experience': '20 năm',
        'employees': 200,
        'project_capacity': 'Lớn',
        'price_range': '1 tỷ - 20 tỷ',
      },
    ),

    // Cửa hàng VLXD
    SearchAccount(
      id: 's1',
      name: 'VLXD Minh Long',
      type: AccountType.store,
      address: 'KCN VSIP, Thuận An',
      province: provinces.firstWhere((p) => p.code == 'BD'),
      specialties: [specialties[13], specialties[18]], // Xi măng, Sơn & Vật liệu phủ
      rating: 4.2,
      reviewCount: 86,
      distanceKm: 12.7,
      avatarUrl: 'https://picsum.photos/200/200?random=31',
      additionalInfo: {
        'business_type': 'Bán buôn & Bán lẻ',
        'delivery': 'Có giao hàng',
        'payment': 'Trả góp 0%',
        'warranty': '12 tháng',
        'price_range': 'Giá cạnh tranh',
      },
    ),
    SearchAccount(
      id: 's2',
      name: 'Cửa hàng Thép Việt',
      type: AccountType.store,
      address: 'Quận 9',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[14]], // Thép
      rating: 4.0,
      reviewCount: 210,
      distanceKm: 7.9,
      avatarUrl: 'https://picsum.photos/200/200?random=33',
      additionalInfo: {
        'business_type': 'Chuyên thép',
        'delivery': 'Giao hàng tận nơi',
        'payment': 'COD & Chuyển khoản',
        'warranty': '6 tháng',
        'price_range': 'Giá nhà máy',
      },
    ),
    SearchAccount(
      id: 's3',
      name: 'Gạch men Đại Phát',
      type: AccountType.store,
      address: 'Quận 12',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[17], specialties[15]], // Gạch men, Gạch
      rating: 4.4,
      reviewCount: 156,
      distanceKm: 15.2,
      avatarUrl: 'https://picsum.photos/200/200?random=35',
      additionalInfo: {
        'business_type': 'Chuyên gạch men',
        'delivery': 'Miễn phí vận chuyển',
        'payment': 'Trả góp 0%',
        'warranty': '24 tháng',
        'price_range': 'Từ 50k/m²',
      },
    ),
  ];
}
