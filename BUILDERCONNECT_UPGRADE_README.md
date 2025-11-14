# BuilderConnect Workflow Upgrade - Tài liệu nâng cấp

## Tổng quan

Đề tài BuilderConnect đã được nâng cấp để thể hiện rõ hơn tính "connect" và nghiệp vụ chuyên sâu, tạo ra một luồng làm việc hoàn chỉnh từ tìm kiếm nhà thiết kế → hợp tác thiết kế → gửi thiết kế cho chủ thầu → hợp tác thi công → gửi kế hoạch cho cửa hàng VLXD → hợp tác mua vật liệu.

## Các tính năng đã triển khai

### 1. Mô hình Project Pipeline (`lib/models/project_pipeline.dart`)

Mô hình mới để theo dõi toàn bộ quá trình dự án qua 3 giai đoạn:

- **Giai đoạn Thiết kế (Design)**: Hợp tác với nhà thiết kế
- **Giai đoạn Thi công (Construction)**: Hợp tác với chủ thầu
- **Giai đoạn Vật liệu (Materials)**: Hợp tác với cửa hàng VLXD

**Trạng thái hợp tác:**
- `none`: Chưa hợp tác
- `requested`: Đã yêu cầu hợp tác
- `accepted`: Đã chấp nhận hợp tác
- `inProgress`: Đang hợp tác
- `completed`: Đã hoàn thành
- `cancelled`: Đã hủy

### 2. Pipeline Service (`lib/services/project/pipeline_service.dart`)

Service quản lý toàn bộ vòng đời của pipeline:

**Các chức năng chính:**
- `createPipelineFromDesignerSearch()`: Tạo pipeline khi người dùng kết nối với nhà thiết kế
- `acceptDesignCollaboration()`: Chấp nhận hợp tác thiết kế
- `completeDesign()`: Hoàn thành thiết kế và chuyển sang giai đoạn thi công
- `sendDesignToContractor()`: Gửi thiết kế cho chủ thầu
- `acceptConstructionCollaboration()`: Chấp nhận hợp tác thi công
- `submitConstructionPlan()`: Gửi kế hoạch thi công
- `completeConstruction()`: Hoàn thành thi công và chuyển sang giai đoạn vật liệu
- `sendConstructionPlanToStore()`: Gửi kế hoạch thi công cho cửa hàng VLXD
- `acceptMaterialsCollaboration()`: Chấp nhận hợp tác mua vật liệu
- `completeMaterials()`: Hoàn thành mua vật liệu
- `getPipelineFromChat()`: Lấy pipeline từ chat ID

### 3. Cập nhật Chat Model (`lib/models/chat_model.dart`)

**Thêm các trường mới:**
- `pipelineId`: ID của pipeline nếu chat thuộc về một dự án
- `collaborationStatus`: Trạng thái hợp tác hiện tại

**Thêm các loại tin nhắn mới:**
- `collaborationRequest`: Yêu cầu hợp tác
- `collaborationAccept`: Chấp nhận hợp tác
- `designHandoff`: Gửi thiết kế cho chủ thầu
- `constructionPlanShare`: Gửi kế hoạch thi công cho cửa hàng

### 4. Tích hợp Smart Search với Pipeline (`lib/screens/search/search_results_screen.dart`)

Khi người dùng tìm kiếm nhà thiết kế và nhấn "Kết nối":
- Tự động tạo pipeline mới với trạng thái `requested`
- Lưu metadata từ tìm kiếm (tiêu chí, ngân sách, phong cách, v.v.)
- Liên kết pipeline với chat được tạo

### 5. Cập nhật Chat Service (`lib/services/chat/chat_service.dart`)

**Tự động load thông tin pipeline:**
- Khi load danh sách chat, tự động tìm pipeline liên quan
- Hiển thị trạng thái hợp tác trong chat list
- Cập nhật `getChatById()` và `getChats()` để bao gồm pipeline info

### 6. Chat List với Collaboration Badges (`lib/screens/chat/chat_conversations_screen.dart`)

