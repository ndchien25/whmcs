# Domain Transfer Specification

**Version:** 0.1  
**Status:** Draft  
**Operation:** Transfer Domain

## 1. References

- [WHMCS 9.0 — Domain Transfers](https://docs.whmcs.com/9-0/domains/renewals-and-transfers/domain-transfers/)
- [ICANN — Transfer Policy](https://www.icann.org/en/contracted-parties/accredited-registrars/resources/domain-name-transfers/policy)
- [eNom API — Check](https://api.enom.com/docs/check)
- [TLD Pricing Configuration](../configuration/tld-pricing-spec.md)
- [Lookup Provider Configuration](../configuration/lookup-provider-configuration-spec.md)
- [Domain Registration](../registration/domain-registration-spec.md)

## 2. Purpose

Đặc tả nghiệp vụ khách nhập domain đang đăng ký ở registrar khác, kiểm tra domain, cấu hình transfer và đưa transfer item vào cart.

## 3. Scope

Trong phạm vi:

```text
Normalize & Validate Input
  -> Check Local System
  -> Check Domain Exists Remotely
  -> Configure Transfer
  -> Add to Cart
```

Ngoài phạm vi:

- Checkout, invoice và payment.
- Gửi transfer request đến eNom.
- FOA, email confirmation, polling và Domain Sync.
- Retry, completion, failure và reconciliation sau payment.

## 4. Dependencies

- Admin đã bật **Allow clients to transfer a domain to you**.
- Exact TLD tồn tại trong Domain Pricing.
- TLD có Transfer 1 Year đang Enable và price khác `-1.00`.
- Lookup Provider đã được cấu hình.
- Nếu Auto Registration của TLD là eNom, module eNom phải đang `Configured`.

Không hiển thị hoặc không cho bắt đầu Transfer Domain khi global transfer setting đang tắt.

## 5. Transfer Input

Màn **Single domain transfer** nhận:

- Domain Name.
- Authorization Code nếu exact TLD bật **EPP Code**.

Domain transfer phải là full domain, ví dụ `example.com`. Không nhận label-only vì operation transfer cần xác định exact domain và exact TLD.

## 6. Normalize and Validate

Dùng cùng normalization và domain validation của Domain Registration:

1. Trim input.
2. Lowercase.
3. Xác định exact TLD theo match dài nhất.
4. Giữ Unicode để hiển thị và tạo ASCII/punycode canonical domain.
5. Validate cấu trúc, ký tự, IDN setting và giới hạn độ dài.

Ngoài ra:

- Exact TLD phải có Transfer 1 Year hợp lệ.
- Không tạo suggestion hoặc Spotlight Domain cho transfer.
- Validation lỗi thì không gọi Lookup Provider.

## 7. Check Domain in Local System

Transfer-in chỉ dành cho domain chưa được hệ thống quản lý:

```text
Domain đã tồn tại trong hệ thống
  -> không cho transfer-in lần nữa

Domain chưa tồn tại trong hệ thống
  -> tiếp tục remote lookup
```

Rules:

- So sánh bằng normalized ASCII/punycode full domain.
- Chặn domain record đã tồn tại trong dữ liệu domain nội bộ.
- Chặn register/transfer cart item trùng domain.
- Local check chạy trước provider lookup và có quyền chặn kết quả remote.

## 8. Remote Domain Check

Mục tiêu của transfer lookup ngược với register lookup:

```text
Register cần domain chưa được đăng ký.
Transfer cần domain đã được đăng ký ở bên ngoài.
```

Remote lookup chỉ xác nhận domain có tồn tại để bắt đầu transfer. Nó không chứng minh domain đã unlock, đủ 60 ngày, EPP đúng hoặc chắc chắn transfer thành công.

### 8.1. Standard WHOIS

Standard WHOIS query chính xác full domain theo registry rule của exact TLD:

| WHOIS result | Transfer interpretation |
|---|---|
| Không tìm thấy domain, response chứa availability marker | Không thể transfer vì domain chưa đăng ký |
| Tìm thấy domain, response không chứa availability marker | Domain tồn tại; cho tiếp tục Configure Transfer |
| Unsupported/Error | Không cho tiếp tục |

Với Standard WHOIS, domain phải **được tìm thấy** mới hợp lệ để transfer.

### 8.2. Domain Registrar — eNom

Gọi eNom `Check` với exact `SLD` và `TLD`:

| eNom result | Transfer interpretation |
|---|---|
| `RRPCode=210`, Available | Không thể transfer vì domain chưa đăng ký |
| `RRPCode=211`, Domain not available | Domain tồn tại; cho tiếp tục Configure Transfer |
| API error hoặc kết quả không xác định | Không cho tiếp tục |

Với provider eNom, domain cần trả kết quả **not available** theo nghĩa availability lookup thì mới là domain có thể bắt đầu transfer.

Premium classification không tham gia transfer lookup và không override Transfer price.

## 9. Transfer Price and Term

- Dùng Transfer price của exact TLD, không dùng Registration hoặc Renewal price.
- Transfer chỉ dùng kỳ hạn 1 năm.
- Nếu Transfer 1 Year bị Disable hoặc bằng `-1.00`, TLD không hỗ trợ transfer trên client area.
- Transfer hoàn tất thường cộng thêm một năm vào thời hạn hiện tại; tổng unexpired term không được vượt quá 10 năm theo ICANN Transfer Policy.
- Lookup không thể xác định chắc chắn domain có vượt giới hạn 10 năm hay không; registrar/registry xác nhận khi xử lý transfer.

## 10. EPP/Authorization Code

Việc hiển thị EPP phụ thuộc cấu hình **EPP Code** của exact TLD.

```text
EPP Code = true
  -> hiển thị Authorization Code trên màn nhập transfer
  -> hiển thị lại ô EPP Code trên Domain Configuration
  -> client được sửa trước khi Continue

EPP Code = false
  -> không hiển thị và không yêu cầu EPP Code
```

Rules:

- EPP Code là bắt buộc khi TLD bật config này.
- Giá trị nhập ở màn Single Domain Transfer được điền sẵn trên màn Domain Configuration.
- Client có thể sửa EPP Code tại Domain Configuration; giá trị cuối cùng khi Continue được lưu vào cart item.
- Không xác minh EPP Code bằng availability lookup.
- EPP sai chỉ được registrar/registry xác nhận khi transfer request được gửi sau payment.
- Không hiển thị lại EPP Code ở dạng plaintext ngoài form cần chỉnh sửa và không đưa EPP vào mô tả cart công khai.

## 11. Configure Transfer

Màn **Domains Configuration** hiển thị:

- Exact domain.
- Transfer period: 1 Year.
- Transfer price.
- EPP Code có thể sửa nếu TLD bật EPP.
- Domain addon đang bật trên TLD.
- Nameserver 1–5 được điền từ Default Nameservers của admin và client có thể custom.
- Custom Domain Fields của exact TLD nếu có.
- IDN Language nếu domain là IDN và Auto Registration của TLD là eNom.

Addon, nameserver, custom field và IDN Language dùng cùng rule trong Domain Registration spec.

## 12. Add to Cart

Khi client nhấn **Continue/Add to Cart**:

1. Xác nhận global transfer setting vẫn bật.
2. Validate lại normalized domain và exact TLD.
3. Kiểm tra domain vẫn chưa tồn tại trong hệ thống hoặc cart.
4. Xác nhận remote result gần nhất cho biết domain tồn tại.
5. Xác nhận Transfer 1 Year vẫn Enable và có price hợp lệ.
6. Validate EPP, addon, nameserver, custom fields và IDN Language.
7. Tạo domain cart item với operation `transfer`.

Transfer cart item lưu:

- Unicode domain nếu có.
- ASCII/punycode canonical domain.
- Exact TLD.
- Operation `transfer`.
- Transfer term `1 Year`.
- Transfer price hiện tại.
- EPP Code cuối cùng nếu được yêu cầu.
- Addon đã chọn.
- Nameserver cuối cùng.
- Custom domain fields và eNom extended-attribute mapping nếu có.
- IDN language/country code nếu áp dụng.

## 13. ICANN Eligibility Notes

Domain tồn tại không đồng nghĩa chắc chắn transfer được. Registrar of Record hoặc registry có thể từ chối, bao gồm:

- Domain được tạo trong vòng 60 ngày.
- Domain đã transfer registrar trong vòng 60 ngày.
- Domain đang chịu 60-day Change of Registrant lock.
- Domain đang `ClientTransferProhibited` và chưa unlock.
- AuthInfo/EPP Code không hợp lệ.
- Domain thuộc trường hợp tranh chấp, court order hoặc policy denial khác.

Các điều kiện này không được suy diễn từ WHOIS/eNom availability result. Trạng thái cuối cùng chỉ được xác nhận khi eNom gửi transfer request đến registry sau payment.

## 14. Rules

1. Domain đã có trong hệ thống không được tạo transfer-in item mới.
2. Domain remote Available không được transfer.
3. Domain remote Unavailable/Found chỉ cho phép đi tiếp, không bảo đảm transfer thành công.
4. Transfer không dùng Suggested Domains, Spotlight Domains hoặc Premium pricing.
5. Cùng một normalized domain chỉ có một register hoặc transfer item trong cart.
6. Thay đổi TLD/EPP/price config sau lookup phải được kiểm tra lại trước Add to Cart.
