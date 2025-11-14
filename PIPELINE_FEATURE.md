# 📋 Tài liệu tính năng Pipeline dự án

## 📖 Tổng quan

**Pipeline dự án** là một tính năng theo dõi quá trình thực hiện dự án xây dựng từ đầu đến cuối, được chia thành 3 giai đoạn chính:

1. **Thiết kế** (Design) - Hợp tác với nhà thiết kế
2. **Thi công** (Construction) - Hợp tác với chủ thầu
3. **Vật liệu** (Materials) - Hợp tác với cửa hàng VLXD

Pipeline giúp:
- Theo dõi tiến độ dự án từng giai đoạn
- Quản lý hợp tác với các đối tác (designer, contractor, store)
- Lưu trữ thông tin liên quan (file thiết kế, kế hoạch thi công, báo giá vật liệu)
- Tích hợp với chat để trao đổi thông tin

**⚠️ Lưu ý quan trọng:**
- **Search chỉ để tìm kiếm tài khoản phù hợp** - không tạo pipeline ngay
- **Pipeline chỉ được tạo khi cả 2 bên đồng ý hợp tác** trong chat
- **Trao đổi trước, hợp tác sau** - người dùng trao đổi trong chat trước khi bắt đầu hợp tác
- **Nút "Bắt đầu hợp tác"** hiển thị trong Quick Actions Panel khi chưa có pipeline

---

## 🎯 Các thành phần chính

### 1. Pipeline Stage (Giai đoạn)

Pipeline có 3 giai đoạn tuần tự:

```dart
enum PipelineStage {
  design,         // Giai đoạn thiết kế
  construction,   // Giai đoạn thi công
  materials,      // Giai đoạn vật liệu
}
```

- **Design**: Giai đoạn đầu tiên, hợp tác với nhà thiết kế
- **Construction**: Giai đoạn thứ hai, hợp tác với chủ thầu (sau khi hoàn thành thiết kế)
- **Materials**: Giai đoạn cuối cùng, hợp tác với cửa hàng VLXD (sau khi hoàn thành thi công)

### 2. Collaboration Status (Trạng thái hợp tác)

Mỗi giai đoạn có trạng thái hợp tác riêng:

```dart
enum CollaborationStatus {
  none,           // Chưa hợp tác
  requested,      // Đã gửi yêu cầu hợp tác
  accepted,       // Đã chấp nhận hợp tác
  inProgress,     // Đang hợp tác
  completed,      // Đã hoàn thành
  cancelled,      // Đã hủy
}
```

### 3. Project Pipeline Model

Mô hình dữ liệu chính:

```dart
class ProjectPipeline {
  final String id;                    // ID pipeline
  final String projectName;           // Tên dự án
  final String ownerId;               // ID chủ dự án (người tìm kiếm)
  final DateTime createdAt;           // Ngày tạo
  final DateTime? updatedAt;          // Ngày cập nhật
  
  // Giai đoạn thiết kế
  final String? designerId;           // ID nhà thiết kế
  final String? designerName;         // Tên nhà thiết kế
  final CollaborationStatus designStatus;  // Trạng thái hợp tác thiết kế
  final String? designFileUrl;        // File thiết kế đã chốt
  final DateTime? designCompletedAt;  // Ngày hoàn thành thiết kế
  
  // Giai đoạn thi công
  final String? contractorId;         // ID chủ thầu
  final String? contractorName;       // Tên chủ thầu
  final CollaborationStatus constructionStatus;  // Trạng thái hợp tác thi công
  final String? constructionPlanUrl;  // Kế hoạch thi công
  final DateTime? constructionCompletedAt;  // Ngày hoàn thành thi công
  
  // Giai đoạn vật liệu
  final String? storeId;              // ID cửa hàng VLXD
  final String? storeName;            // Tên cửa hàng VLXD
  final CollaborationStatus materialsStatus;  // Trạng thái hợp tác mua vật liệu
  final String? materialQuoteUrl;     // Báo giá vật liệu
  final DateTime? materialsCompletedAt;  // Ngày hoàn thành mua vật liệu
  
  // Metadata
  final Map<String, dynamic>? searchMetadata;  // Tiêu chí tìm kiếm ban đầu
  final PipelineStage currentStage;   // Giai đoạn hiện tại
}
```

