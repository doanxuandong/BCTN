# 📚 HƯỚNG DẪN SỬ DỤNG TÍNH NĂNG BUSINESS CHAT

## 📋 TỔNG QUAN

Tính năng **Business Chat** đã được tích hợp vào ứng dụng BuilderConnect, cho phép người dùng:
- Gửi tin nhắn tự động khi tìm kiếm và quan tâm đến một profile
- Sử dụng các tính năng nghiệp vụ chuyên biệt trong chat (báo giá, portfolio, timeline, catalog vật liệu, hẹn gặp)
- Xem chi tiết các business messages (portfolio gallery, timeline, material catalog)

---

## 🎯 CÁC TÍNH NĂNG CHÍNH

### 1. **Auto Message từ Smart Search**
- Khi người dùng tìm kiếm thông minh và nhấn "Kết nối", hệ thống tự động gửi tin nhắn quan tâm
- Chat được tạo với business context (loại tài khoản, tiêu chí tìm kiếm)

### 2. **Quick Actions Panel**
- Panel hiển thị các thao tác nhanh dựa trên loại tài khoản người nhận:
  - **Nhà thiết kế**: Yêu cầu báo giá, Xem Portfolio, Hẹn gặp
  - **Chủ thầu**: Yêu cầu báo giá, Timeline dự án, Hẹn gặp
  - **Cửa hàng VLXD**: Yêu cầu báo giá, Xem Catalog, Hẹn gặp

### 3. **Business Message Types**
- **Quote Request**: Yêu cầu báo giá dự án
- **Quote Response**: Phản hồi báo giá
- **Portfolio Share**: Chia sẻ portfolio (nhiều ảnh)
- **Project Timeline**: Chia sẻ timeline dự án với các mốc thời gian
- **Material Catalog**: Chia sẻ catalog vật liệu
- **Appointment Request**: Yêu cầu hẹn gặp
- **Appointment Confirm**: Xác nhận hẹn gặp

### 4. **Detail Screens**
- **Portfolio Gallery**: Xem gallery ảnh portfolio (grid view + full-screen viewer)
- **Timeline Detail**: Xem chi tiết timeline dự án với các mốc thời gian
- **Material Catalog Detail**: Xem chi tiết catalog vật liệu

---

## 🚀 HƯỚNG DẪN SỬ DỤNG

### **Bước 1: Tìm kiếm và gửi Auto Message**

1. **Mở màn hình tìm kiếm**
   - Vào tab "Tìm kiếm" trên bottom navigation
   - Chọn tab "Tìm kiếm thông minh"

2. **Thực hiện tìm kiếm**
   - Chọn loại tài khoản (Nhà thiết kế, Chủ thầu, hoặc VLXD)
   - Trả lời các câu hỏi của hệ thống
   - Nhấn "Tìm kiếm"

3. **Xem kết quả và kết nối**
   - Xem danh sách kết quả tìm kiếm
   - Nhấn nút "Kết nối" trên profile bạn quan tâm
   - Hệ thống tự động gửi tin nhắn quan tâm và tạo chat

4. **Kiểm tra chat**
   - Vào màn hình "Chat" trên bottom navigation
   - Tìm chat mới được tạo
   - Mở chat để xem tin nhắn tự động

---

### **Bước 2: Sử dụng Quick Actions Panel**

1. **Mở chat có business context**
   - Chọn một chat được tạo từ Smart Search
   - Hoặc chat với người dùng có loại tài khoản cụ thể (designer, contractor, store)

2. **Xem Quick Actions Panel**
   - Panel sẽ hiển thị ngay dưới header của chat
   - Các nút thao tác nhanh sẽ hiển thị tùy theo loại tài khoản người nhận

3. **Sử dụng các thao tác nhanh**
   - Nhấn vào các nút để mở dialog tương ứng
   - Điền thông tin và gửi

---

### **Bước 3: Gửi Yêu cầu Báo giá**

1. **Mở dialog Yêu cầu báo giá**
   - Nhấn nút "Yêu cầu báo giá" trong Quick Actions Panel

