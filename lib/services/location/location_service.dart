import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Kiểm tra và yêu cầu quyền truy cập vị trí
  static Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Kiểm tra đã có quyền truy cập vị trí chưa
  static Future<bool> hasPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Lấy vị trí hiện tại của người dùng
  static Future<Position?> getCurrentLocation() async {
    try {
      print('🔍 LocationService.getCurrentLocation() called');
      
      // Kiểm tra quyền
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        print('❌ No location permission');
        return null;
      }

      // Kiểm tra dịch vụ GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Location retrieved: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Kiểm tra permission
  static Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Mở settings để người dùng cấp quyền
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Tính khoảng cách giữa 2 điểm (km)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Kiểm tra 2 điểm có nằm trong bán kính không
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusKm,
  ) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusKm;
  }
}