**Hiển thị badge trạng thái hợp tác:**
- Badge "Đã yêu cầu" (màu cam) khi trạng thái là `requested`
- Badge "Đang hợp tác" (màu xanh lá) khi trạng thái là `accepted` hoặc `inProgress`
- Badge "Hoàn thành" (màu xanh dương) khi trạng thái là `completed`

### 7. Project Dashboard (`lib/screens/manage/project_dashboard_screen.dart`)

Màn hình mới để quản lý tất cả các dự án:

**Tính năng:**
- Hiển thị danh sách tất cả pipeline của người dùng
- Hiển thị tiến độ dự án (X/3 giai đoạn)
- Hiển thị trạng thái từng giai đoạn
- Hiển thị danh sách đối tác (nhà thiết kế, chủ thầu, cửa hàng VLXD)
- Click vào đối tác để mở chat
- Badge giai đoạn hiện tại (Thiết kế/Thi công/Vật liệu)

**Truy cập:**
- Từ màn hình Quản lý vật liệu → Icon Dashboard trên AppBar

## Luồng làm việc (Workflow)

### 1. Tìm kiếm và kết nối với Nhà thiết kế
1. Người dùng vào **Tìm kiếm thông minh**
2. Chọn loại tài khoản: **Nhà thiết kế**
3. Trả lời các câu hỏi về dự án (phong cách, ngân sách, vị trí, v.v.)
4. Xem kết quả tìm kiếm với điểm phù hợp
5. Nhấn **"Kết nối"** với nhà thiết kế phù hợp
6. **Hệ thống tự động:**
   - Tạo pipeline mới với trạng thái `requested`
   - Gửi tin nhắn tự động đến nhà thiết kế
   - Tạo chat business với metadata pipeline

### 2. Hợp tác thiết kế
1. Nhà thiết kế nhận tin nhắn và có thể chấp nhận hợp tác
2. Trạng thái pipeline chuyển sang `accepted` → `inProgress`
3. Chat hiển thị badge "Đang hợp tác"
4. Khi hoàn thành thiết kế:
   - Nhà thiết kế gửi file thiết kế
   - Pipeline chuyển sang giai đoạn **Thi công**
   - Trạng thái thiết kế: `completed`

### 3. Gửi thiết kế cho Chủ thầu
1. Người dùng tìm kiếm **Chủ thầu** trong Smart Search
2. Chọn chủ thầu phù hợp và nhấn "Kết nối"
3. Trong chat với chủ thầu, có nút **"Gửi thiết kế"**
4. Hệ thống:
   - Liên kết chủ thầu với pipeline
   - Gửi file thiết kế đã chốt
   - Chuyển pipeline sang giai đoạn **Thi công**

### 4. Hợp tác thi công
1. Chủ thầu nhận thiết kế và có thể chấp nhận hợp tác
2. Chủ thầu gửi **Kế hoạch thi công** (timeline, chi phí, v.v.)
3. Người dùng xem và chấp nhận
4. Trạng thái: `inProgress`

### 5. Gửi kế hoạch cho Cửa hàng VLXD
1. Người dùng tìm kiếm **Cửa hàng VLXD**
2. Chọn cửa hàng và nhấn "Kết nối"
3. Trong chat, có nút **"Gửi kế hoạch thi công"**
4. Hệ thống:
   - Liên kết cửa hàng với pipeline
   - Gửi kế hoạch thi công
   - Chuyển pipeline sang giai đoạn **Vật liệu**

### 6. Hợp tác mua vật liệu
1. Cửa hàng nhận kế hoạch và có thể chấp nhận hợp tác
2. Cửa hàng gửi **Báo giá vật liệu**
3. Người dùng xem và chấp nhận
4. Trạng thái: `completed`

## Cấu trúc dữ liệu

### ProjectPipeline trong Firestore

Collection: `project_pipelines`

