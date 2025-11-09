import '../../models/user_profile.dart';

/// Model cho câu hỏi trong Smart Search
class SmartSearchQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<QuestionOption> options;
  final String? hint;
  final int weight; // Trọng số (1-10)
  final UserAccountType targetType;
  final bool isRequired;

  SmartSearchQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.hint,
    this.weight = 5,
    required this.targetType,
    this.isRequired = false,
  });
}

/// Loại câu hỏi
enum QuestionType {
  singleChoice,   // Chọn 1 đáp án
  multipleChoice, // Chọn nhiều đáp án
  slider,         // Slider (ví dụ: khoảng giá, bán kính)
  text,           // Nhập text
  location,       // Chọn vị trí
}

/// Lựa chọn cho câu hỏi
class QuestionOption {
  final String id;
  final String label;
  final Map<String, dynamic> criteria; // Tiêu chí tương ứng với đáp án này

  QuestionOption({
    required this.id,
    required this.label,
    this.criteria = const {},
  });
}

/// Kết quả tìm kiếm với điểm số matching
class SmartSearchResult {
  final UserProfile profile;
  final double matchScore; // Điểm matching (0-100)
  final Map<String, dynamic> matchDetails; // Chi tiết matching

  SmartSearchResult({
    required this.profile,
    required this.matchScore,
    this.matchDetails = const {},
  });

  String get matchPercentage => '${matchScore.toStringAsFixed(0)}%';
}

/// Tiêu chí tìm kiếm từ câu trả lời
class SearchCriteria {
  final UserAccountType accountType;
  final List<String> specialties;
  final String? province;
  final String? designStyle;
  final String? priceRange;
  final double? minBudget;
  final double? maxBudget;
  final bool? needsInteriorDesign;
  final String? projectType;
  final String? projectScale;
  final bool? requiresLicense;
  final bool? needsDelivery;
  final bool? needsWarranty;
  final String? materialTypes;
  final String? quantity;
  final double? userLat;
  final double? userLng;
  final double? maxDistanceKm;

  SearchCriteria({
    required this.accountType,
    this.specialties = const [],
    this.province,
    this.designStyle,
    this.priceRange,
    this.minBudget,
    this.maxBudget,
    this.needsInteriorDesign,
    this.projectType,
    this.projectScale,
    this.requiresLicense,
    this.needsDelivery,
    this.needsWarranty,
    this.materialTypes,
    this.quantity,
    this.userLat,
    this.userLng,
    this.maxDistanceKm,
  });
}

