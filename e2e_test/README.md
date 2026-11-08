# RecipeHub Mobile – ARTEMIS E2E

Bộ 24 ca TC-01…TC-24 theo `docs/test-plan.md`, chạy tuần tự trên Android thật với dữ liệu Firestore thật. Chỉ tạo bộ test; chưa thực thi hoặc có kết quả thiết bị. Không chạy đồng thời nhiều pytest trên cùng thiết bị/thư mục kết quả.

## Chuẩn bị

- Windows, Python >=3.12, `uv`, Android platform-tools (`adb` trong PATH), thiết bị bật USB debugging và đã xác nhận quyền ADB.
- Cài APK RecipeHub với Firebase/Google Sign-In đúng cấu hình. TC-13 cần Firebase Analytics hoạt động và log tag `FA-SVC` trên bản APK sử dụng.
- ARTEMIS checkout `D:/PRM393/artemis`, ghim commit **351ca8422f7b5b54e80a9c1ce03a222e02415b6b**. Server cấu hình provider/API key riêng theo hướng dẫn ARTEMIS.
- ARTEMIS cài **Accessibility Helper** lên thiết bị để đọc/điều khiển UI; cấp các quyền Accessibility và quyền cần thiết theo hướng dẫn server.
- Hai tài khoản Viewer A/B và tài khoản password riêng (`RH_PASSWORD_TEST_EMAIL`, `RH_PASSWORD_TEST_PASSWORD`), một Google account có custom claim Admin, cùng chi nhánh test. Account Google của Viewer A (cùng `RH_VIEWER_EMAIL`) và Admin phải có sẵn trong account picker Android. Admin đăng nhập bằng Google, không dùng email/password Admin.
- Firestore có `Bòng Bưởi - Ô Long Bưởi Nha Đam`, `Americano Nóng`, `Latte Đá`, định lượng/size, ít nhất hai bước video hợp lệ, SOP và hơn 5 công thức đã ban hành. Mỗi vòng cần một nhiệm vụ `Chưa học` có checklist chưa hoàn tất và quiz khả dụng. Chuẩn bị một Barista dành riêng cho đánh giá và một ảnh test không riêng tư trong thư viện Android.

Khởi động ARTEMIS ở terminal riêng:

```powershell
cd D:/PRM393/artemis
uv run artemis ui
# Hoặc .\start.bat
```

Tại thư mục `e2e_test/`:

```powershell
Copy-Item .env.example .env
# Điền serial, tài khoản và mật khẩu test trong .env (không commit).
uv sync
uv run pytest -v -k TC-07
```

Hook collection bổ sung keyword `TC-07`… cho lệnh `-k` trên; tên hàm vẫn là `test_tc07_search_has_results`. Có thể dùng `-k tc07` hoặc node ID. `.env` không ghi đè env đã được thiết lập trong shell.

## Chạy và báo cáo

```powershell
uv run pytest -v -m "not manual"
.\run_suite.ps1
# Script chạy đủ 3 vòng RUN_ID=round1, round2, round3 rồi tổng hợp,
# tiếp tục vòng sau nếu pytest thất bại, exit 1 nếu có vòng lỗi.
uv run python summarize.py
```

Mỗi ca có một dòng trong `results/<RUN_ID>.jsonl`; mặc định RUN_ID là timestamp UTC. Thời gian gồm setup, các phase và cleanup. Các phase TC-21 nằm trong cùng dòng, trường `traces` giữ mọi trace của ca; `trace_id` là trace cuối. Outcome cuối bao gồm assertion Python, setup và teardown; skip được ghi riêng, không tính pass. Chạy lại cùng RUN_ID sẽ nối thêm lần chạy. `results/results.csv` và `results/summary.md` tổng hợp cả 24 mã từ mọi JSONL, không điền kết quả giả. Setup đăng nhập không tạo thêm dòng TC.