---

## 🔄 Flow hoàn chỉnh

### Phase 1: Tìm kiếm và trao đổi (CHƯA tạo Pipeline)

#### Bước 1: User tìm kiếm Designer
```
1. User (owner) vào màn hình Search
2. Chọn loại tìm kiếm: Designer
3. Nhập tiêu chí tìm kiếm (địa điểm, ngân sách, v.v.)
4. Hệ thống hiển thị danh sách Designer phù hợp
5. User chọn Designer và gửi notification
```

**Service:** `SearchNotificationService.sendSearchNotification()`

**Lưu ý:** Search chỉ để tìm kiếm tài khoản phù hợp, KHÔNG tạo pipeline ngay.

#### Bước 2: Designer nhận notification
```
1. Designer nhận notification trong Notifications Screen
2. Notification hiển thị:
   - Tên người gửi
   - Tiêu chí tìm kiếm
   - Loại dịch vụ (Designer)
3. Designer có 2 lựa chọn:
   - Chấp nhận (Accept) - Để trao đổi
   - Từ chối (Reject)
```

#### Bước 3: Designer chấp nhận notification (CHƯA tạo Pipeline)
```
1. Designer nhấn "Chấp nhận"
2. Hệ thống gọi: SearchNotificationService.respondToNotification()
3. KHÔNG tạo pipeline ngay lúc này
4. Chỉ gửi tin nhắn tự động và tạo chat:
   - AutoMessageService.sendInterestMessage()
   - Tạo chat (KHÔNG có pipelineId)
   - Chat được đánh dấu là business chat
5. Owner và Designer trao đổi trong chat
```

**QUAN TRỌNG:** Pipeline sẽ được tạo sau khi cả 2 bên đồng ý hợp tác trong chat.

**Files liên quan:**
- `lib/services/search/search_notification_service.dart` (line 189-221)
- `lib/services/project/pipeline_service.dart` (line 9-41)
- `lib/services/chat/auto_message_service.dart` (line 77-84)

---

### Phase 2: Trao đổi và quyết định hợp tác

#### Bước 4: User mở Chat và trao đổi
```
1. User (owner) mở Chat với Designer
2. ChatDetailScreen được khởi tạo
3. Hệ thống load chat info:
   - ChatService.getChatById()
   - Chat chưa có pipelineId (vì chưa tạo pipeline)
4. Hiển thị Quick Actions Panel:
   - Nút "Bắt đầu hợp tác" (chỉ hiển thị khi chưa có pipeline)
   - Các action khác (Yêu cầu báo giá, Xem Portfolio, v.v.) chỉ hiển thị khi đã có pipeline
5. Owner và Designer trao đổi trong chat
6. Nếu cả 2 đồng ý hợp tác → Click "Bắt đầu hợp tác"
```

#### Bước 5: Bắt đầu hợp tác (Tạo Pipeline)
```
1. User (Owner hoặc Designer) nhấn "Bắt đầu hợp tác"
2. Hiển thị dialog:
   - Hiển thị thông tin đối tác
   - Nhập tên dự án (tùy chọn)
   - Hiển thị lợi ích hợp tác
3. User xác nhận "Bắt đầu hợp tác"
4. Hệ thống tạo Pipeline:
   - PipelineService.createPipelineFromDesignerSearch()
   - designerId = Designer ID
   - designStatus = CollaborationStatus.requested
   - currentStage = PipelineStage.design
5. Cập nhật chat với pipelineId:
   - ChatService.updateChatPipelineId()
   - Lưu pipelineId vào chat document
6. Reload pipeline và chat info
7. Hiển thị Pipeline Status Panel trong ChatDetailScreen
```

**UI Components:**
- Pipeline Status Panel (`_buildPipelineStatusPanel()`)
  - Tên dự án
  - Giai đoạn hiện tại (Thiết kế/Thi công/Vật liệu)
  - Trạng thái hợp tác
  - Progress indicator (3 giai đoạn)
  - Action buttons (nếu cần)

**Files liên quan:**
- `lib/screens/chat/chat_detail_screen.dart` (line 2037-2408)
- `lib/services/chat/chat_service.dart` (line 748-793)

---

### Phase 3: Hiển thị Pipeline và Collaboration Actions

