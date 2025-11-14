/// Tọa độ của các tỉnh/thành phố chính ở Việt Nam
/// Sử dụng khi profile không có latitude/longitude trong Firebase
class ProvinceCoordinates {
  static const Map<String, Map<String, double>> coordinates = {
    'TP. Hồ Chí Minh': {'lat': 10.8231, 'lng': 106.6297},
    'Hà Nội': {'lat': 21.0285, 'lng': 105.8542},
    'Đà Nẵng': {'lat': 16.0544, 'lng': 108.2022},
    'Hải Phòng': {'lat': 20.8449, 'lng': 106.6881},
    'Cần Thơ': {'lat': 10.0452, 'lng': 105.7469},
    'An Giang': {'lat': 10.5216, 'lng': 105.1259},
    'Bà Rịa - Vũng Tàu': {'lat': 10.3460, 'lng': 107.0843},
    'Bắc Giang': {'lat': 21.2731, 'lng': 106.1946},
    'Bắc Kạn': {'lat': 22.1470, 'lng': 105.8347},
    'Bạc Liêu': {'lat': 9.2942, 'lng': 105.7278},
    'Bắc Ninh': {'lat': 21.1861, 'lng': 106.0763},
    'Bến Tre': {'lat': 10.2434, 'lng': 106.3754},
    'Bình Định': {'lat': 13.7750, 'lng': 109.2233},
    'Bình Dương': {'lat': 11.3254, 'lng': 106.4774},
    'Bình Phước': {'lat': 11.6471, 'lng': 106.6056},
    'Bình Thuận': {'lat': 11.5564, 'lng': 108.9920},
    'Cà Mau': {'lat': 9.1769, 'lng': 105.1527},
    'Cao Bằng': {'lat': 22.6657, 'lng': 106.2570},
    'Đắk Lắk': {'lat': 12.7104, 'lng': 108.2377},
    'Đắk Nông': {'lat': 12.0042, 'lng': 107.6877},
    'Điện Biên': {'lat': 21.3860, 'lng': 103.0230},
    'Đồng Nai': {'lat': 10.9574, 'lng': 106.8429},
    'Đồng Tháp': {'lat': 10.4930, 'lng': 105.6882},
    'Gia Lai': {'lat': 13.9718, 'lng': 108.0147},
    'Hà Giang': {'lat': 22.8026, 'lng': 104.9784},
    'Hà Nam': {'lat': 20.5411, 'lng': 105.9229},
    'Hà Tĩnh': {'lat': 18.3428, 'lng': 105.9059},
    'Hải Dương': {'lat': 20.9373, 'lng': 106.3146},
    'Hậu Giang': {'lat': 9.7845, 'lng': 105.4706},
    'Hòa Bình': {'lat': 20.8138, 'lng': 105.3383},
    'Hưng Yên': {'lat': 20.6464, 'lng': 106.0511},
    'Khánh Hòa': {'lat': 12.2388, 'lng': 109.1967},
    'Kiên Giang': {'lat': 10.0204, 'lng': 105.0809},
    'Kon Tum': {'lat': 14.3545, 'lng': 108.0076},
    'Lai Châu': {'lat': 22.3964, 'lng': 103.4582},
    'Lâm Đồng': {'lat': 11.9404, 'lng': 108.4583},
    'Lạng Sơn': {'lat': 21.8537, 'lng': 106.7615},
    'Lào Cai': {'lat': 22.3402, 'lng': 103.8448},
    'Long An': {'lat': 10.6586, 'lng': 106.5984},
    'Nam Định': {'lat': 20.4388, 'lng': 106.1621},
    'Nghệ An': {'lat': 19.2342, 'lng': 104.9200},
    'Ninh Bình': {'lat': 20.2506, 'lng': 105.9745},
    'Ninh Thuận': {'lat': 11.5639, 'lng': 108.9881},
    'Phú Thọ': {'lat': 21.3000, 'lng': 105.2733},
    'Phú Yên': {'lat': 13.0880, 'lng': 109.0929},
    'Quảng Bình': {'lat': 17.4681, 'lng': 106.6227},
    'Quảng Nam': {'lat': 15.8801, 'lng': 108.3380},
    'Quảng Ngãi': {'lat': 15.1167, 'lng': 108.8000},
    'Quảng Ninh': {'lat': 21.0064, 'lng': 107.2925},
    'Quảng Trị': {'lat': 16.7500, 'lng': 107.2000},
    'Sóc Trăng': {'lat': 9.6037, 'lng': 105.9800},
    'Sơn La': {'lat': 21.3257, 'lng': 103.9160},
    'Tây Ninh': {'lat': 11.3131, 'lng': 106.0963},
    'Thái Bình': {'lat': 20.4465, 'lng': 106.3366},
    'Thái Nguyên': {'lat': 21.5942, 'lng': 105.8482},
    'Thanh Hóa': {'lat': 19.8067, 'lng': 105.7852},
    'Thừa Thiên Huế': {'lat': 16.4637, 'lng': 107.5909},
    'Tiền Giang': {'lat': 10.3600, 'lng': 106.3600},
    'Trà Vinh': {'lat': 9.9349, 'lng': 106.3453},
    'Tuyên Quang': {'lat': 21.8180, 'lng': 105.2180},
    'Vĩnh Long': {'lat': 10.2531, 'lng': 105.9722},
    'Vĩnh Phúc': {'lat': 21.3087, 'lng': 105.6049},
    'Yên Bái': {'lat': 21.7029, 'lng': 104.8720},
  };

  /// Lấy tọa độ từ tên tỉnh/thành phố
  /// Trả về null nếu không tìm thấy
  static Map<String, double>? getCoordinates(String provinceName) {
    if (provinceName.isEmpty) {
      return null;
    }

    // Thử tìm chính xác
    if (coordinates.containsKey(provinceName)) {
      return coordinates[provinceName];
    }

    // Thử tìm không phân biệt hoa thường
    final normalizedName = provinceName.toLowerCase().trim();
    for (var key in coordinates.keys) {
      if (key.toLowerCase().trim() == normalizedName) {
        return coordinates[key];
      }
    }

    // Thử tìm một phần tên (ví dụ: "Hồ Chí Minh" trong "TP. Hồ Chí Minh")
    // Loại bỏ các từ phổ biến như "TP.", "Thành phố", "Tỉnh"
    final cleanedName = normalizedName
        .replaceAll('tp.', '')
        .replaceAll('thành phố', '')
        .replaceAll('tỉnh', '')
        .trim();
    
    for (var key in coordinates.keys) {
      final keyLower = key.toLowerCase();
      final keyCleaned = keyLower
          .replaceAll('tp.', '')
          .replaceAll('thành phố', '')
          .replaceAll('tỉnh', '')
          .trim();
      
      // So sánh tên đã làm sạch
      if (keyCleaned == cleanedName || 
          keyCleaned.contains(cleanedName) || 
          cleanedName.contains(keyCleaned)) {
        return coordinates[key];
      }
      
      // So sánh tên gốc
      if (keyLower.contains(normalizedName) || 
          normalizedName.contains(keyLower)) {
        return coordinates[key];
      }
    }

    return null;
  }

  /// Lấy latitude từ tên tỉnh/thành phố
  static double? getLatitude(String provinceName) {
    final coords = getCoordinates(provinceName);
    return coords?['lat'];
  }

  /// Lấy longitude từ tên tỉnh/thành phố
  static double? getLongitude(String provinceName) {
    final coords = getCoordinates(provinceName);
    return coords?['lng'];
  }
}

