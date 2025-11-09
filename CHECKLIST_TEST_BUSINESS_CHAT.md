# ✅ CHECKLIST TEST BUSINESS CHAT - QUICK GUIDE

## 🚀 TEST NHANH (5 PHÚT)

### **1. Test Auto Message từ Smart Search**
```
□ Vào Tìm kiếm > Tìm kiếm thông minh
□ Chọn loại tài khoản (VD: Nhà thiết kế)
□ Trả lời 2-3 câu hỏi
□ Nhấn "Tìm kiếm"
□ Nhấn "Kết nối" trên một profile
□ Kiểm tra: Chat được tạo với tin nhắn tự động
□ Kiểm tra: Quick Actions Panel hiển thị
```

### **2. Test Quick Actions Panel**
```
□ Mở chat có business context
□ Kiểm tra: Panel hiển thị 3 nút thao tác
□ Kiểm tra: Màu sắc và icon hiển thị đúng
```

### **3. Test Quote Request**
```
□ Nhấn "Yêu cầu báo giá"
□ Điền: Loại dự án, Mô tả, Ngân sách
□ Nhấn "Gửi"
□ Kiểm tra: Tin nhắn hiển thị với card màu xanh
□ Kiểm tra: Thông tin hiển thị đầy đủ
```

### **4. Test Portfolio (Nếu là Designer)**
```
□ Nhấn "Xem Portfolio"
□ Chọn 3-5 ảnh từ gallery
□ Điền: Tên dự án, Mô tả
□ Nhấn "Chia sẻ"
□ Đợi upload (có progress bar)
□ Kiểm tra: Tin nhắn portfolio màu tím
□ Tap vào tin nhắn → Xem gallery
□ Test: Swipe ảnh, zoom ảnh
```

### **5. Test Timeline (Nếu là Contractor)**
```
□ Nhấn "Timeline dự án"
□ Điền: Tên dự án, Ngày bắt đầu, Ngày kết thúc
□ Thêm 2-3 mốc thời gian
□ Nhấn "Chia sẻ"
□ Kiểm tra: Tin nhắn timeline màu teal
□ Tap vào tin nhắn → Xem chi tiết timeline
□ Kiểm tra: Các mốc hiển thị đầy đủ
```

### **6. Test Material Catalog (Nếu là Store)**
```
□ Đảm bảo có vật liệu trong hệ thống
□ Nhấn "Xem Catalog"
□ Chọn 2-3 vật liệu
□ Nhấn "Chia sẻ"
□ Kiểm tra: Tin nhắn catalog màu cam
□ Tap vào tin nhắn → Xem chi tiết catalog
□ Kiểm tra: Thông tin vật liệu hiển thị đầy đủ
```

### **7. Test Appointment**
```
□ Nhấn "Hẹn gặp"
□ Chọn: Ngày, Giờ, Địa điểm
□ Điền: Mục đích, Ghi chú (tùy chọn)
□ Nhấn "Gửi"
□ Kiểm tra: Tin nhắn appointment màu xanh
□ Kiểm tra: Thông tin hiển thị đầy đủ
```

---

## 🎯 TEST THEO LOẠI TÀI KHOẢN

### **Nhà Thiết Kế (Designer)**
- ✅ Quick Actions: Yêu cầu báo giá, Xem Portfolio, Hẹn gặp
- ✅ Test Portfolio: Upload nhiều ảnh, xem gallery
- ✅ Test Quote Request: Gửi yêu cầu báo giá

### **Chủ Thầu (Contractor)**
- ✅ Quick Actions: Yêu cầu báo giá, Timeline dự án, Hẹn gặp
- ✅ Test Timeline: Tạo timeline với nhiều mốc
- ✅ Test Quote Request: Gửi yêu cầu báo giá

### **Cửa Hàng VLXD (Store)**
- ✅ Quick Actions: Yêu cầu báo giá, Xem Catalog, Hẹn gặp
- ✅ Test Material Catalog: Chọn và chia sẻ vật liệu
- ✅ Test Quote Request: Gửi yêu cầu báo giá

---

## 🐛 TEST LỖI

### **Test Edge Cases**
```
□ Test với chat không có business context (Quick Actions không hiển thị)
□ Test upload ảnh portfolio với mạng chậm
□ Test gửi quote request không điền đầy đủ thông tin
□ Test timeline không có mốc thời gian
□ Test catalog không có vật liệu
□ Test appointment không chọn ngày
```