#### Bước 6: Hiển thị Pipeline trong Chat
```
1. User mở Chat sau khi đã tạo pipeline
2. ChatDetailScreen load pipeline:
   - ChatService.getChatById() → Đọc pipelineId từ chat document
   - PipelineService.getPipeline(pipelineId) → Load pipeline details
3. Hiển thị Pipeline Status Panel:
   - Tên dự án
   - Giai đoạn hiện tại (Thiết kế/Thi công/Vật liệu)
   - Trạng thái hợp tác
   - Progress indicator (3 giai đoạn)
4. Hiển thị Quick Actions Panel:
   - Các action buttons (Yêu cầu báo giá, Xem Portfolio, v.v.)
   - Chỉ hiển thị khi đã có pipeline
```

#### Bước 7: Designer xem Pipeline và chấp nhận
```
1. Designer mở Chat với Owner
2. Hệ thống load pipeline
3. Kiểm tra collaboration status:
   - designStatus = CollaborationStatus.requested
   - designerId = Designer's currentUserId
4. Hiển thị Action Buttons trong Pipeline Status Panel:
   - "Chấp nhận" (Accept)
   - "Từ chối" (Reject)
```

#### Bước 8: Designer chấp nhận hợp tác
```
1. Designer nhấn "Chấp nhận"
2. Hệ thống gọi: PipelineService.acceptDesignCollaboration()
3. Cập nhật pipeline:
   - designStatus = CollaborationStatus.accepted
   - updatedAt = DateTime.now()
4. Reload pipeline và chat info
5. UI cập nhật:
   - Status thay đổi từ "requested" → "accepted"
   - Action buttons biến mất
   - Progress indicator cập nhật
```

**Files liên quan:**
- `lib/services/project/pipeline_service.dart` (line 131-143)
- `lib/screens/chat/chat_detail_screen.dart` (line 2325-2360)

---

### Phase 4: Hoàn thành giai đoạn và chuyển giai đoạn

#### Bước 9: Designer hoàn thành thiết kế
```
1. Designer upload file thiết kế
2. Hệ thống gọi: PipelineService.completeDesign()
3. Cập nhật pipeline:
   - designStatus = CollaborationStatus.completed
   - designFileUrl = URL file thiết kế
   - designCompletedAt = DateTime.now()
   - currentStage = PipelineStage.construction
4. Pipeline chuyển sang giai đoạn Thi công
```

#### Bước 10: Owner tìm Contractor
```
1. Owner tìm kiếm Contractor
2. Chọn Contractor và gửi notification
3. Contractor chấp nhận
4. Hệ thống gọi: PipelineService.sendDesignToContractor()
5. Cập nhật pipeline:
   - contractorId = Contractor ID
   - contractorName = Contractor Name
   - constructionStatus = CollaborationStatus.requested
   - currentStage = PipelineStage.construction
```

#### Bước 11: Contractor chấp nhận và hoàn thành thi công
```
1. Contractor chấp nhận hợp tác
2. PipelineService.acceptConstructionCollaboration()
3. Contractor gửi kế hoạch thi công
4. PipelineService.submitConstructionPlan()
5. Contractor hoàn thành thi công
6. PipelineService.completeConstruction()
7. Pipeline chuyển sang giai đoạn Vật liệu
```

#### Bước 12: Owner tìm Store và hoàn thành
```
1. Owner tìm kiếm Store
2. Store chấp nhận và gửi báo giá
3. PipelineService.sendConstructionPlanToStore()
4. Store chấp nhận hợp tác
5. PipelineService.acceptMaterialsCollaboration()
6. Store hoàn thành mua vật liệu
7. PipelineService.completeMaterials()
8. Pipeline hoàn thành tất cả giai đoạn
```

---

