# KẾ HOẠCH TRIỂN KHAI SMART SEARCH SCREEN

## 📋 TỔNG QUAN

Tạo một screen mới cho phép người dùng trả lời các câu hỏi về nhu cầu của họ, sau đó hệ thống sẽ tìm kiếm và hiển thị danh sách tài khoản phù hợp nhất dựa trên câu trả lời.

---

## 🎯 MỤC TIÊU

1. **Tạo trải nghiệm tìm kiếm thông minh và tương tác**
2. **Giúp người dùng dễ dàng mô tả nhu cầu của mình**
3. **Tự động match và sắp xếp kết quả theo độ phù hợp**
4. **Tạo điểm khác biệt so với các ứng dụng tìm kiếm thông thường**

---

## 🏗️ KIẾN TRÚC GIẢI PHÁP

### 1. CẤU TRÚC FILE

```
lib/
├── models/
│   ├── smart_search_question.dart       # Model cho câu hỏi
│   └── smart_search_result.dart         # Model cho kết quả với điểm số
├── screens/
│   └── search/
│       ├── smart_search_screen.dart     # Screen chính - câu hỏi
│       └── smart_search_results_screen.dart  # Screen hiển thị kết quả
└── services/
    └── search/
        └── smart_search_service.dart    # Logic tính điểm và matching
```

### 2. LUỒNG HOẠT ĐỘNG

```
1. User mở SmartSearchScreen
   ↓
2. Chọn loại tài khoản cần tìm (Designer/Contractor/Store)
   ↓
3. Trả lời các câu hỏi tương tác (5-7 câu hỏi)
   ↓
4. Hệ thống phân tích câu trả lời và tạo search criteria
   ↓
5. Tìm kiếm và tính điểm matching cho mỗi profile
   ↓
6. Sắp xếp kết quả theo điểm số (cao → thấp)
   ↓
7. Hiển thị kết quả trong SmartSearchResultsScreen
   ↓
8. User có thể:
   - Xem chi tiết profile
   - Gửi tin nhắn tự động (smart connection)
   - Lưu vào danh sách yêu thích
```

---

## 📝 CHI TIẾT TRIỂN KHAI

### 1. MODEL - SmartSearchQuestion

```dart
class SmartSearchQuestion {
  final String id;
  final String question;           // Câu hỏi hiển thị
  final QuestionType type;         // Loại câu hỏi (single, multiple, slider, location)
  final List<QuestionOption> options;  // Các lựa chọn (nếu có)
  final String? hint;              // Gợi ý
  final int weight;                // Trọng số (1-10) - quan trọng bao nhiêu
  final UserAccountType targetType; // Loại tài khoản nào cần câu hỏi này
}

enum QuestionType {
  singleChoice,    // Chọn 1 đáp án
  multipleChoice,  // Chọn nhiều đáp án
  slider,          // Slider (ví dụ: khoảng giá, bán kính)
  text,            // Nhập text
  location,        // Chọn vị trí
}

class QuestionOption {
  final String id;
  final String label;
  final Map<String, dynamic> criteria; // Tiêu chí tương ứng
}
```

### 2. CÂU HỎI MẪU

#### A. CHO NHÀ THIẾT KẾ (Designer)

**Câu hỏi 1: Loại dự án bạn cần thiết kế?**
- Type: Multiple Choice
- Options:
  - Nhà ở dân dụng
  - Biệt thự
  - Chung cư
  - Văn phòng
  - Công trình công cộng
  - Khác

**Câu hỏi 2: Phong cách thiết kế bạn ưa thích?**
- Type: Single Choice
- Options:
  - Hiện đại
  - Cổ điển
  - Tối giản
  - Đông Dương
  - Không quan trọng

**Câu hỏi 3: Ngân sách dự kiến?**
- Type: Slider
- Range: 5 triệu - 200 triệu
- Default: 50 triệu

**Câu hỏi 4: Vị trí dự án?**
- Type: Location
- Options: Chọn tỉnh/thành phố

**Câu hỏi 5: Bạn có cần thiết kế nội thất không?**
- Type: Single Choice (Yes/No)

**Câu hỏi 6: Thời gian hoàn thành mong muốn?**
- Type: Single Choice
- Options:
  - < 1 tháng
  - 1-3 tháng
  - 3-6 tháng
  - > 6 tháng

#### B. CHO CHỦ THẦU (Contractor)

**Câu hỏi 1: Loại công trình cần thi công?**
- Type: Multiple Choice
- Options:
  - Nhà ở
  - Chung cư
  - Công trình công cộng
  - Công nghiệp
  - Khác

**Câu hỏi 2: Quy mô dự án?**
- Type: Single Choice
- Options:
  - Nhỏ (< 100m²)
  - Trung bình (100-500m²)
  - Lớn (500-2000m²)
  - Rất lớn (> 2000m²)

**Câu hỏi 3: Ngân sách dự kiến?**
- Type: Slider
- Range: 100 triệu - 10 tỷ

