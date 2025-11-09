# 🚀 Tính năng Chat Nghiệp vụ - Business Chat Features

## 📋 Tổng quan

Tính năng chat nghiệp vụ giúp người dùng trao đổi hiệu quả hơn trong lĩnh vực xây dựng bằng cách:
- **Liên kết từ tìm kiếm**: Chat được tạo từ Smart Search sẽ có context đặc biệt
- **Quick Actions**: Các hành động nhanh dựa trên loại tài khoản (Designer/Contractor/Store)
- **Business Messages**: Các loại tin nhắn đặc biệt cho nghiệp vụ (báo giá, portfolio, catalog, timeline)

---

## 🎯 Tính năng theo loại tài khoản

### 1. **Nhà thiết kế (Designer)**
- 💰 **Yêu cầu báo giá**: Gửi yêu cầu báo giá với mô tả dự án, ngân sách dự kiến
- 🎨 **Chia sẻ Portfolio**: Chia sẻ hình ảnh công trình đã thiết kế
- 📅 **Hẹn gặp**: Yêu cầu/xác nhận lịch hẹn gặp để trao đổi chi tiết

### 2. **Chủ thầu (Contractor)**
- 💰 **Yêu cầu báo giá**: Gửi yêu cầu báo giá thi công
- 📅 **Timeline dự án**: Chia sẻ timeline và các mốc thời gian của dự án
- 📅 **Hẹn gặp**: Yêu cầu/xác nhận lịch hẹn gặp tại công trường

### 3. **Cửa hàng VLXD (Store)**
- 💰 **Yêu cầu báo giá**: Gửi yêu cầu báo giá vật liệu
- 📦 **Catalog vật liệu**: Chia sẻ danh sách vật liệu có sẵn
- 📅 **Hẹn gặp**: Yêu cầu/xác nhận lịch hẹn gặp để xem vật liệu

---

## 🔧 Cấu trúc đã triển khai

### 1. **Models (`lib/models/chat_model.dart`)**
- ✅ `ChatType` enum: `normal`, `business`
- ✅ `Chat` class: Thêm fields `chatType`, `receiverType`, `searchContext`, `isAutoMessage`
- ✅ `MessageType` enum: Thêm các loại business messages
- ✅ `Message` class: Thêm fields `businessData`, `isAutoMessage`

### 2. **Services**

#### `BusinessChatService` (`lib/services/chat/business_chat_service.dart`)
- ✅ `sendQuoteRequest()`: Gửi yêu cầu báo giá
- ✅ `sendQuoteResponse()`: Phản hồi báo giá
- ✅ `shareMaterialCatalog()`: Chia sẻ catalog vật liệu
- ✅ `sharePortfolio()`: Chia sẻ portfolio (designer)
- ✅ `shareProjectTimeline()`: Chia sẻ timeline dự án (contractor)
- ✅ `sendAppointmentRequest()`: Gửi yêu cầu hẹn gặp
- ✅ `confirmAppointment()`: Xác nhận hẹn gặp
- ✅ `getUserMaterials()`: Lấy danh sách vật liệu của user

#### `AutoMessageService` (đã cập nhật)
- ✅ Lưu business context khi tạo chat từ search:
  - `chatType: 'business'`
  - `receiverType`: Loại tài khoản
  - `searchContext`: Tiêu chí tìm kiếm
  - `isAutoMessage: true`

#### `ChatService` (đã cập nhật)
- ✅ Đọc business context từ Firestore
- ✅ `getChatById()`: Lấy thông tin Chat đầy đủ bao gồm business context
- ✅ `_mapMessage()`: Đọc `businessData` và `isAutoMessage` từ Firestore

---

## 🎨 UI Components cần triển khai

### 1. **Quick Actions Panel** (`ChatDetailScreen`)
Hiển thị các nút hành động nhanh dựa trên `receiverType`:

```dart
// Nhà thiết kế
- Yêu cầu báo giá
- Xem portfolio
- Hẹn gặp

// Chủ thầu
- Yêu cầu báo giá
- Xem timeline dự án
- Hẹn gặp

// Cửa hàng VLXD
- Yêu cầu báo giá
- Xem catalog vật liệu
- Hẹn gặp
```