## 📊 Sơ đồ Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: Tìm kiếm và trao đổi             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Owner tìm kiếm Designer        │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Gửi Search Notification        │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Designer nhận Notification     │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Designer chấp nhận?            │
        └─────────────────────────────────┘
                    │            │
            YES     │            │    NO
                    ▼            ▼
    ┌───────────────────┐   ┌──────────┐
    │ Gửi Auto Message  │   │ Rejected │
    │ Tạo Chat          │   │ (End)    │
    │ (KHÔNG có         │   └──────────┘
    │  pipelineId)      │
    └───────────────────┘
                    │
                    ▼
    ┌─────────────────────────────────┐
    │  Owner và Designer trao đổi     │
    │  trong Chat                     │
    └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Cả 2 đồng ý hợp tác?           │
        └─────────────────────────────────┘
                    │
            YES     │
                    ▼
    ┌─────────────────────────────────┐
    │  Click "Bắt đầu hợp tác"        │
    │  Tạo Pipeline                   │
    │  designStatus = requested       │
    └─────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    PHASE 2: Bắt đầu hợp tác                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  User mở Chat                   │
        │  (Chưa có pipeline)             │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Hiển thị Quick Actions Panel   │
        │  - Nút "Bắt đầu hợp tác"        │
        │  - Các action khác (ẩn)         │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Click "Bắt đầu hợp tác"        │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Dialog: Nhập tên dự án         │
        │  (tùy chọn)                     │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Tạo Pipeline                   │
        │  Cập nhật chat với pipelineId   │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Hiển thị Pipeline Status Panel │
        │  - Tên dự án                    │
        │  - Giai đoạn hiện tại           │
        │  - Trạng thái hợp tác           │
        │  - Progress indicator           │
        │  - Action buttons (nếu cần)      │
        └─────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    PHASE 3: Collaboration                    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Designer xem Pipeline          │
        │  designStatus = requested       │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Hiển thị Action Buttons        │
        │  - Chấp nhận                    │
        │  - Từ chối                      │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Designer chấp nhận?            │
        └─────────────────────────────────┘
                    │            │
            YES     │            │    NO
                    ▼            ▼
    ┌───────────────────┐   ┌──────────┐
    │ designStatus =    │   │ (End)    │
    │ accepted          │   └──────────┘
    └───────────────────┘
                    │
                    ▼
    ┌─────────────────────────────────┐
    │  Designer hoàn thành thiết kế   │
    │  designStatus = completed       │
    │  currentStage = construction    │
    └─────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    PHASE 4: Chuyển giai đoạn                 │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Owner tìm Contractor           │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Contractor chấp nhận           │
        │  constructionStatus = requested │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Contractor hoàn thành thi công │
        │  constructionStatus = completed │
        │  currentStage = materials       │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Owner tìm Store                │
        └─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │  Store chấp nhận và hoàn thành  │
        │  materialsStatus = completed    │
        │  Pipeline hoàn thành            │
        └─────────────────────────────────┘
