enum AccountType {
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

  const Specialty({required this.code, required this.name});
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
    Specialty(code: 'arch', name: 'Kiến trúc'),
    Specialty(code: 'struct', name: 'Kết cấu'),
    Specialty(code: 'mep', name: 'Cơ điện (MEP)'),
    Specialty(code: 'fin', name: 'Hoàn thiện'),
    Specialty(code: 'water', name: 'Cấp thoát nước'),
    Specialty(code: 'steel', name: 'Kết cấu thép'),
    Specialty(code: 'roof', name: 'Mái & Chống thấm'),
  ];

  static List<SearchAccount> get accounts => [
    SearchAccount(
      id: 'a1',
      name: 'Công ty Xây dựng An Phát',
      type: AccountType.contractor,
      address: '12 Lê Duẩn, Q.1',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[0], specialties[1], specialties[3]],
      rating: 4.6,
      reviewCount: 128,
      distanceKm: 3.4,
      avatarUrl: 'https://picsum.photos/200/200?random=30',
    ),
    SearchAccount(
      id: 'a2',
      name: 'VLXD Minh Long',
      type: AccountType.store,
      address: 'KCN VSIP, Thuận An',
      province: provinces.firstWhere((p) => p.code == 'BD'),
      specialties: [specialties[3], specialties[6]],
      rating: 4.2,
      reviewCount: 86,
      distanceKm: 12.7,
      avatarUrl: 'https://picsum.photos/200/200?random=31',
    ),
    SearchAccount(
      id: 'a3',
      name: 'Nhà thầu cơ điện Hòa Bình',
      type: AccountType.contractor,
      address: 'Ngũ Hành Sơn',
      province: provinces.firstWhere((p) => p.code == 'DN'),
      specialties: [specialties[2], specialties[4]],
      rating: 4.8,
      reviewCount: 45,
      distanceKm: 2.1,
      avatarUrl: 'https://picsum.photos/200/200?random=32',
    ),
    SearchAccount(
      id: 'a4',
      name: 'Cửa hàng Thép Việt',
      type: AccountType.store,
      address: 'Quận 9',
      province: provinces.firstWhere((p) => p.code == 'HCM'),
      specialties: [specialties[5]],
      rating: 4.0,
      reviewCount: 210,
      distanceKm: 7.9,
      avatarUrl: 'https://picsum.photos/200/200?random=33',
    ),
    SearchAccount(
      id: 'a5',
      name: 'Xây dựng Miền Trung',
      type: AccountType.contractor,
      address: 'Nha Trang',
      province: provinces.firstWhere((p) => p.code == 'KH'),
      specialties: [specialties[0], specialties[3], specialties[6]],
      rating: 4.7,
      reviewCount: 96,
      distanceKm: 5.6,
      avatarUrl: 'https://picsum.photos/200/200?random=34',
    ),
  ];
}