### **Test Error Handling**
```
□ Test khi không có quyền truy cập storage
□ Test khi không có kết nối internet
□ Test khi Firebase Storage lỗi
□ Test khi Firestore lỗi
□ Test khi không có dữ liệu (empty states)
```

---

## 📱 TEST TRÊN THIẾT BỊ

### **Android**
- ✅ Test trên thiết bị thật (khuyến nghị)
- ✅ Test trên emulator (nếu không có thiết bị thật)
- ✅ Test với các kích thước màn hình khác nhau

### **iOS** (Nếu có)
- ✅ Test trên thiết bị thật
- ✅ Test trên simulator
- ✅ Test với các kích thước màn hình khác nhau

---

## ⚡ TEST PERFORMANCE

### **Upload Performance**
```
□ Test upload 1 ảnh (nhanh)
□ Test upload 5 ảnh (trung bình)
□ Test upload 10+ ảnh (chậm, có progress bar)
□ Kiểm tra: Progress bar hiển thị đúng
□ Kiểm tra: Không bị crash khi upload nhiều ảnh
```

### **Loading Performance**
```
□ Test load chat list (có nhiều business chats)
□ Test load messages (có nhiều business messages)
□ Test load portfolio gallery (nhiều ảnh)
□ Test load material catalog (nhiều vật liệu)
□ Kiểm tra: Loading indicators hiển thị
□ Kiểm tra: Không bị lag khi scroll
```

---

## 🎨 TEST UI/UX

### **Visual Testing**
```
□ Kiểm tra: Màu sắc business messages đúng
□ Kiểm tra: Icons hiển thị rõ ràng
□ Kiểm tra: Typography dễ đọc
□ Kiểm tra: Spacing và padding hợp lý
□ Kiểm tra: Responsive trên các màn hình
```

### **Interaction Testing**
```
□ Test: Tap vào business messages mở detail screen
□ Test: Swipe để chuyển ảnh trong gallery
□ Test: Zoom ảnh trong full-screen viewer
□ Test: Scroll trong detail screens
□ Test: Back navigation hoạt động đúng
```

---

## 📊 TEST DATA

### **Kiểm tra Firestore Data**
```
□ Chat có field: chatType, receiverType, searchContext, isAutoMessage
□ Message có field: businessData, isAutoMessage
□ BusinessData có đầy đủ thông tin theo từng loại message
```

### **Kiểm tra Firebase Storage**
```
□ Portfolio ảnh được upload đúng path
□ Ảnh có thể download và hiển thị
□ URL ảnh được lưu đúng trong message
```

---

## ✅ CHECKLIST HOÀN THÀNH

### **Bắt buộc**
- [ ] Auto Message từ Smart Search hoạt động
- [ ] Quick Actions Panel hiển thị đúng
- [ ] Quote Request gửi và hiển thị đúng
- [ ] Portfolio upload và hiển thị đúng
- [ ] Timeline tạo và hiển thị đúng
- [ ] Material Catalog chia sẻ và hiển thị đúng
- [ ] Appointment gửi và hiển thị đúng
- [ ] Detail screens mở và hiển thị đúng

### **Tùy chọn (Nice to have)**
- [ ] Test trên nhiều thiết bị
- [ ] Test với nhiều dữ liệu
- [ ] Test performance với nhiều ảnh/vật liệu
- [ ] Test error handling đầy đủ
- [ ] Test edge cases

---

## 📝 GHI CHÚ KHI TEST

1. **Đảm bảo có dữ liệu test**:
   - Ít nhất 2 tài khoản
   - Vật liệu trong hệ thống (để test catalog)
   - Ảnh trong gallery (để test portfolio)

2. **Kiểm tra quyền**:
   - Quyền truy cập storage
   - Quyền truy cập camera/gallery

3. **Kiểm tra Firebase**:
   - Firebase Storage rules
   - Firestore rules
   - Firebase config đúng

4. **Test trên thiết bị thật**:
   - Một số tính năng hoạt động tốt hơn trên thiết bị thật
   - Camera/gallery có thể không hoạt động trên emulator

---

**Happy Testing! 🎉**

