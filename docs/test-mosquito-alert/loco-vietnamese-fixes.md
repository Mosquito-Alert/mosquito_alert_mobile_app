# Vietnamese (vi_VN) — Loco / Localise.biz string updates

These changes were applied directly to `assets/language/vi_VN.json` on the
`feature/vietnamese-beta` branch (commit `17dde8d8`). They **must also be
entered into Localise.biz**, otherwise the next run of `update_locales.py`
will overwrite them with the broken originals.

Source data: `assets/language/en_US.json` (reference) and the previous content
of `assets/language/vi_VN.json` shipped to Loco.

---

## Section 1 — High-confidence fixes (already applied in code)

Each fix below addresses an unambiguous bug: text in the wrong language,
opposite meaning, or developer/translator context notes that the translator
pasted into the translation field.

| # | Key | English | VI (broken) | VI (proposed) | Why |
|---|-----|---------|-------------|---------------|-----|
| 1 | `single_mosquito` | Mosquito | *"Để xác định loại báo cáo khi liệt kê tất cả các báo cáo. Báo cáo về muỗi sẽ có tiêu đề là văn bản này (ở dạng số ít). Tránh sử dụng các mạo từ như \"A mosquito\", thay vào đó chỉ sử dụng \"Mosquito\""* | **Muỗi** | Translator's instruction note ended up in the translation field |
| 2 | `single_breeding_site` | Breeding site | *"xác định loại báo cáo khi liệt kê tất cả các báo cáo. Báo cáo về địa điểm sinh sản sẽ có tiêu đề là văn bản này (ở dạng số ít). Tránh sử dụng mạo từ như \"Địa điểm sinh sản\", thay vào đó chỉ sử dụng \"Địa điểm sinh sản\""* | **Địa điểm sinh sản** | Same — instructions leaked into translation |
| 3 | `single_bite` | Bite | *"xác định loại báo cáo khi liệt kê tất cả các báo cáo. Báo cáo Bite sẽ có tiêu đề là văn bản này (ở dạng số ít). Tránh sử dụng các mạo từ như \"A bite\", thay vào đó chỉ sử dụng \"Bite\""* | **Vết cắn** | Same — instructions leaked into translation |
| 4 | `auto_tagging_settings_placeholder` | Enter tag... | Cài đặt Gắn thẻ tự động giữ chỗ | **Nhập thẻ...** | The Loco field hint word *"placeholder"* was translated literally as text |
| 5 | `auto_tagging_settings_title` | Auto-tagging | Cài đặt gắn thẻ tiêu đề tự động | **Tự động gắn thẻ** | The Loco field hint word *"title"* leaked into the translation |
| 6 | `terms_and_conditions_txt3` | and | Y | **và** | Spanish *"Y"* leaked through; should be Vietnamese *"và"* |
| 7 | `enter_password_title` | Enter your password | Tạo mật khẩu cụ thể để đăng ký Mosquito Alert | **Nhập mật khẩu của bạn** | Old text means *"Create a specific password to register Mosquito Alert"* |
| 8 | `access_txt` | OK | Truy cập | **OK** | Old text means *"Access"* — this string is used as an OK confirmation button |
| 9 | `reset` | Reset | Khởi động lại | **Đặt lại** | Old text means *"Restart"* (e.g. reboot device), not *"Reset"* (revert to defaults) |
| 10 | `save` | Save | Sao lưu | **Lưu** | Old text means *"Back up"*, not *"Save"* |
| 11 | `terms_and_conditions_txt1` | Check | Kiểm tra lại | **Đọc** | Context is *"Check the terms and conditions"* (the user is being asked to read them, not re-verify them) |
| 12 | `plural_bite` | Bites | Bị muỗi cắn nhiều lần | **Vết cắn** | Old text means *"Bitten by mosquitoes multiple times"*; Vietnamese has no grammatical plural — kept consistent with the new `single_bite` |

### How to enter these in Loco

For each row above, in Localise.biz:

1. Switch to the **Vietnamese (vi_VN)** locale.
2. Search for the key (e.g. `single_mosquito`).
3. Replace the translation with the bold value from the *VI (proposed)* column.
4. Save.

Once all 12 are entered, the next `python3 update_locales.py` pull will be a
no-op for these keys.

---

## Section 2 — Lower-confidence items for native-speaker review

These were **not** changed in code. The current translation is intelligible
but stylistically off, or there is a more idiomatic shorter form. Please ask
a Vietnamese-speaking collaborator to confirm before changing in Loco.

| Key | English | VI (current) | Suggested alternative | Note |
|-----|---------|--------------|------------------------|------|
| `delete` | Delete | Xoá bỏ | **Xoá** | *"Xoá"* alone is the standard short UI verb |
| `exit` | Exit | Thoát ra | **Thoát** | *"Thoát"* alone is the standard Exit-button label |
| `ok_next_txt` | OK | Được rồi | **OK** or **Đồng ý** | *"Được rồi"* is informal ("alright"); a confirmation button typically uses *"OK"* or *"Đồng ý"* |

---

## Section 3 — Known-good entries that the automated audit also flagged

For completeness, the automated audit also flagged these as suspicious, but
inspection shows they are actually fine and should be left alone:

- `ok`, `cancel`, `yes`, `no`, `edit`, `continue_txt`, `retry`, and the
  `question_*_answer_*` Yes/No options — flagged only because the English
  source matched a short canonical UI verb pattern; the Vietnamese
  translations are correct.
- `no_show_info` (EN *"Not now"* → VI *"Không phải bây giờ"*) — flagged for
  length; the translation is correct, Vietnamese is just longer.
- The three asset-path keys `lisence_link`, `privacy_link`, `terms_link`
  pointing to `_en.html` are intentional fallbacks, not translation errors.
