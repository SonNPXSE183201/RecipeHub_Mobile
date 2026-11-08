# Nhật ký kiểm thử khám phá – RecipeHub mobile

- **Ngày:** 05/11/2026
- **Thiết bị:** Xiaomi Redmi 7 (Android 10, API 29, 720×1520), Wi-Fi + 4G
- **Bản build:** debug APK, `API_BASE_URL=http://127.0.0.1:5000` qua `adb reverse`, Gateway + Recipe service chạy Docker local, Firebase project `recipehub-mobile`
- **Người thực hiện:** agent điều khiển qua `adb` (chạm, nhập, chụp màn hình, đọc logcat)

## Charter

> Khám phá luồng Barista tại quầy (đăng nhập → tra cứu → chi tiết → tự luyện → phản hồi kèm ảnh → báo cáo PDF) trên màn hình nhỏ 360dp với mạng không ổn định, để tìm lỗi bố cục, lỗi xử lý mạng và lỗi tích hợp Firebase.

Time-box: 2 phiên, tổng khoảng 25 phút (04:53–05:03 và 05:14–05:35). Thời gian chạy ARTEMIS có kịch bản không tính vào đây.

## Phát hiện

| # | Thời điểm | Mức | Phát hiện | Bằng chứng | Trạng thái |
| :-: | :-- | :-- | :-- | :-- | :-- |
| E-01 | 04:39 | Cao | Màn tra cứu tràn ngang trên màn 360dp: hàng chip chi nhánh và hàng meta của thẻ công thức (vạch vàng-đen "RIGHT OVERFLOWED BY 9.5 PIXELS"). Test Flutter không bắt được vì TC-10 bỏ qua lỗi overflow. | `lookup.png` | Đã sửa (`Flexible`/`Expanded` + ellipsis), chụp lại sạch |
| E-02 | 04:42 | Trung bình | Màn chi tiết: chữ "Ban hành: 05/11/2026" tràn 0px ở hàng chip phiên bản | `detail.png` | Đã sửa |
| E-03 | 04:56 | Trung bình | Lịch sử tự luyện: hàng mã món · khẩu phần + ngày giờ tràn 1.8–42px | `08_timer_saved.png` | Đã sửa, `21_history_fixed.png` |
| E-04 | 04:39 | Cao | Mobile gửi `versionStatus=Approved` nhưng backend chỉ nhận `draft`/`published` → Gateway trả 400, app không tải được công thức nào từ backend thật | `curl` 400 "Invalid version status 'Approved'" | Đã sửa phía mobile (`published`) |
| E-05 | 04:40 | Thấp | "Matcha Latte" bị xếp nhóm "Trà Trái Cây" do suy luận theo tên | `lookup2.png` | Đã sửa (`matcha`, `latte` → Trà Sữa) |
| E-06 | 04:58 | Trung bình | Nút "Gây crash thử nghiệm" bị ẩn: chỉ Admin thấy, phải nhấn giữ tiêu đề "CÀI ĐẶT ỨNG DỤNG". Người chấm khó tìm. | `10_account_a.png`, `15_crash_dialog.png` | Mở, chờ quyết định (UI đã chốt) |
| E-07 | 05:02 | Trung bình | Vai trò Admin mất sau khi khởi động lại app (quay về Viewer dù vẫn đăng nhập) | `20_state_empty.png` (badge VIEWER) | Đã sửa: vai trò lấy từ custom claim (`ensureProfile`), ART-13/15 |
| E-08 | 05:10 | Trung bình | Phiên tự luyện vừa lưu biến mất sau khi khởi động lại app; lịch sử chỉ còn dữ liệu mẫu | `21_history_fixed.png` | Mở (dữ liệu chỉ lưu trong bộ nhớ) |
| E-09 | 05:14 | Thấp | Xuất PDF chỉ có spinner trên icon, không có % tiến độ (file ~2KB nên gần như tức thời) | `22_pdf_progress_1.png` | Chấp nhận |
| E-10 | 05:16 | Thấp | Thông báo "Ảnh vượt quá 5MB" vẫn hiện sau khi lần chọn ảnh tiếp theo bị hủy | `28_after_dismiss.png` | Mở |
| E-11 | 05:16, 05:18 | Ngoài phạm vi | Trình chọn tệp của hệ thống (Google DocumentsUI trên MIUI) crash khi trả ảnh về: `IllegalStateException: Can not perform this action after onSaveInstanceState`. RecipeHub vẫn nhận ảnh. | logcat buffer `crash`, `27_feedback_ready.png` | Lỗi hệ thống, ghi nhận |
| E-12 | 05:19 | Thông tin | Ảnh 1,07MB tải lên rất chậm (≈1 phút trên Wi-Fi này); thanh tiến độ hiển thị đúng | `36_upload_t2.png` | Đạt |
| E-13 | 05:32 | Thông tin | Mất mạng giữa lúc tải ảnh: tiến độ đứng ở ~23%, nút "Hủy tải" vẫn dùng được; có mạng lại thì tự tải tiếp và hoàn tất sau ~21s | `61_net_cut_45s.png`, log `submit_feedback` | Đạt |
| E-14 | 05:20, 05:33 | Thông tin (công cụ) | Màn hình đen sau khi gửi phản hồi khi trang được mở bằng automation server (`debugScreenOverride` thay route gốc, `Navigator.pop` làm rỗng navigator). Đi bằng điều hướng thật thì không bị. | `38_feedback_done.png`, `67_after_submit_real.png` | Chỉ ảnh hưởng công cụ debug |
| E-15 | 05:26 | Thông tin | Remote Config real-time: thay đổi trên server mất khoảng 30 giây đến 4 phút mới tới app | `48_rc_max3_bottom.png` → `50_rc_lookup_bottom.png` | Đạt |
| E-19 | 05:28, 06:11 | Cao | Tăng `max_lookup_results` từ 3 lên 50: danh sách vẫn 3 món. Ban đầu tưởng là trễ real-time; ARTEMIS lặp lại cho thấy hướng 3 → 50 luôn rớt, 50 → 3 luôn đạt. Nguyên nhân có hai lớp: (1) app chỉ tải đúng số món theo giới hạn cũ và không tải lại; (2) màn tra cứu đọc `MockDataService.recipes` thay vì `watch` `RecipeViewModel`, nên dù đã tải lại vẫn không rebuild. Lần sửa đầu chỉ xử lý (1) nên lượt 12–18 vẫn rớt; log `[Recipe] applyLimit 50 … loaded=3` giúp tìm ra (2) | ARTEMIS ART-10 lượt 2, 10, 16, 18 | Đã sửa (`applyLimit` + View watch `RecipeViewModel`, TC-13) |
| E-20 | 06:03 | Cao | Thông báo FCM đã mở bị xử lý lại sau khi đăng xuất rồi đăng nhập (mở trang Thông báo hoặc món cũ thay vì màn Tra cứu) | ARTEMIS ART-01 lượt 2, 3, 5 | Đã sửa (TC-12) |
| E-21 | 06:07 | Cao | Thông báo trỏ tới món nằm ngoài danh sách đã tải (bị giới hạn bởi Remote Config) mở trang Thông báo thay vì chi tiết món | ARTEMIS ART-09 lượt 2 | Đã sửa (TC-11) |
| E-16 | 04:55 | Thấp (bảo mật) | FCM device token in đầy đủ ra log (`FCM Device Token: …`) kể cả bản release | logcat `flutter` | Đã sửa: chỉ in 8 ký tự đầu khi `kDebugMode`; token lưu ở Firestore `devices/` |
| E-17 | 05:30 | Thấp (analytics) | `view_recipe.source` = `lookup` cả khi mở từ thông báo FCM → không đo được tỷ lệ mở từ thông báo | log `FA-SVC` | Đã sửa: `source=notification`, xác nhận trên máy (`e2e2/u-18`) |
| E-18 | 04:42 | Thấp (dữ liệu) | Đơn vị "lát" hiển thị "lat" do mã đơn vị seed không dấu | `detail.png` | Đã sửa trong dữ liệu Firestore (`lát`) |
| E-22 | 12:06 (05/11) | Trung bình | Bấm "Gây crash" rồi mở lại app → thêm một sự cố `previous_crash` trùng | web Admin, `incidents/` | Đã sửa: `markCrashAlreadyReported`, TC-19 |
| E-23 | 12:15 | Cao | Đăng xuất (bị khóa) rồi đăng nhập lại ngay → `ConcurrentModificationError` trong `NotificationViewModel.reset()` (duyệt list có `await` trong khi `start()` thêm phần tử); app tự báo 2 sự cố + Crashlytics alert tạo issue | web Admin: stack `notification_viewmodel.dart:203` | Đã sửa: xóa trạng thái đồng bộ rồi dọn trên bản sao, TC-22 |
| E-24 | 12:15 | Cao | Mở khóa tài khoản rồi đăng nhập lại vẫn bị đăng xuất "đã bị khóa" | `m-10` | Đã sửa: bỏ snapshot `users/{uid}` lấy từ cache offline (`isFromCache`) |
| E-25 | 12:09 | Trung bình | Bị Admin khóa → app về màn đăng nhập nhưng không nói lý do | `m-08` | Đã sửa: `notice` → SnackBar ở AuthGate, TC-15 |
| E-26 | 12:07 | Thấp (web) | Panel chi tiết sự cố vẫn hiện "Đang mở" sau khi bấm Đã xử lý (sự cố rời danh sách theo bộ lọc) | `web-14` | Đã sửa: cập nhật `selected` tại chỗ |
| E-27 | 12:02 | Thấp (web) | Cột "thiết bị" luôn 0 | `web-06` | Đã sửa: Function `onDeviceWritten` |
| E-28 | 12:02 | Thấp (web) | Gõ tiếng Việt bằng SendKeys vào Flutter Web bị mất dấu (giới hạn công cụ tự động, người gõ tay bình thường) | `web-09` | Không phải lỗi app; runner dán qua clipboard |
| E-29 | 16:21 | Trung bình | Thư viện SOP: hàng mã/phiên bản/phân loại tràn ngang 17–33 px trên màn 720 px (sọc vàng đen); app tự báo 3 sự cố non-fatal lên web | `e2e2/u-11`, web `u-16` | Đã sửa: phân loại/“Áp dụng” co giãn + ellipsis, mã SOP giữ đủ; E2E-02 |
| E-30 | 16:26 | Thấp | Chi tiết món từ Firestore hiện nhãn "Quy cách phục vụ chuẩn:" trống | `e2e2/u-18` | Đã sửa: ẩn khối khi chưa có quy cách; E2E-03 |
| E-31 | 16:27 | Trung bình | Thông báo tới khi app đang mở chỉ hiện SnackBar, không có cách mở món/SOP đính kèm | `e2e2/u-20` | Đã sửa: nút "Xem" → `NotificationViewModel.open`; E2E-01 |
| E-32 | 12:44 | Cao | `setState() called after dispose(): MainAppShellState` — đang ở trang Thông báo thì đổi vai trò/đăng xuất (shell dựng lại theo key vai trò), bấm back → crash (2 sự cố Crash trên web) | web Sự cố | Đã sửa: kiểm tra `mounted` sau `await Navigator.push` ở shell, Việc học, Phản hồi; E2E-04 |
| E-33 | 16:27 | Thấp (web) | Sau khi gửi, tiêu đề/nội dung xóa nhưng "Khi chạm mở" vẫn giữ món cũ → dễ gửi nhầm deep link ở tin kế tiếp | `e2e/_web9` | Đã sửa: reset `recipeCode` sau khi gửi; W-07 |
| E-34 | 16:24 | Thấp (web) | Dropdown người nhận không cho biết ai chưa có thiết bị → gửi xong mới báo lỗi | `e2e/_web5` | Đã sửa: nhãn "chưa có thiết bị" |
| E-35 | 16:24 | Thấp | Tin FCM dùng `fcm_fallback_notification_channel` ("Miscellaneous"), MIUI xếp vào nhóm im lặng | `dumpsys notification` | Đã sửa: kênh `recipehub_updates` (IMPORTANCE_HIGH) tạo ở `MainActivity` + `default_notification_channel_id` trong manifest |
| E-36 | 16:38 | Trung bình | Web hiện sự cố "Crash: ứng dụng bị crash ở lần chạy trước" dù app không chết: `FlutterError` (vd overflow) được ghi `recordFlutterFatalError` → Crashlytics đặt `didCrashOnPreviousExecution` | web Tổng quan `e2e/_web20` | Đã sửa: `recordFlutterError` (non-fatal), khớp loại sự cố gửi Admin |
| E-37 | 16:50 | Trung bình (web) | Sau deploy, admin vẫn chạy `main.dart.js` cũ tới 1 giờ (`Cache-Control: max-age=3600` cho file không hash) — lộ ra khi một bản build thiếu `--dart-define-from-file` bị deploy (web hiện "Thiếu cấu hình Firebase web" ~3 phút) | `curl -I`, `e2e/_web16` | Đã sửa: `no-cache` (revalidate ETag) cho js/json/html; README ghi rõ cờ build |
| E-38 | 17:02 | Thấp | Đăng nhập khi mất mạng/hủy chọn tài khoản bị ghi lỗi Crashlytics (`auth_guest`) — nhiễu, đây là tình huống dự kiến đã báo bằng thông điệp | logcat `flutter` | Đã sửa: bỏ ghi với mã `network`/`cancelled`; E2E-05 |
| E-39 | 17:06 | Trung bình | Chạm thông báo khi app đã tắt: mở đúng món nhưng tin vẫn "chưa đọc" — sự kiện "đã chạm" tới trước, bị bản background handler lưu (chưa đọc) ghi đè khi nạp lịch sử | `e2e2/u-42`, `run-as … FlutterSharedPreferences.xml` | Đã sửa: ưu tiên bản trong bộ nhớ, cộng dồn cờ đã đọc; E2E-06; xác nhận lại `u-45` |
| E-40 | 17:05 | Thấp (phạm vi) | Phản hồi chỉ lưu cục bộ (dữ liệu mẫu) nhưng thông báo "Đã gửi … đến Quản lý Admin"; web Admin chưa có màn Phản hồi | `e2e2/u-41` | Mở: ngoài phạm vi Lab 3 (plan không có luồng Phản hồi lên server) — event `submit_feedback` và ảnh đính kèm Storage vẫn thật |

## Ghi chú môi trường

- Màn khóa có PIN của MIUI chặn `screencap` (`FB is protected: PERMISSION_DENIED`) → ảnh đen; cần mở khóa và bật `svc power stayon usb`.
- Bàn phím Telex tự đổi "test" → "tét" khi nhập bằng `adb shell input text`; dùng từ không bị Telex biến đổi.
- `am force-stop` đưa app vào trạng thái stopped nên FCM không giao tin; ca terminated dùng `am kill` sau khi về Home.
