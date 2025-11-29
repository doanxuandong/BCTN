# Hướng dẫn Test Tính Năng Mới - BuilderConnect

## ⚠️ QUAN TRỌNG: Cần Hot Restart App

Sau khi có code mới, bạn **PHẢI** làm:
1. **Stop app** (nếu đang chạy)
2. **Hot Restart** (Ctrl+Shift+F5 hoặc click icon restart) - KHÔNG phải Hot Reload
3. Hoặc **Stop và Run lại** từ đầu

Hot Reload (F5) sẽ KHÔNG load các file mới được tạo!

---

## 🧪 CÁCH TEST TỪNG TÍNH NĂNG

### 1️⃣ Test Project Dashboard (Quản lý dự án)

**Bước 1:** Mở app và đăng nhập

**Bước 2:** 
- Vào tab **"Quản lý"** (icon thứ 4 từ trái ở bottom navigation)
- Bạn sẽ thấy màn hình **"Quản lý vật liệu"**

**Bước 3:**
- Nhìn lên **AppBar** (thanh trên cùng)
- Tìm icon **Dashboard** (📊) ở góc trên bên phải
- Icon này nằm giữa icon History và icon Refresh
- **Click vào icon Dashboard**

**Bước 4:**
- Màn hình **"Quản lý dự án"** sẽ mở ra
- Nếu chưa có dự án: Sẽ hiển thị "Chưa có dự án nào"
- Nếu đã có dự án: Sẽ hiển thị danh sách các dự án với:
  - Tên dự án
  - Badge giai đoạn (Thiết kế/Thi công/Vật liệu)
  - Tiến độ (X/3 giai đoạn)
  - Danh sách đối tác

**✅ Kết quả mong đợi:**
- Màn hình Project Dashboard mở được
- Hiển thị danh sách dự án (nếu có)
- Có thể click vào đối tác để mở chat

---

### 2️⃣ Test Tạo Pipeline từ Smart Search

**Bước 1:**
- Vào tab **"Tìm kiếm"** (icon thứ 3 từ trái)
- Chọn tab **"Tìm kiếm thông minh"** (tab thứ 2)

**Bước 2:**
- Chọn loại tài khoản: **"Nhà thiết kế"** (chip đầu tiên)
- Trả lời các câu hỏi:
  - Loại dự án bạn cần thiết kế?
  - Phong cách thiết kế?
  - Ngân sách?
  - Vị trí dự án?
  - v.v.

**Bước 3:**
- Nhấn **"Tìm kiếm"** sau khi trả lời hết câu hỏi
- Màn hình kết quả sẽ hiển thị danh sách nhà thiết kế với điểm phù hợp

**Bước 4:**
- Chọn một nhà thiết kế
- Nhấn nút **"Kết nối"** (màu xanh, có icon ⭐)

**Bước 5:**
- Hệ thống sẽ:
  - Tạo pipeline mới (trong Firestore collection `project_pipelines`)
  - Gửi tin nhắn tự động đến nhà thiết kế
  - Mở màn hình chat với nhà thiết kế đó

**Bước 6: Kiểm tra Pipeline đã tạo:**
- Quay lại **Project Dashboard** (theo hướng dẫn ở mục 1)
- Bạn sẽ thấy dự án mới xuất hiện với:
  - Tên: "Dự án mới" (hoặc tên bạn đã đặt)
  - Giai đoạn: "Thiết kế"
  - Trạng thái: "Đã gửi yêu cầu hợp tác thiết kế"
  - Đối tác: Tên nhà thiết kế bạn vừa kết nối

**✅ Kết quả mong đợi:**
- Pipeline được tạo trong Firestore
- Chat được mở với tin nhắn tự động
- Dự án xuất hiện trong Project Dashboard

---

### 3️⃣ Test Collaboration Badges trong Chat List

**Bước 1:**
- Vào tab **"Tin nhắn"** (icon thứ 2 từ trái)
- Chọn tab **"Chat"** (tab đầu tiên, không phải tab "Bạn bè")

**Bước 2:**
- Xem danh sách chat
- Tìm các chat với:
  - Nhà thiết kế
  - Chủ thầu
  - Cửa hàng VLXD

**Bước 3:**
- Nếu chat có pipeline và trạng thái hợp tác:
  - **Badge màu cam "Đã yêu cầu"** - khi trạng thái là `requested`
  - **Badge màu xanh lá "Đang hợp tác"** - khi trạng thái là `accepted` hoặc `inProgress`
  - **Badge màu xanh dương "Hoàn thành"** - khi trạng thái là `completed`

**✅ Kết quả mong đợi:**
- Badge hiển thị bên cạnh tên người chat
- Màu sắc và text đúng với trạng thái

**⚠️ Lưu ý:**
- Badge chỉ hiển thị nếu:
  - Chat có `pipelineId` (đã liên kết với pipeline)
  - Trạng thái hợp tác không phải `none`
- Nếu không thấy badge, có thể:
  - Chat chưa được liên kết với pipeline
  - Cần reload chat list (pull down để refresh)

---