2. **Điền thông tin**
   - **Loại dự án**: VD: Nhà ở dân dụng, Biệt thự...
   - **Mô tả dự án**: Mô tả chi tiết về dự án
   - **Ngân sách dự kiến**: Nhập số tiền (triệu VNĐ), VD: 50
   - **Ngày bắt đầu dự kiến**: Chọn ngày từ date picker

3. **Gửi yêu cầu**
   - Nhấn nút "Gửi"
   - Tin nhắn báo giá sẽ được gửi với UI đặc biệt (màu xanh)

4. **Xem tin nhắn**
   - Tin nhắn sẽ hiển thị dưới dạng card với header màu xanh
   - Hiển thị đầy đủ thông tin: loại dự án, ngân sách, mô tả

---

### **Bước 4: Chia sẻ Portfolio (Cho Nhà thiết kế)**

1. **Mở dialog Portfolio**
   - Nhấn nút "Xem Portfolio" trong Quick Actions Panel (chỉ hiển thị khi chat với nhà thiết kế)
   - Hoặc nhấn "Xem Portfolio" nếu bạn là nhà thiết kế

2. **Chọn ảnh**
   - Nhấn nút "Chọn ảnh"
   - Chọn nhiều ảnh từ gallery (hỗ trợ multi-select)
   - Xem preview ảnh đã chọn
   - Có thể xóa ảnh hoặc thêm ảnh mới

3. **Điền thông tin**
   - **Tên dự án**: VD: Nhà phố 2 tầng, Biệt thự hiện đại...
   - **Mô tả dự án**: Mô tả về dự án thiết kế

4. **Gửi portfolio**
   - Nhấn nút "Chia sẻ"
   - Hệ thống sẽ upload ảnh lên Firebase Storage
   - Hiển thị progress bar khi đang upload
   - Tin nhắn portfolio sẽ được gửi (màu tím)

5. **Xem portfolio**
   - Tap vào tin nhắn portfolio để mở Portfolio Gallery Screen
   - Xem ảnh dưới dạng grid (2 cột)
   - Tap vào ảnh để xem full-screen
   - Swipe để chuyển ảnh, zoom để phóng to

---

### **Bước 5: Chia sẻ Timeline Dự án (Cho Chủ thầu)**

1. **Mở dialog Timeline**
   - Nhấn nút "Timeline dự án" trong Quick Actions Panel (chỉ hiển thị khi chat với chủ thầu)
   - Hoặc nhấn "Timeline dự án" nếu bạn là chủ thầu

2. **Điền thông tin dự án**
   - **Tên dự án**: VD: Xây dựng nhà phố 2 tầng...
   - **Ngày bắt đầu dự kiến**: Chọn ngày từ date picker
   - **Ngày kết thúc dự kiến**: Chọn ngày từ date picker

3. **Thêm các mốc thời gian**
   - Nhấn nút "Thêm mốc"
   - Điền thông tin cho mỗi mốc:
     - **Tên mốc**: VD: Khởi công, Hoàn thiện, Bàn giao...
     - **Ngày**: Chọn ngày từ date picker
     - **Mô tả**: Mô tả chi tiết về mốc thời gian
   - Có thể thêm nhiều mốc
   - Có thể xóa mốc bằng nút delete

4. **Gửi timeline**
   - Nhấn nút "Chia sẻ"
   - Tin nhắn timeline sẽ được gửi (màu teal)

5. **Xem timeline**
   - Tap vào tin nhắn timeline để mở Timeline Detail Screen
   - Xem thông tin dự án và tất cả các mốc thời gian
   - Mỗi mốc hiển thị: số thứ tự, tên, ngày, mô tả

---

### **Bước 6: Chia sẻ Material Catalog (Cho Cửa hàng VLXD)**

1. **Mở dialog Catalog**
   - Nhấn nút "Xem Catalog" trong Quick Actions Panel (chỉ hiển thị khi chat với cửa hàng VLXD)
   - Hoặc nhấn "Xem Catalog" nếu bạn là chủ cửa hàng

2. **Chọn vật liệu**
   - Danh sách vật liệu của bạn sẽ hiển thị
   - Chọn các vật liệu muốn chia sẻ (checkbox)
   - Xem thông tin: tên, danh mục, tồn kho, đơn vị

