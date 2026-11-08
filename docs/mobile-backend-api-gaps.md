# Mobile ↔ Backend: API đang dùng và khoảng trống

Mobile gọi Gateway YARP `http://<host>:5000` (Android emulator: `10.0.2.2`; máy thật: `--dart-define=API_BASE_URL=http://<ip>:5000`).
Không sửa `src/backend/`; mục thiếu ghi lại ở đây để nhóm backend bổ sung.

## Đang dùng API thật

| Chức năng mobile | Endpoint | Ghi chú |
| :--- | :--- | :--- |
| Danh sách công thức (M-02) | `GET /api/v1/recipes?versionStatus=Approved&pageSize=N` | `N` = Remote Config `max_lookup_results` |
| Chi tiết công thức (M-03, M-04) | `GET /api/v1/recipes/{id}` | Nguyên liệu, bước, thời lượng, nhiệt độ, dụng cụ |

`RecipeMapper` đổi `RecipeDetailResponse` → `RecipeItem` của UI. Không còn mock fallback (`AppConfig.enableOfflineMockFallback = false`);
lỗi mạng hiển thị màn "Không tải được công thức" + nút Thử lại.

## Backend chưa có → mobile giữ dữ liệu cục bộ trong phiên

| Nhu cầu | API còn thiếu | Hiện trạng trên mobile |
| :--- | :--- | :--- |
| Biến thể size S/M/L | Định lượng theo size cho `Recipe` | UI nhận 1 size chuẩn `M` ("Định lượng chuẩn") |
| Danh mục đồ uống | `category` trên recipe | Suy từ tên (`RecipeMapper.categoryOf`) |
| Video hướng dẫn / media URL | URL phát được cho `mediaAssetRef` | Mốc video tính từ `durationSeconds`, chưa phát video thật |
| Ngày ban hành / người ban hành | `publishedAt`, `publishedBy` | Dùng `updatedAt`, nhãn "R&D RecipeHub" |
| Phiên bản mới hơn | cờ `hasNewerVersion` | luôn `false` |
| SOP (M-05, M-06) | `/api/v1/sops` | Danh sách SOP cục bộ |
| Nhiệm vụ học (M-07, M-08) | `/api/v1/learning-tasks` | Cục bộ |
| Quiz (M-16) | `/api/v1/quizzes` | Cục bộ |
| Phản hồi (M-11, M-12) | `/api/v1/feedback` | Lưu cục bộ; ảnh đính kèm lên Firebase Storage |
| Thông báo (M-10) | `/api/v1/notifications` | Lịch sử FCM lưu cục bộ (shared_preferences); gửi từ Firebase Console |
| Tự luyện (M-14, M-15) | `/api/v1/practice-sessions` | Cục bộ; báo cáo PDF lên Firebase Storage |
| Đánh giá thực hành, học viên (Admin) | `/api/v1/evaluations`, `/api/v1/trainees` | Cục bộ |
| Nhật ký kiểm toán | `/api/v1/audit` đã có route Gateway nhưng chưa có endpoint đọc cho mobile | Chưa dùng |
| Xác thực | Identity chưa cấp token cho Firebase user | Dùng Firebase Auth; `X-User-Id` là GUID dev mặc định |