```

---

## 🗂️ Cấu trúc dữ liệu trong Firestore

### Collection: `project_pipelines`

```json
{
  "id": "pipeline_abc123",
  "projectName": "Dự án mới",
  "ownerId": "user_123",
  "createdAt": 1700000000000,
  "updatedAt": 1700000000000,
  
  "designerId": "designer_456",
  "designerName": "Nguyễn Văn A",
  "designStatus": "requested",
  "designFileUrl": "https://...",
  "designCompletedAt": null,
  
  "contractorId": null,
  "contractorName": null,
  "constructionStatus": "none",
  "constructionPlanUrl": null,
  "constructionCompletedAt": null,
  
  "storeId": null,
  "storeName": null,
  "materialsStatus": "none",
  "materialQuoteUrl": null,
  "materialsCompletedAt": null,
  
  "searchMetadata": {
    "searchCriteria": "Nhà phố 2 tầng, Hà Nội",
    "searchedType": "designer",
    "notificationId": "notif_789"
  },
  "currentStage": "design"
}
```

### Collection: `chats`

```json
{
  "id": "user_123_designer_456",
  "participants": ["designer_456", "user_123"],
  "lastMessage": "Chào bạn! 👋",
  "lastMessageTime": 1700000000000,
  "chatType": "business",
  "receiverType": "UserAccountType.designer",
  "searchContext": "Nhà phố 2 tầng, Hà Nội",
  "isAutoMessage": true,
  "pipelineId": "pipeline_abc123"
}
```

---

## 🎨 UI/UX Components

### 1. Pipeline Status Panel

**Vị trí:** Hiển thị ở đầu `ChatDetailScreen`, trên Quick Actions Panel

**Thành phần:**
- **Header**: Icon pipeline + "Pipeline dự án" + Status icon
- **Project Name**: Tên dự án
- **Stage Badge**: Badge hiển thị giai đoạn hiện tại (Thiết kế/Thi công/Vật liệu)
- **Status Description**: Mô tả trạng thái hợp tác
- **Progress Indicator**: 3 icon hiển thị tiến độ 3 giai đoạn
  - ✅ Completed (màu xanh)
  - 🔵 Active/Current (màu xanh dương)
  - ⚪ Not started (màu xám)
- **Action Buttons**: Chấp nhận/Từ chối (chỉ hiển thị khi cần)

**Màu sắc theo status:**
- `none`: Xám
- `requested`: Cam
- `accepted`: Xanh dương
- `inProgress`: Xanh dương đậm
- `completed`: Xanh lá
- `cancelled`: Đỏ

### 2. Progress Indicator

Hiển thị 3 giai đoạn với icon và màu sắc:
- **Thiết kế**: Icon + label
- **Thi công**: Icon + label
- **Vật liệu**: Icon + label

Mỗi giai đoạn có thể ở trạng thái:
- Chưa bắt đầu (xám)
- Đang thực hiện (xanh dương)
- Đã hoàn thành (xanh lá)

---

## 🔧 Service Methods

### PipelineService

#### 1. Tạo Pipeline
```dart
Future<String?> createPipelineFromDesignerSearch({
  required String designerId,
  required String designerName,
  required Map<String, dynamic> searchMetadata,
  String? projectName,
})
```

#### 2. Lấy Pipeline
```dart
Future<ProjectPipeline?> getPipeline(String pipelineId)
Future<List<ProjectPipeline>> getUserPipelines()
Future<List<ProjectPipeline>> getParticipatingPipelines()
Future<ProjectPipeline?> getPipelineFromChat(String chatId)
```

#### 3. Collaboration Actions
```dart
// Design
Future<bool> acceptDesignCollaboration(String pipelineId)
Future<bool> completeDesign({required String pipelineId, required String designFileUrl})

// Construction
Future<bool> sendDesignToContractor({required String pipelineId, required String contractorId, required String contractorName})
Future<bool> acceptConstructionCollaboration(String pipelineId)
Future<bool> submitConstructionPlan({required String pipelineId, required String planUrl})
Future<bool> completeConstruction({required String pipelineId})