### 4️⃣ Test Chat với Pipeline Info

**Bước 1:**
- Mở một chat với nhà thiết kế/chủ thầu/cửa hàng (đã có pipeline)

**Bước 2:**
- Xem màn hình chat
- Ở trên cùng, dưới AppBar, có thể có panel **"Thao tác nhanh"** (màu xanh nhạt)
- Panel này hiển thị các nút:
  - Yêu cầu báo giá
  - Xem Portfolio (nếu là nhà thiết kế)
  - Timeline dự án (nếu là chủ thầu)
  - Xem Catalog (nếu là cửa hàng)

**Bước 3:**
- Chat này đã được liên kết với pipeline
- Pipeline info được load tự động khi mở chat

**✅ Kết quả mong đợi:**
- Chat load được pipeline info
- Quick Actions panel hiển thị đúng theo loại tài khoản

---

## 🔍 KIỂM TRA TRONG FIRESTORE

Nếu muốn kiểm tra dữ liệu trong Firestore:

1. Mở Firebase Console
2. Vào **Firestore Database**
3. Tìm collection **`project_pipelines`**
4. Xem các document được tạo:
   - Mỗi pipeline có ID riêng
   - Chứa thông tin: ownerId, designerId, status, v.v.

---

## 🐛 TROUBLESHOOTING

### Vấn đề: Không thấy icon Dashboard

**Giải pháp:**
- Kiểm tra file `lib/screens/manage/material_management_screen.dart`
- Đảm bảo có import `project_dashboard_screen.dart`
- Đảm bảo có method `_navigateToProjectDashboard()`
- **Hot Restart** app

### Vấn đề: Project Dashboard trống

**Nguyên nhân:**
- Chưa tạo pipeline nào
- Pipeline được tạo bởi user khác

**Giải pháp:**
- Test tạo pipeline từ Smart Search (mục 2)
- Kiểm tra trong Firestore xem pipeline có được tạo không
- Kiểm tra `ownerId` trong pipeline có đúng với userId hiện tại không

### Vấn đề: Không thấy Collaboration Badges

**Nguyên nhân:**
- Chat chưa được liên kết với pipeline
- Pipeline chưa có trạng thái hợp tác

**Giải pháp:**
- Tạo pipeline mới từ Smart Search
- Pull down để refresh chat list
- Kiểm tra trong Firestore xem chat có `pipelineId` không

### Vấn đề: Smart Search không tạo pipeline

**Nguyên nhân:**
- Chưa chọn đúng loại tài khoản (phải là "Nhà thiết kế")
- Lỗi khi tạo pipeline

**Giải pháp:**
- Kiểm tra console log xem có lỗi không
- Đảm bảo đã trả lời đủ câu hỏi
- Kiểm tra Firestore permissions

---

## 📝 CHECKLIST TEST

- [ ] Project Dashboard mở được từ Material Management
- [ ] Project Dashboard hiển thị danh sách dự án (nếu có)
- [ ] Smart Search tạo pipeline khi kết nối với nhà thiết kế
- [ ] Pipeline xuất hiện trong Project Dashboard sau khi tạo
- [ ] Collaboration badges hiển thị trong chat list
- [ ] Chat load được pipeline info
- [ ] Click vào đối tác trong Project Dashboard mở được chat

---

## 🎯 TEST CASE CHI TIẾT

### Test Case 1: Tạo Pipeline từ đầu

1. Đăng nhập với tài khoản người dùng thường
2. Vào Smart Search → Chọn Nhà thiết kế
3. Trả lời câu hỏi → Tìm kiếm
4. Kết nối với 1 nhà thiết kế
5. **Expected:** Pipeline được tạo, chat mở ra
6. Vào Project Dashboard
7. **Expected:** Thấy dự án mới với trạng thái "Đã yêu cầu"

### Test Case 2: Xem Collaboration Status

1. Vào Chat list
2. Tìm chat với nhà thiết kế đã kết nối
3. **Expected:** Thấy badge "Đã yêu cầu" (màu cam)
4. (Nếu nhà thiết kế chấp nhận) **Expected:** Badge chuyển thành "Đang hợp tác" (màu xanh)

### Test Case 3: Project Dashboard Navigation

1. Vào Material Management
2. Click icon Dashboard
3. **Expected:** Màn hình Project Dashboard mở ra
4. Click vào đối tác trong dự án
5. **Expected:** Chat với đối tác đó mở ra

---

## 💡 LƯU Ý

- Tất cả tính năng mới đều cần **Hot Restart** để hoạt động
- Pipeline chỉ được tạo khi kết nối với **Nhà thiết kế** từ Smart Search
- Badges chỉ hiển thị khi chat đã được liên kết với pipeline
- Project Dashboard chỉ hiển thị dự án của user hiện tại (ownerId)

---

Nếu vẫn không thấy tính năng mới, hãy:
1. **Stop app hoàn toàn**
2. **Run lại từ đầu** (F5 hoặc Run button)
3. Kiểm tra console log xem có lỗi không
4. Kiểm tra Firestore xem dữ liệu có được tạo không












