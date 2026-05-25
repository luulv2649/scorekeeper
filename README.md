# ScoreKeeper - Flutter

Ứng dụng ghi điểm bài cho 4 người chơi. Chạy được trên Windows, Android, iOS.

---

## Cài đặt Flutter trên Windows

### Bước 1 — Tải Flutter SDK

1. Vào https://docs.flutter.dev/get-started/install/windows
2. Tải file zip Flutter SDK (khoảng 1GB)
3. Giải nén vào `C:\flutter` (tránh đường dẫn có dấu cách)

### Bước 2 — Thêm Flutter vào PATH

1. Mở **Start** → tìm "Environment Variables"
2. Chọn **Edit the system environment variables**
3. Click **Environment Variables** → chọn `Path` → **Edit**
4. Thêm `C:\flutter\bin`
5. Restart terminal

### Bước 3 — Kiểm tra

```bash
flutter doctor
```

---

## Chạy trên Windows Desktop (nhanh nhất để test)

```bash
cd scorekeeper_flutter
flutter pub get
flutter run -d windows
```

Cửa sổ app sẽ mở ngay trên máy tính.

---

## Chạy trên Android (điện thoại thật)

1. Bật **Developer Options** trên điện thoại Android
2. Bật **USB Debugging**
3. Cắm cáp USB vào máy tính
4. Chạy:

```bash
flutter devices          # kiểm tra thiết bị đã nhận chưa
flutter run              # tự chọn thiết bị
```

---

## Chạy trên Android Emulator

1. Cài **Android Studio**: https://developer.android.com/studio
2. Mở Android Studio → **Virtual Device Manager** → tạo emulator
3. Khởi động emulator, rồi:

```bash
flutter run -d emulator-5554
```

---

## Chạy trên iOS (cần Mac)

```bash
flutter run -d ios
```

---

## Cấu trúc project

```
lib/
├── main.dart                    # Entry point
├── models/
│   └── game_model.dart          # Player, Round, Game
├── providers/
│   └── game_store.dart          # State management + lưu local
├── screens/
│   ├── home_screen.dart         # Màn hình chính
│   ├── new_game_screen.dart     # Tạo game mới
│   ├── game_play_screen.dart    # Chơi game, xem điểm
│   ├── add_round_screen.dart    # Nhập điểm từng ván
│   ├── history_screen.dart      # Lịch sử
│   └── game_detail_screen.dart  # Chi tiết game đã kết thúc
└── utils/
    └── helpers.dart             # Màu sắc, format ngày
```

---

## Tính năng

- ✅ 4 người chơi, nhập tên tùy ý
- ✅ Kiểm tra tổng điểm = 0 theo thời gian thực
- ✅ Warning nếu tổng ≠ 0
- ✅ Nút +10 / -10 để nhập nhanh
- ✅ 2 chế độ: hiện điểm sau mỗi ván / ẩn đến khi kết thúc
- ✅ Sửa / xóa từng ván
- ✅ Lịch sử với tìm kiếm và lọc
- ✅ Bảng xếp hạng cuối game (🥇🥈🥉)
- ✅ Lưu local bằng SharedPreferences
- ✅ Dark mode tự động
# scorekeeper