`fresh_app` force-stop, `pm clear`, rồi mở bằng `monkey`; thao tác này xóa dữ liệu app trên thiết bị, không xóa Firestore. TC-03 gửi email reset thật; TC-15/18/19/20 tạo/cập nhật dữ liệu thật. Chuẩn bị lại nhiệm vụ `Chưa học` trước vòng tiếp theo và dọn dữ liệu test theo chính sách dự án. TC-24 sinh mật khẩu tạm, phục hồi mật khẩu gốc trong finally, kể cả khi ca lỗi; nếu cleanup thất bại cần khôi phục tài khoản trước vòng sau.

Mật khẩu được gửi trong goal tới ARTEMIS để nhập UI nhưng được che `***` trong JSONL và đối tượng kết quả/assertion của suite. Suite không print instruction, không bật HTTP debug, không lưu logcat thô. Không dùng `--showlocals`, tracing HTTP hoặc plugin pytest ghi locals khi xử lý tài khoản thật. Trace/log của **server ARTEMIS** có thể giữ goal/thao tác nhập, cần quản lý quyền truy cập và lưu trữ tại server.

## Thao tác ngoài app

**TC-09:** manual/skip vì `pm clear` xóa cả Auth. Setup loại cache: force-stop → `pm clear` → tắt Wi-Fi/data → mở app; nhưng app sẽ ở Login, không vào tra cứu offline được. Cần setup phiên Auth hợp lệ mà chưa tải Firestore trước khi đo lỗi tải/retry. Không coi cache hoặc lỗi đăng nhập là lỗi tải công thức.

**TC-13:** fixture đặt `adb shell setprop debug.firebase.analytics.app <RH_APP_PACKAGE>` trước khi khởi động app, reset `.none.` khi xong. Xóa logcat, mở `Americano Nóng`, poll tối đa 30 giây qua `adb logcat -d -s FA-SVC`, kiểm tra `name=view_recipe`, `recipe_code`, `category`, `size`, `source=lookup`, không chứa credential/email hoặc khóa PII thông dụng. Chỉ kiểm tra event tương ứng, không lấy tham số từ event khác.

**TC-21:** cần Console operator ở mỗi vòng. Chờ `results/<RUN_ID>.tc21-baseline-ready`, đọc `max_lookup_results` hiện tại và ghi số nguyên đó vào `tc21-baseline-done` (không giả định giá trị). Ví dụ tại `e2e_test/`: `Set-Content results/round1.tc21-baseline-done 50` chỉ khi đã đọc được giá trị gốc là 50. Test chọn target 1 (hoặc 2 khi gốc là 1); số card baseline phải khác target. Khi có `tc21-ready`, publish target ghi trong ready rồi tạo `tc21-done`. Giữ app foreground, không sync/reload/restart. Trong finally, chờ `tc21-restore-ready`, khôi phục CHÍNH XÁC giá trị gốc rồi tạo `tc21-restore-done`. Mỗi handshake tối đa 180 giây, kiểm realtime tối đa 90 giây; thiếu xác nhận sẽ fail. TC-21 nằm trong `not manual`, operator phải theo dõi cả ba vòng.

**TC-23:** luôn có marker `manual`, skip nếu không đặt `RH_FCM_SENT=1`:

```powershell
$env:RH_FCM_SENT = "1"
$env:RUN_ID = "fcm-check"
uv run pytest -v -k TC-23
```

Sau setup đăng nhập mới, test dùng ADB đưa app về background và tạo `results/fcm-check.tc23-ready`. Lấy FCM token **hiện tại** (pm clear có thể đổi token), gửi từ Firebase Console notification title `Cập nhật công thức`, data key `type` value `recipe`. Sau khi gửi, tạo `results/fcm-check.tc23-done` trong 180 giây. ARTEMIS tap notification mới từ khay Android và xác nhận mở trực tiếp `Thông báo & Thay đổi`. Không gửi trước setup hoặc dùng token cũ. `RH_FCM_SENT=1` cho phép chạy ca, ready/done handshake xác định đúng thời điểm gửi.