**Câu hỏi 4: Yêu cầu về giấy phép?**
- Type: Single Choice
- Options:
  - Có giấy phép hành nghề
  - Không yêu cầu
  - Ưu tiên có giấy phép

**Câu hỏi 5: Vị trí dự án?**
- Type: Location

**Câu hỏi 6: Thời gian thi công mong muốn?**
- Type: Single Choice
- Options:
  - < 3 tháng
  - 3-6 tháng
  - 6-12 tháng
  - > 12 tháng

#### C. CHO CỬA HÀNG VLXD (Store)

**Câu hỏi 1: Loại vật liệu cần mua?**
- Type: Multiple Choice
- Options:
  - Xi măng
  - Gạch
  - Sắt thép
  - Gỗ
  - Sơn
  - Thiết bị vệ sinh
  - Khác

**Câu hỏi 2: Số lượng dự kiến?**
- Type: Single Choice
- Options:
  - Nhỏ lẻ
  - Trung bình
  - Số lượng lớn
  - Rất lớn

**Câu hỏi 3: Ngân sách?**
- Type: Slider
- Range: 10 triệu - 1 tỷ

**Câu hỏi 4: Yêu cầu giao hàng?**
- Type: Single Choice
- Options:
  - Có giao hàng
  - Tự vận chuyển
  - Không quan trọng

**Câu hỏi 5: Yêu cầu bảo hành?**
- Type: Single Choice (Yes/No)

**Câu hỏi 6: Vị trí?**
- Type: Location

---

### 3. LOGIC TÍNH ĐIỂM MATCHING

#### A. Công thức tính điểm

```dart
Total Score = Σ (Question Weight × Answer Match Score)

Trong đó:
- Question Weight: Trọng số của câu hỏi (1-10)
- Answer Match Score: Điểm khớp của câu trả lời (0-1)
```

#### B. Các yếu tố tính điểm

1. **Chuyên ngành (Specialties)**: 30%
   - Nếu profile có chuyên ngành khớp với câu trả lời → +30 điểm
   - Một phần khớp → +15 điểm

2. **Vị trí (Location)**: 25%
   - Cùng tỉnh/thành → +25 điểm
   - Cùng miền → +15 điểm
   - Khác miền → +5 điểm
   - Có tính khoảng cách (gần hơn = điểm cao hơn)

3. **Đánh giá (Rating)**: 20%
   - Rating cao → điểm cao
   - Công thức: (rating / 5) × 20

4. **Thông tin bổ sung (Additional Info)**: 15%
   - Giấy phép, kinh nghiệm, quy mô, etc.
   - Khớp với yêu cầu → +15 điểm

5. **Khoảng cách (Distance)**: 10%
   - Gần hơn → điểm cao hơn
   - Công thức: max(0, 10 - (distance / 10))

#### C. Ví dụ tính điểm

**User trả lời:**
- Loại dự án: Nhà ở dân dụng, Biệt thự
- Phong cách: Hiện đại
- Ngân sách: 50 triệu
- Vị trí: TP.HCM
- Cần thiết kế nội thất: Yes

**Profile A (Nhà thiết kế):**
- Specialties: ["Nhà ở dân dụng", "Biệt thự"] → 30 điểm
- Location: TP.HCM → 25 điểm
- Rating: 4.5/5 → 18 điểm
- Additional Info: {style: "Hiện đại", interior: true} → 15 điểm
- Distance: 5km → 9.5 điểm
- **Tổng: 97.5 điểm**

**Profile B (Nhà thiết kế):**
- Specialties: ["Chung cư"] → 0 điểm
- Location: Hà Nội → 5 điểm
- Rating: 4.8/5 → 19.2 điểm
- Additional Info: {style: "Cổ điển"} → 0 điểm
- Distance: 1730km → 0 điểm
- **Tổng: 24.2 điểm**

→ Profile A sẽ được hiển thị trước Profile B

---

### 4. UI/UX DESIGN

#### A. SmartSearchScreen

**Layout:**
- AppBar: "Tìm kiếm thông minh" với nút Back
- Progress indicator: Hiển thị tiến độ (Câu hỏi X/6)
- Question Card: Hiển thị câu hỏi hiện tại
- Answer Options: Radio buttons, Checkboxes, Slider, etc.
- Navigation: Nút "Tiếp theo" / "Quay lại" / "Bỏ qua"

**Features:**
- Animation khi chuyển câu hỏi
- Validation (một số câu hỏi bắt buộc)
- Auto-save answers (nếu user quay lại)
- Preview answers trước khi submit

#### B. SmartSearchResultsScreen

**Layout:**
- AppBar: "Kết quả tìm kiếm" với số lượng kết quả
- Filter bar: Có thể filter thêm (nếu cần)
- Result cards: Hiển thị từng profile với:
  - Avatar, Tên, Loại tài khoản
  - Điểm matching (ví dụ: "95% phù hợp")
  - Thông tin nổi bật (chuyên ngành, vị trí, rating)
  - Khoảng cách
  - Nút "Kết nối" (gửi tin nhắn tự động)