// Materials
Future<bool> sendConstructionPlanToStore({required String pipelineId, required String storeId, required String storeName})
Future<bool> acceptMaterialsCollaboration(String pipelineId)
Future<bool> completeMaterials({required String pipelineId, required String quoteUrl})
```

---

## 📱 User Experience Flow

### Scenario 1: Owner tìm Designer

1. **Owner** vào Search Screen
2. Chọn "Nhà thiết kế"
3. Tìm kiếm và chọn Designer
4. Gửi notification
5. **Designer** nhận notification
6. **Designer** chấp nhận
7. Chat được tạo (CHƯA có pipelineId)
8. **Owner** và **Designer** trao đổi trong chat
9. Cả 2 đồng ý hợp tác → **Owner** hoặc **Designer** nhấn "Bắt đầu hợp tác"
10. Pipeline được tạo với `designStatus = requested`
11. Chat được cập nhật với `pipelineId`
12. **Owner** mở Chat → Thấy Pipeline Status Panel
13. **Designer** mở Chat → Thấy Action Buttons (Chấp nhận/Từ chối)
14. **Designer** chấp nhận → Status thay đổi
15. **Designer** hoàn thành thiết kế → Chuyển sang giai đoạn Thi công

### Scenario 2: Owner tìm Contractor (sau khi hoàn thành thiết kế)

1. **Owner** tìm kiếm Contractor
2. Chọn Contractor và gửi notification
3. **Contractor** chấp nhận
4. Pipeline cập nhật:
   - `contractorId` = Contractor ID
   - `constructionStatus` = `requested`
   - `currentStage` = `construction`
5. **Contractor** mở Chat → Thấy Pipeline Status Panel
6. **Contractor** chấp nhận → Bắt đầu hợp tác thi công
7. **Contractor** hoàn thành → Chuyển sang giai đoạn Vật liệu

### Scenario 3: Owner tìm Store (sau khi hoàn thành thi công)

1. **Owner** tìm kiếm Store
2. Chọn Store và gửi notification
3. **Store** chấp nhận
4. Pipeline cập nhật:
   - `storeId` = Store ID
   - `materialsStatus` = `requested`
   - `currentStage` = `materials`
5. **Store** mở Chat → Thấy Pipeline Status Panel
6. **Store** chấp nhận → Bắt đầu hợp tác mua vật liệu
7. **Store** hoàn thành → Pipeline hoàn thành tất cả giai đoạn

---

## 🔍 Debugging và Logging

### Log Messages

Pipeline sử dụng các log messages để debug:

- `✅ Pipeline created with ID: {pipelineId}`
- `✅ Pipeline loaded: {projectName}, stage: {currentStage}`
- `✅ Found pipelineId in chat document: {pipelineId}`
- `⚠️ Pipeline not found: {pipelineId}`
- `❌ Error loading pipeline: {error}`

### Kiểm tra Pipeline trong Firestore

1. Mở Firestore Console
2. Vào collection `project_pipelines`
3. Tìm pipeline theo `pipelineId`
4. Kiểm tra các fields:
   - `designStatus`, `constructionStatus`, `materialsStatus`
   - `currentStage`
   - `designerId`, `contractorId`, `storeId`
   - `pipelineId` trong chat document

---

## 🚀 Tính năng tương lai (Future Enhancements)

1. **Timeline View**: Hiển thị timeline chi tiết của từng giai đoạn
2. **File Management**: Quản lý file thiết kế, kế hoạch thi công, báo giá
3. **Notifications**: Thông báo khi pipeline thay đổi trạng thái
4. **Analytics**: Thống kê tiến độ, thời gian hoàn thành
5. **Multi-stage Pipeline**: Hỗ trợ nhiều giai đoạn phụ
6. **Collaboration History**: Lịch sử hợp tác với từng đối tác
7. **Rating System**: Đánh giá đối tác sau khi hoàn thành

---

## 📝 Tóm tắt

Pipeline dự án là một tính năng quan trọng giúp:
- ✅ Theo dõi tiến độ dự án từng giai đoạn
- ✅ Quản lý hợp tác với các đối tác
- ✅ Lưu trữ thông tin liên quan
- ✅ Tích hợp với chat để trao đổi thông tin
- ✅ Tạo pipeline khi cả 2 bên đồng ý hợp tác (không tự động)
- ✅ Hiển thị trực quan trong Chat Detail Screen
- ✅ Hỗ trợ các action buttons để chấp nhận/từ chối hợp tác

**Flow chính:**
1. **Tìm kiếm** → Gửi notification (chỉ để tìm tài khoản phù hợp)
2. **Chấp nhận** → Tạo chat (CHƯA có pipeline)
3. **Trao đổi** → Owner và Designer trao đổi trong chat
4. **Bắt đầu hợp tác** → Click "Bắt đầu hợp tác" → Tạo pipeline
5. **Hiển thị** → Pipeline Status Panel trong Chat
6. **Collaboration** → Chấp nhận/Từ chối hợp tác
7. **Hoàn thành** → Chuyển sang giai đoạn tiếp theo

**QUAN TRỌNG:**
- Search chỉ để tìm kiếm tài khoản phù hợp
- Pipeline KHÔNG được tạo tự động khi chấp nhận notification
- Pipeline chỉ được tạo khi cả 2 bên đồng ý hợp tác trong chat
- Nút "Bắt đầu hợp tác" hiển thị trong Quick Actions Panel khi chưa có pipeline

---

## 📚 Files liên quan

### Models
- `lib/models/project_pipeline.dart`

### Services
- `lib/services/project/pipeline_service.dart`
- `lib/services/search/search_notification_service.dart`
- `lib/services/chat/auto_message_service.dart`
- `lib/services/chat/chat_service.dart`

### Screens
- `lib/screens/chat/chat_detail_screen.dart`
- `lib/screens/manage/project_dashboard_screen.dart`

### Components
- Pipeline Status Panel (trong `chat_detail_screen.dart`)
- Progress Indicator (trong `chat_detail_screen.dart`)
- Action Buttons (trong `chat_detail_screen.dart`)

---

**Tác giả:** BuilderConnect Team  
**Ngày tạo:** 2025-01-13  
**Phiên bản:** 1.0.0

