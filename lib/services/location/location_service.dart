import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Minimum accuracy threshold (meters) - vị trí chính xác trong vòng 100m
  static const double _minAccuracyMeters = 100.0;
  // Maximum retry attempts
  static const int _maxRetries = 3;
  // Retry delay
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Kiểm tra và yêu cầu quyền truy cập vị trí
  static Future<bool> requestPermission() async {
    try {
      // Kiểm tra quyền hiện tại
      final currentStatus = await Permission.location.status;
      
      if (currentStatus.isGranted) {
        print('✅ Location permission already granted');
        return true;
      }
      
      if (currentStatus.isDenied) {
        // Yêu cầu quyền
        final status = await Permission.location.request();
        if (status.isGranted) {
          print('✅ Location permission granted');
          return true;
        } else if (status.isPermanentlyDenied) {
          print('❌ Location permission permanently denied');
          return false;
        }
      } else if (currentStatus.isPermanentlyDenied) {
        print('❌ Location permission permanently denied - need to open settings');
        return false;
      }
      
      return false;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Kiểm tra đã có quyền truy cập vị trí chưa
  static Future<bool> hasPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }

  /// Lấy vị trí hiện tại của người dùng với retry và accuracy check
  /// Cải thiện: Thêm accuracy validation, retry mechanism, và better error handling
  static Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int maxRetries = _maxRetries,
    bool requireAccurateLocation = true,
  }) async {
    try {
      print('🔍 LocationService.getCurrentLocation() called');
      print('   Accuracy: $accuracy, Max retries: $maxRetries');
      
      // Kiểm tra quyền
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        print('❌ No location permission - requesting...');
        final granted = await requestPermission();
        if (!granted) {
          print('❌ Location permission not granted');
          return null;
        }
      }

      // Kiểm tra dịch vụ GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Retry mechanism
      Position? bestPosition;
      double bestAccuracy = double.infinity;
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('📍 Attempt $attempt/$maxRetries: Getting location...');
          
          // Lấy vị trí hiện tại
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: const Duration(seconds: 15), // Tăng timeout lên 15 giây
          );

          print('📍 Position retrieved:');
          print('   Lat: ${position.latitude}, Lng: ${position.longitude}');
          print('   Accuracy: ${position.accuracy}m');
          print('   Timestamp: ${position.timestamp}');

          // Kiểm tra accuracy
          if (position.accuracy <= _minAccuracyMeters) {
            print('✅ Location is accurate (${position.accuracy}m <= ${_minAccuracyMeters}m)');
            return position;
          }

          // Nếu không đủ chính xác nhưng tốt hơn lần trước, lưu lại
          if (position.accuracy < bestAccuracy) {
            bestPosition = position;
            bestAccuracy = position.accuracy;
            print('⚠️ Location accuracy ${position.accuracy}m is not ideal, but keeping as best so far');
          }

          // Nếu không yêu cầu location chính xác, trả về ngay
          if (!requireAccurateLocation) {
            print('✅ Location retrieved (accuracy not strictly required)');
            return position;
          }

          // Nếu không phải lần cuối, chờ một chút rồi thử lại
          if (attempt < maxRetries) {
            print('⏳ Waiting ${_retryDelay.inSeconds}s before retry...');
            await Future.delayed(_retryDelay);
          }
        } catch (e) {
          print('❌ Error in attempt $attempt: $e');
          if (attempt < maxRetries) {
            await Future.delayed(_retryDelay);
          }
        }
      }

      // Nếu có position tốt nhất, trả về nó (cảnh báo về accuracy)
      if (bestPosition != null) {
        print('⚠️ Returning best available location with accuracy ${bestAccuracy}m');
        print('   (Requested accuracy: ${_minAccuracyMeters}m)');
        return bestPosition;
      }

      print('❌ Failed to get location after $maxRetries attempts');
      return null;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Lấy vị trí với accuracy thấp hơn (nhanh hơn, ít chính xác hơn)
  static Future<Position?> getCurrentLocationQuick() async {
    return getCurrentLocation(
      accuracy: LocationAccuracy.medium,
      maxRetries: 2,
      requireAccurateLocation: false,
    );
  }

  /// Kiểm tra permission
  static Future<bool> checkPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Error checking permission: $e');
      return false;
    }
  }

  /// Mở settings để người dùng cấp quyền
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ Error opening settings: $e');
    }
  }

  /// Tính khoảng cách giữa 2 điểm (km) sử dụng Haversine formula
  /// Sử dụng Geolocator.distanceBetween() - đã được tối ưu và chính xác
  /// [silent]: Nếu true, sẽ không print log (dùng khi tính toán nhiều lần trong vòng lặp)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    bool silent = false, // Mặc định không silent để debug, nhưng có thể bật khi cần
  }) {
    try {
      // Validate inputs
      if (!_isValidLatitude(lat1) || !_isValidLatitude(lat2)) {
        if (!silent) print('⚠️ Invalid latitude: $lat1, $lat2');
        return double.infinity;
      }
      if (!_isValidLongitude(lon1) || !_isValidLongitude(lon2)) {
        if (!silent) print('⚠️ Invalid longitude: $lon1, $lon2');
        return double.infinity;
      }

      // Kiểm tra nếu 2 điểm giống nhau (tránh tính toán không cần thiết)
      if (lat1 == lat2 && lon1 == lon2) {
        return 0.0;
      }

      // Sử dụng Geolocator.distanceBetween() - đã implement Haversine formula chính xác
      final distanceMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
      final distanceKm = distanceMeters / 1000.0;
      
      // Chỉ log khi không silent và distance hợp lý (không quá lớn - có thể là lỗi)
      if (!silent && distanceKm < 20000) { // Chỉ log nếu distance < 20000km (hợp lý)
        print('📍 Distance: ${distanceKm.toStringAsFixed(2)} km');
      } else if (!silent && distanceKm >= 20000) {
        // Log cảnh báo nếu distance quá lớn (có thể là lỗi data)
        print('⚠️ Distance quá lớn (có thể lỗi data): ${distanceKm.toStringAsFixed(2)} km');
        print('   From: ($lat1, $lon1)');
        print('   To: ($lat2, $lon2)');
      }
      
      return distanceKm;
    } catch (e) {
      if (!silent) print('❌ Error calculating distance: $e');
      return double.infinity;
    }
  }

  /// Kiểm tra 2 điểm có nằm trong bán kính không
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusKm,
  ) {
    try {
      final distance = calculateDistance(lat1, lon1, lat2, lon2);
      final isWithin = distance <= radiusKm;
      print('📍 Is within radius: $isWithin (distance: ${distance.toStringAsFixed(2)}km, radius: ${radiusKm}km)');
      return isWithin;
    } catch (e) {
      print('❌ Error checking radius: $e');
      return false;
    }
  }

  /// Validate latitude (-90 to 90)
  static bool _isValidLatitude(double latitude) {
    return latitude >= -90.0 && latitude <= 90.0;
  }

  /// Validate longitude (-180 to 180)
  static bool _isValidLongitude(double longitude) {
    return longitude >= -180.0 && longitude <= 180.0;
  }

  /// Kiểm tra location có hợp lệ không (không phải 0,0 và trong phạm vi hợp lệ)
  static bool isValidLocation(double latitude, double longitude) {
    // Kiểm tra không phải là giá trị mặc định (0,0)
    if (latitude == 0.0 && longitude == 0.0) {
      return false;
    }
    
    // Kiểm tra trong phạm vi hợp lệ
    return _isValidLatitude(latitude) && _isValidLongitude(longitude);
  }

  /// Lấy vị trí với fallback về default location nếu không lấy được
  static Future<Position?> getCurrentLocationWithFallback({
    double defaultLat = 10.8231, // TP.HCM
    double defaultLng = 106.6297,
  }) async {
    final position = await getCurrentLocation(requireAccurateLocation: false);
    
    if (position != null && isValidLocation(position.latitude, position.longitude)) {
      return position;
    }
    
    print('⚠️ Using default location: ($defaultLat, $defaultLng)');
    // Tạo Position object với default location
    return Position(
      latitude: defaultLat,
      longitude: defaultLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}