## Đối chiếu UI và giới hạn chứng minh

Đã đối chiếu `lib/features/`: `Tìm theo tên món...`, `Tra cứu tại quầy`, `Quên mật khẩu?`, `Gửi thư đặt lại`, `ĐỊNH LƯỢNG NGUYÊN LIỆU`, `Xem video chuẩn`, `Bước tiếp theo`, `Sổ tay SOP`, `Mục lục`, `Xuất PDF`, `Làm quiz`, `Nộp bài kiểm tra`, `Tự luyện quầy bar`, `Bấm giờ`, `Lưu lần luyện tập`, `Xuất báo cáo PDF`, `Chấm ngay`, `Lưu đánh giá thực hành tại quầy`, `Thư viện`, `Gửi phản hồi`, `Đổi mật khẩu tài khoản`, `Đăng xuất khỏi quầy bar`.

- TC-04 manual/skip vì Login không có UI xin quyền Admin; Flutter AuthViewModel test kiểm riêng fallback, không suy thành E2E pass.
- Badge UI hiện có thể dùng `Barista` thay cho enum `VIEWER`; xác nhận vai trò hiển thị và tab tương ứng, không yêu cầu UI lộ mã kỹ thuật.
- TC-12 mở detail từ Lookup trong cùng ca để độc lập. Thiếu video/dữ liệu chuẩn là fail, không skip âm thầm.
- TC-17 hiện lưu xong vẫn ở timer: test mở `Lịch sử` để kiểm tra bản ghi trước khi export.
- TC-19 dùng một thiết bị, chuyển A → Admin và xác nhận nhận feedback/ảnh qua list mà không refresh. Điều này chứng minh nhận dữ liệu sau đổi phiên; không đo được độ trễ real-time đồng thời giữa hai thiết bị.
- TC-20 tự tạo feedback A với nội dung duy nhất trước khi chuyển B, không phụ thuộc TC-19; kiểm tra toàn danh sách B.

## API đã kiểm tra tại checkout ghim

Đọc `packages/artemis-client/README.md`, `src/artemis_client/client.py`, `models.py`, `examples/basic.py`. Dùng `ArtemisClient(base_url, device_serial=..., default_profile=...)` và `await client.run(goal, enable_outputter=True, expected_output=...)`. `expected_output` là **chuỗi hướng dẫn**, client này không nhận `schema`/`response_schema`; suite yêu cầu JSON rồi parse `result.output` (dict hoặc chuỗi JSON, chấp nhận fence JSON). Kiểm tra `result.succeeded`, dùng `result.trace_id`, `result.error`, `result.status`. Thành công của agent chưa đủ: mọi ca còn assert output; TC-13 kiểm tra logcat từ host.

Follow-up offline không chạy uv sync/pytest thiết bị. Đã thử Flutter analyze/test với --no-pub nhưng chưa có kết quả; Python chưa khởi chạy được. Xem docs/coderabbit-followup.md.


## Tùy chọn ADB_LOGIN và E2E_REUSE_SESSION

- `ADB_LOGIN=1`: nhập Viewer bằng ADB; toạ độ email `(400,660)`, password `(380,848)`, submit `(360,1134)` đo trên Redmi 7 **720×1520**. Thiết bị khác cần đo lại `_LOGIN_POINTS`. Mặc định tắt.
- `E2E_REUSE_SESSION=1`: chỉ có hiệu lực với `ADB_LOGIN=1`; tái dùng Viewer cùng tài khoản qua `results/.session`. TC-19/20/24 invalidate marker trước thao tác đổi phiên; `fresh_app` cũng xóa marker.
- TC-24 dùng tài khoản password test riêng, nhập đủ ba ô và phục hồi mật khẩu gốc trong finally kể cả khi assertion lỗi.
