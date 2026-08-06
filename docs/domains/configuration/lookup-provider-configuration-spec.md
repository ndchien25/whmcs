# Lookup Provider Configuration Specification

**Version:** 0.2  
**Status:** Draft

## 1. References

- [WHMCS 9.0 — Lookup Providers](https://docs.whmcs.com/9-0/domains/lookup-providers/)
- [WHMCS 9.0 — Domain Pricing](https://docs.whmcs.com/9-0/domains/pricing-and-configuration/domain-pricing/)
- [WHMCS 9.0 — eNom Registrar Module](https://docs.whmcs.com/9-0/domains/domain-registrar-modules/enom/)
- [eNom API — GetNameSuggestions](https://api.enom.com/docs/getnamesuggestions)
- [eNom API — Check](https://api.enom.com/docs/check)
- [`resources/domains/dist.whois.json`](../../../resources/domains/dist.whois.json) — Cấu hình WHOIS endpoint và chuỗi nhận biết availability theo từng TLD

## 2. Purpose

Đặc tả cấu hình provider dùng để kiểm tra domain availability trong domain checker và cart.

## 3. Supported Providers

Hệ thống chỉ hỗ trợ hai provider:

| Provider | Meaning |
|---|---|
| Standard WHOIS | Chỉ kiểm tra availability trực tiếp qua WHOIS servers; không hỗ trợ Premium Domains |
| Domain Registrar | Dùng registrar eNom để kiểm tra availability, suggestion và Premium Domain data |

Không hỗ trợ WHMCS Namespinning.

## 4. Default Provider

- Provider mặc định là `Standard WHOIS`.
- Chỉ đổi sang `Domain Registrar` khi cần lookup qua eNom hoặc bán Premium Domains.
- Tại một thời điểm chỉ có một active Lookup Provider.

## 5. Change Provider

Admin thực hiện tại Domain Pricing > Lookup Provider:

1. Nhấn **Change**.
2. Chọn **Standard WHOIS** hoặc **Domain Registrar**.
3. Nếu chọn Domain Registrar, chọn eNom.
4. Cấu hình các TLD cần lookup.
5. Nhấn **Save**.

Provider mới chỉ có hiệu lực sau Save thành công.

Premium Domains phụ thuộc vào active Lookup Provider:

- Chuyển từ `Standard WHOIS` sang `Domain Registrar (eNom)` chỉ làm cho cấu hình `Premium Domains` khả dụng; admin phải chủ động bật.
- Chuyển từ `Domain Registrar (eNom)` về `Standard WHOIS` tự động tắt `Premium Domains` vì Standard WHOIS không thể trả premium classification và premium price.
- Không cho phép bật lại Premium Domains khi provider hiện tại là Standard WHOIS.

## 6. Standard WHOIS

### 6.1. Behavior

- Kiểm tra availability bằng WHOIS server của từng TLD.
- Có thể kiểm tra domain khách nhập cùng các extension bổ sung đã được chọn.
- Trả availability và normal pricing của các TLD được tìm thấy cho domain checker/cart.
- Không cung cấp WHMCS Namespinning.
- Không trả Premium Domain classification hoặc premium price.

### 6.2. Configuration

Admin nhấn **Configure** và chọn các extension bổ sung cần lookup.

Form hiển thị toàn bộ TLD trong Domain Pricing theo đúng display order. Đây là multi-select; admin có thể chọn hoặc bỏ chọn nhiều TLD.

Ví dụ chọn `.com`, `.net`, `.org`:

- Khách tìm extension đã nhập.
- Hệ thống đồng thời kiểm tra cùng label với `.com`, `.net`, `.org`.
- Kết quả chỉ hiển thị TLD đã cấu hình và có pricing phù hợp.

### 6.3. Persisted settings

Cấu hình Standard WHOIS được lưu trong `tbldomain_lookup_configuration`:

| registrar | setting | value |
|---|---|---|
| `WhmcsWhois` | `useWhmcsWhoisForSuggestions` | `on` |
| `WhmcsWhois` | `suggestTlds` | Các TLD được chọn, nối bằng dấu phẩy, ví dụ `.net,.biz` |

Rules:

- Giữ nguyên tên registrar `WhmcsWhois` và tên setting giống WHMCS.
- `suggestTlds` lưu extension đầy đủ có dấu chấm ở đầu.
- Thứ tự trong `suggestTlds` theo thứ tự TLD được chọn trên form.
- Khi có lựa chọn, `suggestTlds` lưu danh sách đã chọn. Trường hợp không chọn TLD nào cần giữ đúng hành vi persistence của WHMCS: không tạo row hoặc xóa row `suggestTlds` thay vì suy diễn một danh sách mặc định.
- `useWhmcsWhoisForSuggestions=on` cho phép Standard WHOIS dùng danh sách `suggestTlds` để kiểm tra thêm extension; đây không phải WHMCS Namespinning.

### 6.4. Registry WHOIS configuration

Standard WHOIS không dùng eNom API. Hệ thống lookup trực tiếp đến WHOIS endpoint được cấu hình cho extension trong [`dist.whois.json`](../../../resources/domains/dist.whois.json).

File là một JSON array. Mỗi rule có cấu trúc:

| Field | Required | Meaning |
|---|---|---|
| `extensions` | Có | Một hoặc nhiều extension dùng chung rule, phân cách bằng dấu phẩy và có dấu chấm đầu |
| `uri` | Có | WHOIS endpoint của registry; hỗ trợ `socket://`, `http://` hoặc `https://` theo dữ liệu hiện có |
| `available` | Có | Chuỗi trong response cho biết domain chưa được đăng ký |
| `comment` | Không | Ghi chú hoặc giới hạn đặc biệt của registry |

Ví dụ:

```json
{
  "extensions": ".com,.net,.es,.com.es,.nom.es,.gob.es,.edu.es",
  "uri": "socket://whois.crsnic.net",
  "available": "No match for"
}
```

### 6.5. Standard WHOIS lookup logic

1. Chuẩn hóa domain và xác định extension khớp trong `dist.whois.json`.
2. Với extension nhiều cấp như `.com.es`, ưu tiên extension đầy đủ/dài nhất; không được chọn nhầm rule `.es` hoặc `.com`.
3. Gửi full domain đến `uri` của rule:
   - `socket://`: mở WHOIS socket và gửi query domain.
4. Đọc raw response.
5. Nếu response chứa chuỗi `available` của rule thì kết quả là `Available`.
6. Nếu request thành công nhưng không có chuỗi `available` thì kết quả là `Unavailable`.

Rules:

- Mỗi TLD muốn lookup bằng Standard WHOIS phải có rule tương ứng trong `dist.whois.json`.
- Không có rule cho TLD thì trả `Unsupported`; không tự fallback sang eNom.
- Connection timeout, HTTP/socket error hoặc response không thể đọc được trả `Unknown/Error`, không được coi là `Available`.
- `available` là marker riêng của từng registry, không dùng một marker chung cho tất cả TLD.
- `comment` không tham gia parse availability nhưng phải được giữ khi cập nhật file.
- Standard WHOIS độc lập với eNom Auto Registration: lookup có thể đi đến registry WHOIS nhưng registration vẫn được provision qua eNom.

## 7. Domain Registrar — eNom

### 7.1. Prerequisite

- eNom đã `Configured` theo [Registrar Configuration Spec](./registrar-configuration-spec.md).
- Credential và `TestMode` hiện tại quyết định endpoint eNom được dùng.

### 7.2. Behavior

- Gọi `GetNameSuggestions` để tạo danh sách domain gợi ý.
- Domain do `GetNameSuggestions` trả về chưa được coi là available; gọi `Check` lại cho từng suggestion trước khi hiển thị là có thể mua.
- Có thể cung cấp registrar suggestion và Premium Domain data nếu eNom hỗ trợ cho TLD.
- Provider lookup là eNom không bắt buộc TLD phải chọn eNom Auto Registration, dù dự án hiện chỉ hỗ trợ registrar eNom.
- Lỗi eNom không được chuyển thành Available.

### 7.3. TLD selection

- Admin chọn các TLD để eNom kiểm tra thêm ngoài extension khách nhập.
- Chỉ TLD đã tồn tại trong Domain Pricing mới được chọn.
- Thứ tự hiển thị TLD dùng `tbldomainpricing.order ASC, id ASC`.

### 7.4. eNom configuration form

Ngoài multi-select TLD, form eNom có ba cấu hình suggestion:

| UI field | setting | Value |
|---|---|---|
| Maximum Number of Suggestions to Return | `suggestMaxResultCount` | Số lượng tối đa, mặc định/recommended là `100` |
| Only suggest domains in General Availability | `suggestOnlyGeneralAvailability` | Bật: `on`; tắt: chuỗi rỗng |
| Include Adult Domains in Suggestions | `suggestAdultDomains` | Bật: `on`; tắt: chuỗi rỗng |

Ý nghĩa:

- `suggestMaxResultCount` giới hạn số suggestion tối đa eNom trả về.
- `suggestOnlyGeneralAvailability=on` chỉ nhận suggestion đang ở trạng thái General Availability.
- `suggestAdultDomains=on` cho phép suggestion có nội dung adult; mặc định tắt.

### 7.5. Persisted settings

Cấu hình eNom được lưu thành từng row trong `tbldomain_lookup_configuration` với `registrar='enom'`:

| registrar | setting | Example value |
|---|---|---|
| `enom` | `suggestMaxResultCount` | `100` |
| `enom` | `suggestOnlyGeneralAvailability` | `on` hoặc chuỗi rỗng |
| `enom` | `suggestAdultDomains` | `on` hoặc chuỗi rỗng |
| `enom` | `suggestTlds` | Row tùy chọn; danh sách TLD được chọn, nối bằng dấu phẩy |

Nếu eNom không chọn TLD bổ sung thì không cần có row `enom/suggestTlds`. Ba row `suggestMaxResultCount`, `suggestOnlyGeneralAvailability` và `suggestAdultDomains` vẫn được lưu; checkbox tắt có value là chuỗi rỗng.

Các row cấu hình `WhmcsWhois` có thể vẫn tồn tại khi active provider chuyển sang eNom. Không dùng sự tồn tại của row để xác định provider đang active.

## 8. Lookup versus Auto Registration

Hai cấu hình độc lập:

| Config | Purpose |
|---|---|
| Standard WHOIS lookup | Chỉ trả availability dựa trên registry WHOIS response |
| Domain Registrar/eNom lookup | Trả availability, registrar suggestion và premium data khi Premium Domains được bật |
| Auto Registration | Chọn registrar nhận request sau payment |

Lookup thành công không đăng ký domain và không giữ chỗ domain. Trước provision, Domain Registration flow vẫn phải recheck theo rule của nó.

## 9. Pricing Interaction

- Normal domain price lấy từ Domain Pricing.
- Premium Domains chỉ hoạt động khi Lookup Provider là `Domain Registrar (eNom)`.
- Chuyển từ Standard WHOIS sang eNom không tự bật Premium Domains.
- Chuyển từ eNom về Standard WHOIS phải tự tắt Premium Domains.
- Premium price được eNom trả real-time rồi áp premium markup; giá này không lấy từ normal pricing matrix.
- Domain có kết quả Available nhưng không có Registration price hợp lệ thì không được thêm vào cart.
- TLD được chọn để lookup nhưng đã bị xóa khỏi Domain Pricing không được hiển thị để bán.

## 10. Save Configuration

Khi Save:

1. Validate provider thuộc danh sách hỗ trợ.
2. Nếu là Domain Registrar, validate eNom đang `Configured`.
3. Validate các selected TLD còn tồn tại.
4. Upsert từng setting của provider vào `tbldomain_lookup_configuration`.
5. Lưu active provider riêng với các setting của provider.
6. Không xóa setting của provider cũ chỉ vì admin chuyển provider; chúng được giữ để dùng lại khi chuyển về.
7. Cấu hình mới được dùng cho lookup request tiếp theo.

Các cột được sử dụng:

| Column | Meaning |
|---|---|
| `id` | Primary key của row cấu hình |
| `registrar` | `WhmcsWhois` hoặc `enom` |
| `setting` | Tên setting chính xác như các bảng trên |
| `value` | Giá trị cấu hình; các value này không mã hóa |
| `created_at` | Thời điểm tạo row |
| `updated_at` | Thời điểm cập nhật gần nhất |

## 11. Delete TLD Interaction

Khi xóa một TLD khỏi Domain Pricing:

- Hệ thống đọc các setting `suggestTlds` trong `tbldomain_lookup_configuration`.
- Loại extension bị xóa khỏi danh sách của từng provider có chứa TLD đó, bao gồm `WhmcsWhois` và `enom` nếu có.
- Ghi lại value `suggestTlds` bằng danh sách còn lại, vẫn sử dụng dấu phẩy làm delimiter.
- Nếu không còn TLD nào, value trở thành chuỗi rỗng hoặc row `suggestTlds` được xóa theo đúng persistence convention của provider.
- TLD đã xóa không còn được lookup hoặc hiển thị trong domain checker/cart.
- Việc cập nhật `suggestTlds` diễn ra ngay trong luồng xóa TLD; admin không cần mở và Save lại Lookup Provider configuration.
