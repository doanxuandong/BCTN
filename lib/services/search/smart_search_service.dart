import '../../models/user_profile.dart';
import '../../models/smart_search_question.dart';
import '../user/user_profile_service.dart';
import '../location/location_service.dart';
import 'dart:math' as math;

class SmartSearchService {
  /// Lấy danh sách câu hỏi theo loại tài khoản
  static List<SmartSearchQuestion> getQuestions(UserAccountType type) {
    switch (type) {
      case UserAccountType.designer:
        return _getDesignerQuestions();
      case UserAccountType.contractor:
        return _getContractorQuestions();
      case UserAccountType.store:
        return _getStoreQuestions();
      default:
        return [];
    }
  }

  /// Câu hỏi cho Nhà thiết kế
  static List<SmartSearchQuestion> _getDesignerQuestions() {
    return [
      SmartSearchQuestion(
        id: 'designer_1',
        question: 'Loại dự án bạn cần thiết kế?',
        type: QuestionType.multipleChoice,
        weight: 10,
        targetType: UserAccountType.designer,
        isRequired: true,
        options: [
          QuestionOption(
            id: 'residential',
            label: 'Nhà ở dân dụng',
            criteria: {'specialty': 'Nhà ở dân dụng'},
          ),
          QuestionOption(
            id: 'villa',
            label: 'Biệt thự',
            criteria: {'specialty': 'Biệt thự'},
          ),
          QuestionOption(
            id: 'apartment',
            label: 'Chung cư',
            criteria: {'specialty': 'Chung cư'},
          ),
          QuestionOption(
            id: 'office',
            label: 'Văn phòng',
            criteria: {'specialty': 'Văn phòng'},
          ),
          QuestionOption(
            id: 'public',
            label: 'Công trình công cộng',
            criteria: {'specialty': 'Công trình công cộng'},
          ),
          QuestionOption(
            id: 'other',
            label: 'Khác',
            criteria: {'specialty': 'Khác'},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'designer_2',
        question: 'Phong cách thiết kế bạn ưa thích?',
        type: QuestionType.singleChoice,
        weight: 8,
        targetType: UserAccountType.designer,
        options: [
          QuestionOption(
            id: 'modern',
            label: 'Hiện đại',
            criteria: {'design_style': 'Hiện đại'},
          ),
          QuestionOption(
            id: 'classic',
            label: 'Cổ điển',
            criteria: {'design_style': 'Cổ điển'},
          ),
          QuestionOption(
            id: 'minimalist',
            label: 'Tối giản',
            criteria: {'design_style': 'Tối giản'},
          ),
          QuestionOption(
            id: 'indochine',
            label: 'Đông Dương',
            criteria: {'design_style': 'Đông Dương'},
          ),
          QuestionOption(
            id: 'any',
            label: 'Không quan trọng',
            criteria: {},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'designer_3',
        question: 'Ngân sách dự kiến (triệu VNĐ)?',
        type: QuestionType.slider,
        weight: 7,
        targetType: UserAccountType.designer,
        hint: 'Chọn ngân sách từ 5 triệu đến 200 triệu',
      ),
      SmartSearchQuestion(
        id: 'designer_4',
        question: 'Vị trí dự án?',
        type: QuestionType.location,
        weight: 9,
        targetType: UserAccountType.designer,
        isRequired: true,
      ),
      SmartSearchQuestion(
        id: 'designer_5',
        question: 'Bạn có cần thiết kế nội thất không?',
        type: QuestionType.singleChoice,
        weight: 6,
        targetType: UserAccountType.designer,
        options: [
          QuestionOption(
            id: 'yes',
            label: 'Có',
            criteria: {'interior_design': true},
          ),
          QuestionOption(
            id: 'no',
            label: 'Không',
            criteria: {'interior_design': false},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'designer_6',
        question: 'Thời gian hoàn thành mong muốn?',
        type: QuestionType.singleChoice,
        weight: 5,
        targetType: UserAccountType.designer,
        options: [
          QuestionOption(
            id: '1month',
            label: 'Dưới 1 tháng',
            criteria: {'timeline': '< 1 tháng'},
          ),
          QuestionOption(
            id: '1-3months',
            label: '1-3 tháng',
            criteria: {'timeline': '1-3 tháng'},
          ),
          QuestionOption(
            id: '3-6months',
            label: '3-6 tháng',
            criteria: {'timeline': '3-6 tháng'},
          ),
          QuestionOption(
            id: '6months',
            label: 'Trên 6 tháng',
            criteria: {'timeline': '> 6 tháng'},
          ),
        ],
      ),
    ];
  }

  /// Câu hỏi cho Chủ thầu
  static List<SmartSearchQuestion> _getContractorQuestions() {
    return [
      SmartSearchQuestion(
        id: 'contractor_1',
        question: 'Loại công trình cần thi công?',
        type: QuestionType.multipleChoice,
        weight: 10,
        targetType: UserAccountType.contractor,
        isRequired: true,
        options: [
          QuestionOption(
            id: 'house',
            label: 'Nhà ở',
            criteria: {'specialty': 'Nhà ở'},
          ),
          QuestionOption(
            id: 'apartment',
            label: 'Chung cư',
            criteria: {'specialty': 'Chung cư'},
          ),
          QuestionOption(
            id: 'public',
            label: 'Công trình công cộng',
            criteria: {'specialty': 'Công trình công cộng'},
          ),
          QuestionOption(
            id: 'industrial',
            label: 'Công nghiệp',
            criteria: {'specialty': 'Công nghiệp'},
          ),
          QuestionOption(
            id: 'other',
            label: 'Khác',
            criteria: {'specialty': 'Khác'},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'contractor_2',
        question: 'Quy mô dự án?',
        type: QuestionType.singleChoice,
        weight: 8,
        targetType: UserAccountType.contractor,
        options: [
          QuestionOption(
            id: 'small',
            label: 'Nhỏ (< 100m²)',
            criteria: {'project_capacity': 'Nhỏ'},
          ),
          QuestionOption(
            id: 'medium',
            label: 'Trung bình (100-500m²)',
            criteria: {'project_capacity': 'Trung bình'},
          ),
          QuestionOption(
            id: 'large',
            label: 'Lớn (500-2000m²)',
            criteria: {'project_capacity': 'Lớn'},
          ),
          QuestionOption(
            id: 'very_large',
            label: 'Rất lớn (> 2000m²)',
            criteria: {'project_capacity': 'Rất lớn'},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'contractor_3',
        question: 'Ngân sách dự kiến (triệu VNĐ)?',
        type: QuestionType.slider,
        weight: 7,
        targetType: UserAccountType.contractor,
        hint: 'Chọn ngân sách từ 100 triệu đến 10.000 triệu',
      ),
      SmartSearchQuestion(
        id: 'contractor_4',
        question: 'Yêu cầu về giấy phép?',
        type: QuestionType.singleChoice,
        weight: 6,
        targetType: UserAccountType.contractor,
        options: [
          QuestionOption(
            id: 'required',
            label: 'Có giấy phép hành nghề',
            criteria: {'license': 'required'},
          ),
          QuestionOption(
            id: 'preferred',
            label: 'Ưu tiên có giấy phép',
            criteria: {'license': 'preferred'},
          ),
          QuestionOption(
            id: 'not_required',
            label: 'Không yêu cầu',
            criteria: {'license': 'not_required'},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'contractor_5',
        question: 'Vị trí dự án?',
        type: QuestionType.location,
        weight: 9,
        targetType: UserAccountType.contractor,
        isRequired: true,
      ),
      SmartSearchQuestion(
        id: 'contractor_6',
        question: 'Thời gian thi công mong muốn?',
        type: QuestionType.singleChoice,
        weight: 5,
        targetType: UserAccountType.contractor,
        options: [
          QuestionOption(
            id: '3months',
            label: 'Dưới 3 tháng',
            criteria: {'timeline': '< 3 tháng'},
          ),
          QuestionOption(
            id: '3-6months',
            label: '3-6 tháng',
            criteria: {'timeline': '3-6 tháng'},
          ),
          QuestionOption(
            id: '6-12months',
            label: '6-12 tháng',
            criteria: {'timeline': '6-12 tháng'},
          ),
          QuestionOption(
            id: '12months',
            label: 'Trên 12 tháng',
            criteria: {'timeline': '> 12 tháng'},
          ),
        ],
      ),
    ];
  }

  /// Câu hỏi cho Cửa hàng VLXD
  static List<SmartSearchQuestion> _getStoreQuestions() {
    return [
      SmartSearchQuestion(
        id: 'store_1',
        question: 'Loại vật liệu cần mua?',
        type: QuestionType.multipleChoice,
        weight: 10,
        targetType: UserAccountType.store,
        isRequired: true,
        options: [
          QuestionOption(
            id: 'cement',
            label: 'Xi măng',
            criteria: {'specialty': 'Xi măng'},
          ),
          QuestionOption(
            id: 'brick',
            label: 'Gạch',
            criteria: {'specialty': 'Gạch'},
          ),
          QuestionOption(
            id: 'steel',
            label: 'Sắt thép',
            criteria: {'specialty': 'Sắt thép'},
          ),
          QuestionOption(
            id: 'wood',
            label: 'Gỗ',
            criteria: {'specialty': 'Gỗ'},
          ),
          QuestionOption(
            id: 'paint',
            label: 'Sơn',
            criteria: {'specialty': 'Sơn'},
          ),
          QuestionOption(
            id: 'sanitary',
            label: 'Thiết bị vệ sinh',
            criteria: {'specialty': 'Thiết bị vệ sinh'},
          ),
          QuestionOption(
            id: 'other',
            label: 'Khác',
            criteria: {'specialty': 'Khác'},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'store_2',
        question: 'Số lượng dự kiến?',
        type: QuestionType.singleChoice,
        weight: 7,
        targetType: UserAccountType.store,
        options: [
          QuestionOption(
            id: 'small',
            label: 'Nhỏ lẻ',
            criteria: {'quantity': 'Nhỏ lẻ'},
          ),
          QuestionOption(
            id: 'medium',
            label: 'Trung bình',
            criteria: {'quantity': 'Trung bình'},
          ),
          QuestionOption(
            id: 'large',
            label: 'Số lượng lớn',
            criteria: {'quantity': 'Lớn'},
          ),
          QuestionOption(
            id: 'very_large',
            label: 'Rất lớn',
            criteria: {'quantity': 'Rất lớn'},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'store_3',
        question: 'Ngân sách (triệu VNĐ)?',
        type: QuestionType.slider,
        weight: 6,
        targetType: UserAccountType.store,
        hint: 'Chọn ngân sách từ 10 triệu đến 1.000 triệu',
      ),
      SmartSearchQuestion(
        id: 'store_4',
        question: 'Yêu cầu giao hàng?',
        type: QuestionType.singleChoice,
        weight: 8,
        targetType: UserAccountType.store,
        options: [
          QuestionOption(
            id: 'yes',
            label: 'Có giao hàng',
            criteria: {'delivery': true},
          ),
          QuestionOption(
            id: 'no',
            label: 'Tự vận chuyển',
            criteria: {'delivery': false},
          ),
          QuestionOption(
            id: 'any',
            label: 'Không quan trọng',
            criteria: {},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'store_5',
        question: 'Yêu cầu bảo hành?',
        type: QuestionType.singleChoice,
        weight: 6,
        targetType: UserAccountType.store,
        options: [
          QuestionOption(
            id: 'yes',
            label: 'Có',
            criteria: {'warranty': true},
          ),
          QuestionOption(
            id: 'no',
            label: 'Không',
            criteria: {'warranty': false},
          ),
        ],
      ),
      SmartSearchQuestion(
        id: 'store_6',
        question: 'Vị trí?',
        type: QuestionType.location,
        weight: 9,
        targetType: UserAccountType.store,
        isRequired: true,
      ),
    ];
  }

  /// Phân tích câu trả lời và tạo search criteria
  static SearchCriteria analyzeAnswers(
    UserAccountType type,
    Map<String, dynamic> answers,
    double? userLat,
    double? userLng,
  ) {
    final specialties = <String>[];
    String? province;
    String? designStyle;
    String? priceRange;
    double? minBudget;
    double? maxBudget;
    bool? needsInteriorDesign;
    String? projectType;
    String? projectScale;
    bool? requiresLicense;
    bool? needsDelivery;
    bool? needsWarranty;
    String? materialTypes;
    String? quantity;

    // Parse answers
    answers.forEach((questionId, answer) {
      if (answer == null) return;

      // Parse location (String) - check questionId first
      // Location questions: designer_4, contractor_5, store_6
      if (questionId == 'designer_4' || questionId == 'contractor_5' || questionId == 'store_6') {
        if (answer is String && answer.isNotEmpty) {
          province = answer;
        }
        return; // Skip other parsing for location
      }

      // Parse specialties (from multiple choice or single choice)
      if (answer is List) {
        // Multiple choice
        for (var item in answer) {
          if (item is Map) {
            if (item['specialty'] != null) {
              specialties.add(item['specialty'].toString());
            }
            // Also check other criteria in the map
            if (item['design_style'] != null) {
              designStyle = item['design_style'].toString();
            }
            if (item['interior_design'] != null) {
              needsInteriorDesign = item['interior_design'] as bool?;
            }
            if (item['project_capacity'] != null) {
              projectScale = item['project_capacity'].toString();
            }
            if (item['license'] != null) {
              requiresLicense = item['license'] == 'required';
            }
            if (item['delivery'] != null) {
              needsDelivery = item['delivery'] as bool?;
            }
            if (item['warranty'] != null) {
              needsWarranty = item['warranty'] as bool?;
            }
            if (item['quantity'] != null) {
              quantity = item['quantity'].toString();
            }
          }
        }
      } else if (answer is Map) {
        // Single choice
        if (answer['specialty'] != null) {
          specialties.add(answer['specialty'].toString());
        }
        if (answer['design_style'] != null) {
          designStyle = answer['design_style'].toString();
        }
        if (answer['interior_design'] != null) {
          needsInteriorDesign = answer['interior_design'] as bool?;
        }
        if (answer['project_capacity'] != null) {
          projectScale = answer['project_capacity'].toString();
        }
        if (answer['license'] != null) {
          requiresLicense = answer['license'] == 'required';
        }
        if (answer['delivery'] != null) {
          needsDelivery = answer['delivery'] as bool?;
        }
        if (answer['warranty'] != null) {
          needsWarranty = answer['warranty'] as bool?;
        }
        if (answer['quantity'] != null) {
          quantity = answer['quantity'].toString();
        }
      } else if (answer is double || answer is int) {
        // Budget slider (designer_3, contractor_3, store_3)
        if (questionId.contains('_3')) {
          final budget = (answer as num).toDouble();
          minBudget = budget * 0.8; // -20%
          maxBudget = budget * 1.2; // +20%
          if (type == UserAccountType.designer) {
            if (budget < 50) {
              priceRange = '5-30 triệu';
            } else if (budget < 100) {
              priceRange = '10-50 triệu';
            } else {
              priceRange = 'Trên 50 triệu';
            }
          } else if (type == UserAccountType.contractor) {
            priceRange = '${(budget * 0.8).toStringAsFixed(0)} - ${(budget * 1.2).toStringAsFixed(0)} triệu';
          } else if (type == UserAccountType.store) {
            priceRange = '${(budget * 0.8).toStringAsFixed(0)} - ${(budget * 1.2).toStringAsFixed(0)} triệu';
          }
        }
      }
    });

    return SearchCriteria(
      accountType: type,
      specialties: specialties,
      province: province,
      designStyle: designStyle,
      priceRange: priceRange,
      minBudget: minBudget,
      maxBudget: maxBudget,
      needsInteriorDesign: needsInteriorDesign,
      projectType: projectType,
      projectScale: projectScale,
      requiresLicense: requiresLicense,
      needsDelivery: needsDelivery,
      needsWarranty: needsWarranty,
      materialTypes: materialTypes,
      quantity: quantity,
      userLat: userLat,
      userLng: userLng,
      // Tăng maxDistanceKm lên 200km để linh hoạt hơn
      // Nếu không có kết quả, sẽ thử lại không có distance filter
      maxDistanceKm: 200, // Tăng từ 50km lên 200km
    );
  }

  /// Tìm kiếm và tính điểm matching
  static Future<List<SmartSearchResult>> searchAndScore({
    required UserAccountType type,
    required Map<String, dynamic> answers,
    double? userLat,
    double? userLng,
  }) async {
    try {
      // Phân tích answers để tạo criteria
      final criteria = analyzeAnswers(type, answers, userLat, userLng);

      // Tìm kiếm profiles với distance filter
      var profiles = await UserProfileService.searchProfiles(
        accountType: criteria.accountType,
        province: criteria.province,
        specialties: criteria.specialties.isNotEmpty ? criteria.specialties : null,
        userLat: criteria.userLat,
        userLng: criteria.userLng,
        maxDistanceKm: criteria.maxDistanceKm,
        limit: 100, // Giới hạn 100 kết quả
      );

      // Nếu không tìm thấy kết quả với distance filter, thử lại không có distance filter
      // Để hiển thị các profile match về specialties, province nhưng ở xa hơn
      if (profiles.isEmpty && criteria.userLat != null && criteria.userLng != null) {
        print('⚠️ Không tìm thấy kết quả với distance filter, thử lại không có distance filter...');
        profiles = await UserProfileService.searchProfiles(
          accountType: criteria.accountType,
          province: criteria.province,
          specialties: criteria.specialties.isNotEmpty ? criteria.specialties : null,
          userLat: criteria.userLat, // Vẫn truyền để tính distance cho match score
          userLng: criteria.userLng,
          maxDistanceKm: null, // Bỏ distance filter
          limit: 100,
        );
        print('✅ Tìm thấy ${profiles.length} profiles khi bỏ distance filter');
      }

      // Nếu vẫn không có kết quả và có filter province, thử lại không có province filter
      if (profiles.isEmpty && criteria.province != null && criteria.province!.isNotEmpty) {
        print('⚠️ Không tìm thấy kết quả với province filter, thử lại không có province filter...');
        profiles = await UserProfileService.searchProfiles(
          accountType: criteria.accountType,
          province: null, // Bỏ province filter
          specialties: criteria.specialties.isNotEmpty ? criteria.specialties : null,
          userLat: criteria.userLat,
          userLng: criteria.userLng,
          maxDistanceKm: null,
          limit: 100,
        );
        print('✅ Tìm thấy ${profiles.length} profiles khi bỏ province filter');
      }

      // Tính điểm matching cho mỗi profile
      final results = <SmartSearchResult>[];
      for (var profile in profiles) {
        final matchScore = calculateMatchScore(
          profile: profile,
          answers: answers,
          criteria: criteria,
          type: type,
          userLat: userLat,
          userLng: userLng,
        );

        results.add(SmartSearchResult(
          profile: profile,
          matchScore: matchScore,
          matchDetails: _getMatchDetails(profile, criteria),
        ));
      }

      // Sắp xếp theo điểm số (cao → thấp)
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return results;
    } catch (e) {
      print('❌ Error in searchAndScore: $e');
      return [];
    }
  }

  /// Tính điểm matching cho một profile
  static double calculateMatchScore({
    required UserProfile profile,
    required Map<String, dynamic> answers,
    required SearchCriteria criteria,
    required UserAccountType type,
    double? userLat,
    double? userLng,
  }) {
    double totalScore = 0.0;
    double maxPossibleScore = 0.0;

    // 1. Chuyên ngành (Specialties) - 30%
    final specialtyWeight = 30.0;
    maxPossibleScore += specialtyWeight;
    if (criteria.specialties.isNotEmpty) {
      final matchCount = profile.specialties.where((s) =>
          criteria.specialties.any((cs) =>
              s.toLowerCase().contains(cs.toLowerCase()) ||
              cs.toLowerCase().contains(s.toLowerCase()))).length;
      if (matchCount > 0) {
        final matchRatio = matchCount / criteria.specialties.length;
        totalScore += specialtyWeight * matchRatio;
      }
    } else {
      totalScore += specialtyWeight * 0.5; // Nếu không có yêu cầu, cho 50%
    }

    // 2. Vị trí (Location) - 25%
    final locationWeight = 25.0;
    maxPossibleScore += locationWeight;
    if (criteria.province != null && criteria.province!.isNotEmpty) {
      if (profile.province.toLowerCase().contains(criteria.province!.toLowerCase()) ||
          criteria.province!.toLowerCase().contains(profile.province.toLowerCase())) {
        totalScore += locationWeight; // Cùng tỉnh
      } else if (profile.region.isNotEmpty && criteria.province!.isNotEmpty) {
        totalScore += locationWeight * 0.6; // Cùng miền (ước tính)
      } else {
        totalScore += locationWeight * 0.2; // Khác miền
      }
    } else {
      totalScore += locationWeight * 0.5; // Nếu không có yêu cầu
    }

    // 3. Đánh giá (Rating) - 20%
    final ratingWeight = 20.0;
    maxPossibleScore += ratingWeight;
    final ratingScore = (profile.rating / 5.0) * ratingWeight;
    totalScore += ratingScore;

    // 4. Thông tin bổ sung (Additional Info) - 15%
    final additionalWeight = 15.0;
    maxPossibleScore += additionalWeight;
    double additionalScore = 0.0;
    
    if (type == UserAccountType.designer) {
      if (criteria.designStyle != null) {
        final profileStyle = profile.additionalInfo['design_style']?.toString() ?? '';
        if (profileStyle.toLowerCase().contains(criteria.designStyle!.toLowerCase())) {
          additionalScore += 5.0;
        }
      }
      if (criteria.needsInteriorDesign == true) {
        final hasInterior = profile.additionalInfo['interior_design'] == true;
        if (hasInterior) additionalScore += 5.0;
      }
      if (criteria.priceRange != null) {
        final profilePrice = profile.additionalInfo['price_range']?.toString() ?? '';
        if (profilePrice == criteria.priceRange) {
          additionalScore += 5.0;
        }
      }
    } else if (type == UserAccountType.contractor) {
      if (criteria.projectScale != null) {
        final profileScale = profile.additionalInfo['project_capacity']?.toString() ?? '';
        if (profileScale == criteria.projectScale) {
          additionalScore += 5.0;
        }
      }
      if (criteria.requiresLicense == true) {
        final hasLicense = profile.additionalInfo['license']?.toString() ?? '';
        if (hasLicense.isNotEmpty && hasLicense != 'Không có') {
          additionalScore += 5.0;
        }
      }
    } else if (type == UserAccountType.store) {
      if (criteria.needsDelivery == true) {
        final hasDelivery = profile.additionalInfo['delivery']?.toString() ?? '';
        if (hasDelivery.isNotEmpty && hasDelivery != 'Không giao hàng') {
          additionalScore += 5.0;
        }
      }
      if (criteria.needsWarranty == true) {
        final hasWarranty = profile.additionalInfo['warranty']?.toString() ?? '';
        if (hasWarranty.isNotEmpty && hasWarranty != 'Không bảo hành') {
          additionalScore += 5.0;
        }
      }
    }
    
    totalScore += additionalScore;

    // 5. Khoảng cách (Distance) - 10%
    final distanceWeight = 10.0;
    maxPossibleScore += distanceWeight;
    if (userLat != null && userLng != null &&
        LocationService.isValidLocation(profile.latitude, profile.longitude)) {
      final distance = LocationService.calculateDistance(
        userLat,
        userLng,
        profile.latitude,
        profile.longitude,
        silent: true,
      );
      if (distance < 10) {
        totalScore += distanceWeight; // < 10km
      } else if (distance < 50) {
        totalScore += distanceWeight * 0.7; // 10-50km
      } else if (distance < 100) {
        totalScore += distanceWeight * 0.4; // 50-100km
      } else {
        totalScore += distanceWeight * 0.1; // > 100km
      }
    } else {
      totalScore += distanceWeight * 0.5; // Không có location
    }

    // Normalize về 0-100
    final normalizedScore = maxPossibleScore > 0
        ? (totalScore / maxPossibleScore) * 100
        : 0.0;

    return math.min(100.0, math.max(0.0, normalizedScore));
  }

  /// Lấy chi tiết matching
  static Map<String, dynamic> _getMatchDetails(
    UserProfile profile,
    SearchCriteria criteria,
  ) {
    final details = <String, dynamic>{};
    
    if (criteria.specialties.isNotEmpty) {
      final matchedSpecialties = profile.specialties.where((s) =>
          criteria.specialties.any((cs) =>
              s.toLowerCase().contains(cs.toLowerCase()))).toList();
      details['matchedSpecialties'] = matchedSpecialties;
    }
    
    if (criteria.province != null) {
      details['locationMatch'] = profile.province
          .toLowerCase()
          .contains(criteria.province!.toLowerCase());
    }
    
    return details;
  }
}