3. **Chia sẻ catalog**
   - Nhấn nút "Chia sẻ"
   - Tin nhắn catalog sẽ được gửi (màu cam)

4. **Xem catalog**
   - Tap vào tin nhắn catalog để mở Material Catalog Detail Screen
   - Xem danh sách vật liệu đã chia sẻ
   - Thông tin hiển thị: tên, danh mục, tồn kho, giá, mô tả

---

### **Bước 7: Yêu cầu Hẹn gặp**

1. **Mở dialog Hẹn gặp**
   - Nhấn nút "Hẹn gặp" trong Quick Actions Panel

2. **Điền thông tin**
   - **Ngày hẹn**: Chọn ngày từ date picker
   - **Giờ hẹn**: Chọn giờ từ time picker
   - **Địa điểm**: VD: Văn phòng, Công trường...
   - **Mục đích**: VD: Trao đổi về dự án, Xem mẫu...
   - **Ghi chú**: Thông tin bổ sung (tùy chọn)

3. **Gửi yêu cầu**
   - Nhấn nút "Gửi"
   - Tin nhắn hẹn gặp sẽ được gửi (màu xanh)

4. **Xác nhận hẹn gặp** (người nhận)
   - Người nhận có thể xác nhận hẹn gặp
   - Tin nhắn xác nhận sẽ có màu xanh lá

---

## 📁 CÁC FILE ĐÃ THÊM MỚI / THAY ĐỔI

### **Models**
- `lib/models/chat_model.dart`: Thêm `ChatType`, `chatType`, `receiverType`, `searchContext`, `isAutoMessage`, `businessData`, các `MessageType` mới

### **Services**
- `lib/services/chat/business_chat_service.dart`: Service mới để quản lý business chat features
- `lib/services/chat/auto_message_service.dart`: Cập nhật để lưu business context
- `lib/services/chat/chat_service.dart`: Cập nhật để đọc business context
- `lib/services/storage/image_service.dart`: Thêm `pickMultipleImagesFromGallery()` và `uploadMultipleImages()`

### **Screens**
- `lib/screens/chat/chat_detail_screen.dart`: Thêm Quick Actions Panel và các dialogs
- `lib/screens/chat/material_catalog_detail_screen.dart`: Màn hình xem chi tiết catalog vật liệu
- `lib/screens/chat/portfolio_gallery_screen.dart`: Màn hình xem gallery portfolio
- `lib/screens/chat/timeline_detail_screen.dart`: Màn hình xem chi tiết timeline

### **Components**
- `lib/components/message_bubble.dart`: Thêm các widget hiển thị business messages và navigation đến detail screens

---

## ✅ CHECKLIST TEST

### **Test Auto Message**
- [ ] Tìm kiếm thông minh và nhấn "Kết nối"
- [ ] Kiểm tra tin nhắn tự động được gửi
- [ ] Kiểm tra chat được tạo với business context
- [ ] Kiểm tra Quick Actions Panel hiển thị đúng loại tài khoản

### **Test Quote Request**
- [ ] Gửi yêu cầu báo giá với đầy đủ thông tin
- [ ] Kiểm tra tin nhắn hiển thị đúng format (màu xanh)
- [ ] Kiểm tra thông tin hiển thị đầy đủ (loại dự án, ngân sách, mô tả)

### **Test Portfolio**
- [ ] Chọn nhiều ảnh từ gallery
- [ ] Upload ảnh và gửi portfolio
- [ ] Tap vào tin nhắn portfolio để xem gallery
- [ ] Test full-screen viewer (swipe, zoom)

### **Test Timeline**
- [ ] Tạo timeline với nhiều mốc thời gian
- [ ] Gửi timeline
- [ ] Tap vào tin nhắn timeline để xem chi tiết
- [ ] Kiểm tra các mốc thời gian hiển thị đúng

### **Test Material Catalog**
- [ ] Chọn nhiều vật liệu
- [ ] Gửi catalog
- [ ] Tap vào tin nhắn catalog để xem chi tiết
- [ ] Kiểm tra thông tin vật liệu hiển thị đầy đủ

