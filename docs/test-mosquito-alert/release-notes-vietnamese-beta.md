# Test Mosquito Alert — Internal Testing Release Notes (Vietnamese beta)

Use these notes for both Apple TestFlight (DevTF scheme) and Google Play
Internal Testing (Android `dev` flavor) for the first build that includes
Vietnamese localisation. Build the AAB and the iOS archive from the
`feature/vietnamese-beta` branch.

> **Important for all testers:** *Test Mosquito Alert* points to our
> **development server** (`apidev.mosquitoalert.com`). Any reports submitted
> here are visible to the developer team only and are **not** used in any
> public dataset. Please feel free to submit fake / dummy reports — they will
> not pollute production data.

---

## What to Test — English (paste into TestFlight + Play Internal listing)

This is the first build of Test Mosquito Alert that includes the Vietnamese
language. We are looking for two kinds of feedback:

**1. Vietnamese translation quality**
- Open the app and switch your device language to Vietnamese (or install on a
  Vietnamese-language device).
- Walk through onboarding, the report-a-mosquito flow, the report-a-breeding-
  site flow, the settings screen, and the notifications screen.
- Note any text that is unclear, wrong, or feels unnatural. Screenshots are
  very helpful — please share the screen and the suggested better wording.
- A handful of obvious errors have already been corrected directly in this
  build (e.g. Reset/Save/OK button labels, the "Enter your password" title).
  Please call out anything else that still reads badly.

**2. General app stability**
- Submit a few test reports of each type (adult mosquito, breeding site,
  bite). Confirm they upload successfully.
- Toggle background tracking on and off in Settings and confirm the toggle
  behaves as expected.
- Confirm the map loads and your location appears.
- Take photos using both the in-app camera and gallery picker.

Reports submitted in Test Mosquito Alert go to our development server and are
not used in real research — please feel free to submit anything for testing.

---

## What to Test — Vietnamese (paste into TestFlight + Play Internal listing)

> *(Translator note: the section below was drafted in English first; please
> have a native Vietnamese speaker review and refine it before use. The text
> deliberately avoids relying on the existing Loco translations because those
> are exactly what we are trying to validate.)*

Đây là bản dựng đầu tiên của Test Mosquito Alert có hỗ trợ tiếng Việt.
Chúng tôi mong nhận được hai loại phản hồi:

**1. Chất lượng bản dịch tiếng Việt**
- Mở ứng dụng và chuyển ngôn ngữ thiết bị sang tiếng Việt (hoặc cài đặt trên
  thiết bị đã đặt ngôn ngữ tiếng Việt).
- Thử các luồng chính: đăng ký / đăng nhập, gửi báo cáo muỗi, gửi báo cáo địa
  điểm sinh sản, cài đặt và thông báo.
- Ghi lại bất kỳ đoạn văn bản nào không rõ ràng, sai nghĩa, hoặc nghe không tự
  nhiên. Ảnh chụp màn hình kèm gợi ý sửa lại sẽ rất hữu ích.
- Một số lỗi rõ ràng đã được sửa trong bản dựng này (ví dụ: các nút Đặt lại /
  Lưu / OK, tiêu đề "Nhập mật khẩu của bạn"). Vui lòng góp ý thêm cho những
  chỗ còn đọc chưa thuận.

**2. Tính ổn định chung của ứng dụng**
- Gửi thử một vài báo cáo cho mỗi loại (muỗi trưởng thành, địa điểm sinh sản,
  vết cắn) và xác nhận chúng được tải lên thành công.
- Bật/tắt theo dõi nền trong Cài đặt và kiểm tra xem công tắc có hoạt động
  đúng không.
- Kiểm tra bản đồ tải đúng và vị trí của bạn hiển thị.
- Thử chụp ảnh bằng cả camera trong ứng dụng và bằng thư viện ảnh.

Tất cả báo cáo trong Test Mosquito Alert được gửi tới máy chủ phát triển và
**không** được sử dụng cho nghiên cứu thực tế — bạn có thể gửi dữ liệu thử
nghiệm tuỳ ý.

---

## Internal release notes (for the build / changelog)

```
Test Mosquito Alert — Vietnamese beta build

- Restores the vi_VN locale that was removed in production until translation
  quality reached 80% in Localise.biz.
- Adds vi_VN to FORCE_LANGUAGES in update_locales.py so it keeps pulling
  during translation work.
- Fixes 12 obviously-broken Vietnamese strings (Spanish leak, opposite
  meanings, translator-context text pasted into the translation field).
  See docs/test-mosquito-alert/loco-vietnamese-fixes.md.
- iOS: build with the "devtf" scheme; bundle "Test Mosquito Alert"
  (cat.ibeji.tigatrapp.devtf), distributed via TestFlight DevTF group.
- Android: build with `--flavor dev --target lib/main.dart`; applicationId
  `ceab.movelab.tigatrapp.dev`, distributed via Google Play Internal Testing.
- Both flavors point to the development backend (apidev.mosquitoalert.com),
  so submitted reports do not enter the production dataset.
```