**Features:**
- Sort by: Điểm matching, Khoảng cách, Rating
- Pull to refresh
- Infinite scroll (nếu có nhiều kết quả)
- Empty state với gợi ý

---

### 5. SERVICE - SmartSearchService

```dart
class SmartSearchService {
  // Lấy danh sách câu hỏi theo loại tài khoản
  static List<SmartSearchQuestion> getQuestions(UserAccountType type);
  
  // Phân tích câu trả lời và tạo search criteria
  static SearchCriteria analyzeAnswers(
    UserAccountType type,
    Map<String, dynamic> answers
  );
  
  // Tìm kiếm và tính điểm matching
  static Future<List<SmartSearchResult>> searchAndScore({
    required UserAccountType type,
    required Map<String, dynamic> answers,
    double? userLat,
    double? userLng,
  });
  
  // Tính điểm matching cho một profile
  static double calculateMatchScore({
    required UserProfile profile,
    required Map<String, dynamic> answers,
    required UserAccountType type,
    double? userLat,
    double? userLng,
  });
}
```

---

### 6. TÍCH HỢP VỚI SEARCH SCREEN HIỆN TẠI

**Cách tích hợp:**
1. Thêm nút "Tìm kiếm thông minh" vào SearchScreen
2. Khi user click → Navigate đến SmartSearchScreen
3. Sau khi trả lời xong → Navigate đến SmartSearchResultsScreen
4. Từ SmartSearchResultsScreen → Có thể gửi tin nhắn tự động (dùng AutoMessageService hiện có)

---

## 🚀 CÁC BƯỚC TRIỂN KHAI

### Phase 1: Models & Data (1-2 giờ)
1. ✅ Tạo `SmartSearchQuestion` model
2. ✅ Tạo `SmartSearchResult` model
3. ✅ Tạo danh sách câu hỏi mẫu
4. ✅ Tạo `SearchCriteria` model

### Phase 2: Service Logic (2-3 giờ)
1. ✅ Tạo `SmartSearchService`
2. ✅ Implement logic tính điểm matching
3. ✅ Implement logic phân tích câu trả lời
4. ✅ Test logic với dữ liệu mẫu

### Phase 3: UI Screens (3-4 giờ)
1. ✅ Tạo `SmartSearchScreen` với UI câu hỏi
2. ✅ Implement navigation giữa các câu hỏi
3. ✅ Tạo `SmartSearchResultsScreen`
4. ✅ Implement hiển thị kết quả với điểm số

### Phase 4: Integration (1-2 giờ)
1. ✅ Tích hợp vào SearchScreen
2. ✅ Kết nối với AutoMessageService
3. ✅ Test end-to-end
4. ✅ Polish UI/UX

---

## 📊 DỮ LIỆU CẦN THIẾT

### Từ UserProfile:
- `accountType`: Loại tài khoản
- `specialties`: Chuyên ngành
- `province`: Tỉnh/thành phố
- `region`: Miền
- `latitude`, `longitude`: Vị trí
- `rating`: Đánh giá
- `reviewCount`: Số đánh giá
- `additionalInfo`: Thông tin bổ sung
  - `design_style`: Phong cách thiết kế
  - `license`: Giấy phép
  - `project_capacity`: Quy mô dự án
  - `delivery`: Có giao hàng không
  - `warranty`: Có bảo hành không
  - etc.

---

## 🎨 ĐIỂM NỔI BẬT

1. **Trải nghiệm tương tác**: Thay vì filter phức tạp, user chỉ cần trả lời câu hỏi đơn giản
2. **Kết quả thông minh**: Tự động sắp xếp theo độ phù hợp, không chỉ theo khoảng cách
3. **Gợi ý chính xác**: Dựa trên nhiều yếu tố, không chỉ location
4. **Dễ sử dụng**: UI/UX đơn giản, dễ hiểu
5. **Tích hợp tốt**: Kết nối với tính năng chat tự động

---

## ❓ CÂU HỎI THƯỜNG GẶP

**Q: Tại sao cần tính điểm matching thay vì chỉ filter?**
A: Để hiển thị kết quả phù hợp nhất trước, giúp user tìm được đúng người cần tìm nhanh hơn.

**Q: Có thể tùy chỉnh trọng số của câu hỏi không?**
A: Có, trọng số có thể điều chỉnh dựa trên feedback của user.

**Q: Nếu không có kết quả nào khớp 100% thì sao?**
A: Hệ thống vẫn hiển thị các kết quả có điểm cao nhất, và cho phép user filter thêm nếu cần.

**Q: Có thể lưu câu trả lời để dùng lại không?**
A: Có thể thêm tính năng này trong tương lai (save search preferences).

---

**Tài liệu này sẽ được cập nhật khi có thêm thông tin hoặc thay đổi.**