```json
{
  "projectName": "Dự án mới",
  "ownerId": "userId",
  "createdAt": 1234567890,
  "updatedAt": 1234567890,
  "designerId": "designerUserId",
  "designerName": "Tên nhà thiết kế",
  "designStatus": "requested|accepted|inProgress|completed|cancelled",
  "designFileUrl": "url_to_design_file",
  "designCompletedAt": 1234567890,
  "contractorId": "contractorUserId",
  "contractorName": "Tên chủ thầu",
  "constructionStatus": "requested|accepted|inProgress|completed|cancelled",
  "constructionPlanUrl": "url_to_plan",
  "constructionCompletedAt": 1234567890,
  "storeId": "storeUserId",
  "storeName": "Tên cửa hàng",
  "materialsStatus": "requested|accepted|inProgress|completed|cancelled",
  "materialQuoteUrl": "url_to_quote",
  "materialsCompletedAt": 1234567890,
  "searchMetadata": {
    "searchCriteria": "...",
    "budget": 100,
    "style": "..."
  },
  "currentStage": "design|construction|materials"
}
```

## Các file đã tạo mới

1. `lib/models/project_pipeline.dart` - Mô hình pipeline
2. `lib/services/project/pipeline_service.dart` - Service quản lý pipeline
3. `lib/screens/manage/project_dashboard_screen.dart` - Màn hình quản lý dự án

## Các file đã cập nhật

1. `lib/models/chat_model.dart` - Thêm pipeline fields và message types mới
2. `lib/services/chat/chat_service.dart` - Tích hợp pipeline loading
3. `lib/screens/search/search_results_screen.dart` - Tự động tạo pipeline khi kết nối
4. `lib/screens/chat/chat_conversations_screen.dart` - Hiển thị collaboration badges
5. `lib/screens/manage/material_management_screen.dart` - Thêm link đến Project Dashboard

## Hướng dẫn sử dụng

### Cho người dùng thường (chủ dự án):

1. **Bắt đầu dự án:**
   - Vào **Tìm kiếm** → Tab **Tìm kiếm thông minh**
   - Chọn **Nhà thiết kế**
   - Trả lời câu hỏi và tìm nhà thiết kế phù hợp
   - Nhấn **"Kết nối"** để bắt đầu

2. **Theo dõi tiến độ:**
   - Vào **Quản lý** → Icon **Dashboard** (góc trên phải)
   - Xem danh sách tất cả dự án
   - Xem tiến độ và trạng thái từng giai đoạn
   - Click vào đối tác để mở chat

3. **Chuyển giai đoạn:**
   - Sau khi hoàn thành thiết kế, tìm **Chủ thầu** và gửi thiết kế
   - Sau khi có kế hoạch thi công, tìm **Cửa hàng VLXD** và gửi kế hoạch

### Cho nhà thiết kế/chủ thầu/cửa hàng:

1. **Nhận yêu cầu hợp tác:**
   - Xem trong danh sách chat có badge "Đã yêu cầu"
   - Mở chat và chấp nhận hợp tác

2. **Theo dõi dự án tham gia:**
   - Có thể xem các dự án mình đang tham gia (sẽ được thêm trong tương lai)

## Lưu ý kỹ thuật

1. **Performance:**
   - Pipeline được load async khi load chat list
   - Có thể cache pipeline info để tối ưu

2. **Error Handling:**
   - Tất cả pipeline operations đều có try-catch
   - Lỗi pipeline không làm crash chat functionality

3. **Future Enhancements:**
   - Thêm notifications khi có thay đổi pipeline
   - Thêm màn hình xem pipeline cho nhà thiết kế/chủ thầu/cửa hàng
   - Thêm tính năng gửi file thiết kế/kế hoạch trực tiếp trong chat
   - Thêm tính năng chấp nhận/từ chối hợp tác trong chat

## Kết luận

Hệ thống BuilderConnect giờ đây có một luồng làm việc hoàn chỉnh và rõ ràng, thể hiện được tính "connect" giữa các bên liên quan trong ngành xây dựng. Người dùng có thể dễ dàng theo dõi tiến độ dự án và biết mình đang ở giai đoạn nào trong quá trình xây dựng.