### 2. **Business Message Widgets** (`MessageBubble`)
Hiển thị các loại business messages đặc biệt:
- Quote Request Card
- Quote Response Card
- Portfolio Gallery
- Project Timeline Card
- Material Catalog Card
- Appointment Card

### 3. **Dialogs/Forms**
- Quote Request Dialog
- Appointment Request Dialog
- Material Catalog Selection Dialog
- Portfolio Selection Dialog

---

## 📝 Các bước triển khai tiếp theo

### Phase 1: Quick Actions Panel (Ưu tiên)
1. ✅ Load chat info trong `ChatDetailScreen.initState()`
2. ⏳ Tạo `_buildQuickActionsPanel()` widget
3. ⏳ Hiển thị panel dựa trên `chat.receiverType`
4. ⏳ Tạo dialogs cho các quick actions

### Phase 2: Business Message Widgets
1. ⏳ Cập nhật `MessageBubble` để hỗ trợ business message types
2. ⏳ Tạo các widget cards cho từng loại message
3. ⏳ Tích hợp với `BusinessChatService`

### Phase 3: Integration & Testing
1. ⏳ Test end-to-end flow
2. ⏳ Polish UI/UX
3. ⏳ Thêm error handling

---

## 🔗 Liên kết với Smart Search

Khi user tìm kiếm và gửi auto message từ `SearchResultsScreen`:
1. `AutoMessageService.sendInterestMessage()` được gọi
2. Chat được tạo với `chatType: 'business'` và `receiverType`
3. `ChatDetailScreen` sẽ hiển thị Quick Actions Panel dựa trên `receiverType`

---

## 💡 Ví dụ sử dụng

### Gửi yêu cầu báo giá:
```dart
await BusinessChatService.sendQuoteRequest(
  chatId: chatId,
  receiverId: receiverId,
  receiverType: UserAccountType.designer,
  projectDescription: 'Thiết kế nhà 2 tầng, diện tích 100m²',
  estimatedBudget: 50.0,
  projectType: 'Nhà ở dân dụng',
);
```

### Chia sẻ catalog vật liệu:
```dart
await BusinessChatService.shareMaterialCatalog(
  chatId: chatId,
  materialIds: ['material1', 'material2', 'material3'],
  category: 'Vật liệu kết dính',
);
```

---

## 🎯 Lợi ích

1. **Trải nghiệm tốt hơn**: Người dùng không cần gõ nhiều, chỉ cần chọn quick action
2. **Chuyên nghiệp**: Các tính năng được tùy chỉnh theo từng loại tài khoản
3. **Hiệu quả**: Trao đổi nhanh chóng, rõ ràng về báo giá, timeline, catalog
4. **Tích hợp**: Liên kết chặt chẽ với Smart Search và các service hiện có

---

## 📚 Files đã tạo/cập nhật

### Đã tạo:
- ✅ `lib/services/chat/business_chat_service.dart`
- ✅ `BUSINESS_CHAT_FEATURES.md` (file này)

### Đã cập nhật:
- ✅ `lib/models/chat_model.dart`
- ✅ `lib/services/chat/auto_message_service.dart`
- ✅ `lib/services/chat/chat_service.dart`

### Cần cập nhật:
- ⏳ `lib/screens/chat/chat_detail_screen.dart` (Thêm Quick Actions Panel)
- ⏳ `lib/components/message_bubble.dart` (Thêm business message widgets)
- ⏳ `lib/screens/search/search_results_screen.dart` (Đảm bảo gửi đúng receiverType)

---

## 🚀 Next Steps

1. **Implement Quick Actions Panel** trong `ChatDetailScreen`
2. **Create Business Message Widgets** trong `MessageBubble`
3. **Create Dialogs** cho các quick actions
4. **Test** end-to-end flow từ Smart Search → Chat → Quick Actions
5. **Polish UI/UX** và thêm animations

---

*Tài liệu này sẽ được cập nhật khi có thêm tính năng mới.*