### **Test Appointment**
- [ ] Gửi yêu cầu hẹn gặp
- [ ] Kiểm tra tin nhắn hiển thị đúng format
- [ ] Test xác nhận hẹn gặp (nếu có)

### **Test UI/UX**
- [ ] Kiểm tra Quick Actions Panel hiển thị đúng theo loại tài khoản
- [ ] Kiểm tra các business messages có màu sắc phân biệt
- [ ] Kiểm tra navigation đến detail screens hoạt động đúng
- [ ] Kiểm tra responsive trên các kích thước màn hình khác nhau

---

## 🐛 XỬ LÝ LỖI THƯỜNG GẶP

### **Lỗi: Quick Actions Panel không hiển thị**
- **Nguyên nhân**: Chat chưa có business context
- **Giải pháp**: Tạo chat mới từ Smart Search hoặc kiểm tra `receiverType` trong chat data

### **Lỗi: Không thể upload ảnh portfolio**
- **Nguyên nhân**: Quyền truy cập storage hoặc kết nối internet
- **Giải pháp**: Kiểm tra quyền storage, kiểm tra kết nối internet, kiểm tra Firebase Storage rules

### **Lỗi: Không thể chọn vật liệu**
- **Nguyên nhân**: Chưa có vật liệu trong hệ thống
- **Giải pháp**: Thêm vật liệu vào màn hình Quản lý vật liệu trước

### **Lỗi: Detail screen không hiển thị**
- **Nguyên nhân**: `businessData` trong message không đúng format
- **Giải pháp**: Kiểm tra data structure trong Firestore, đảm bảo các field cần thiết có đầy đủ

---

## 📝 LƯU Ý KHI TEST

1. **Đảm bảo có dữ liệu test**:
   - Có ít nhất 2 tài khoản (1 để gửi, 1 để nhận)
   - Các tài khoản có loại khác nhau (designer, contractor, store)
   - Có vật liệu trong hệ thống (để test catalog)

2. **Kiểm tra quyền truy cập**:
   - Quyền truy cập storage (để upload ảnh)
   - Quyền truy cập camera/gallery (để chọn ảnh)

3. **Kiểm tra Firebase**:
   - Firebase Storage rules cho phép upload
   - Firestore rules cho phép đọc/ghi chat và messages

4. **Test trên thiết bị thật**:
   - Một số tính năng (như chọn ảnh) có thể hoạt động khác trên emulator
   - Test trên thiết bị thật để đảm bảo UX tốt nhất

---

## 🎨 UI/UX HIGHLIGHTS

### **Color Coding cho Business Messages**
- **Quote Request**: Màu xanh (blue)
- **Quote Response**: Màu xanh lá (green)
- **Portfolio**: Màu tím (purple)
- **Timeline**: Màu teal
- **Material Catalog**: Màu cam (orange)
- **Appointment**: Màu xanh (blue) / Xanh lá (green) khi confirmed

### **Quick Actions Panel**
- Hiển thị ngay dưới header chat
- Background màu xanh nhạt
- Các nút có border và icon rõ ràng
- Responsive với Wrap widget

### **Detail Screens**
- AppBar màu theo từng loại message
- Loading states khi fetch data
- Error handling với empty states
- Smooth navigation và animations

---

## 🔗 LIÊN KẾT VỚI CÁC TÍNH NĂNG KHÁC

### **Smart Search**
- Business Chat được kích hoạt từ Smart Search
- Search context được lưu trong chat để reference sau này

### **Material Management**
- Material Catalog sử dụng dữ liệu từ Material Management
- Cần có vật liệu trong hệ thống để test catalog feature

### **User Profile**
- Business Chat sử dụng `UserAccountType` từ user profile
- Quick Actions Panel hiển thị dựa trên loại tài khoản

---

## 📞 HỖ TRỢ

Nếu gặp vấn đề khi test, vui lòng:
1. Kiểm tra log trong console để xem lỗi chi tiết
2. Kiểm tra Firebase Console để xem data structure
3. Kiểm tra các file đã liệt kê ở trên
4. Tham khảo phần "Xử lý lỗi thường gặp"

---

**Chúc bạn test thành công! 🎉**

