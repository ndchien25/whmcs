# Registrar Configuration Specification — eNom

**Version:** 0.1  
**Status:** Draft  
**Supported registrar:** eNom only

## 1. References

- [WHMCS 9.0 — eNom Registrar Module](https://docs.whmcs.com/9-0/domains/domain-registrar-modules/enom/)
- [eNom API — SetCustomerDefinedData](https://api.enom.com/docs/setcustomerdefineddata)

## 2. Prerequisites

- Có eNom reseller account.
- Tạo production API token.
- Whitelist public outbound IP của application server tại eNom Resellers > Manage > API.

`Test Mode` quyết định endpoint eNom được gọi. Production và Reseller Test sử dụng Username và API Token khác nhau. Form chỉ lưu một bộ credential đang được cấu hình, vì vậy khi đổi môi trường admin phải nhập lại cả Username và API Token tương ứng với endpoint được chọn.

## 3. Purpose

Đặc tả cấu hình module eNom, hành vi Activate, Save Changes, xác minh credential, xử lý lỗi và Deactivate.

## 4. Module states

| State | Meaning |
|---|---|
| Inactive | Module chưa được bật local |
| Active | Module đã activate nhưng chưa có cấu hình eNom hợp lệ |
| Configured | Save Changes đã được eNom xác minh thành công và cấu hình đã được lưu |

Chỉ `Configured` được coi là sẵn sàng sử dụng.

## 5. Configuration fields

Module chỉ có đúng năm setting sau:

| DB setting | UI field | Required | Runtime meaning |
|---|---|---|---|
| `Username` | Username | Yes | eNom reseller username; gửi qua `uid` |
| `Password` | API Token | Yes | eNom API token; gửi qua `pw` |
| `TestMode` | Enable Test Mode | No | `true` dùng Reseller Test; `false` dùng production |
| `DisableIRTP` | Disable IRTP | No | `true` ẩn notice xác minh contact trong application |
| `DefaultNameservers` | Use Default Nameservers | No | `true` dùng default nameserver của eNom |

Tên setting và chữ hoa/thường phải giữ nguyên để tương thích WHMCS. UI gọi trường bí mật là **API Token**, nhưng persistence key vẫn là `Password`.

### 5.1. Persistence contract

Tên bảng: `tblregistrars`.

| Column | Rule |
|---|---|
| `id` | Primary key của từng setting row |
| `registrar` | Luôn là `enom` cho module này |
| `setting` | Một trong đúng năm setting được liệt kê ở trên |
| `value` | Toàn bộ giá trị được mã hóa trước khi lưu |

Unique key logic:

```text
registrar + setting
```

Mỗi setting là một row riêng. Không lưu cả config thành một JSON blob.

### 5.2. Encryption rules

- Mã hóa toàn bộ `value`, bao gồm `Username`, `Password` và ba giá trị boolean.
- Không lưu plaintext hoặc hash một chiều vì runtime cần giải mã để gọi eNom.
- Boolean được chuẩn hóa thành giá trị thống nhất trước khi mã hóa, ví dụ `on/off` hoặc `1/0`; implementation phải chọn một format tương thích dữ liệu WHMCS thực tế.
- Không dùng prefix/ciphertext quan sát được như một business rule nếu chưa xác định encryption contract của hệ thống.
- Khi đọc config, giải mã từng row rồi map theo `setting`.
- Khi ghi config, mã hóa từng value rồi upsert theo `registrar=enom` và `setting`.
- API Token không được trả plaintext về form sau khi đã lưu.
- Encryption/decryption failure làm config không khả dụng và không được gọi eNom.

### 5.3. Application constants

`Key`, `EnteredBy`, `Engine`, `ObjectID`, `Type` và `DisplayFlag` trong request `SetCustomerDefinedData` không thuộc năm registrar settings. Chúng là hằng số/metadata do application cung cấp.

## 6. Activate

Khi admin nhấn **Activate**:

1. Chuyển `Inactive` thành `Active`.
2. Hiển thị form cấu hình.
3. Không gọi API eNom.
4. Thông báo rõ module chỉ được bật local và vẫn cần cấu hình.

Activate thành công không có nghĩa credential hợp lệ.

## 7. Save Changes

Save có remote side effect, không phải CRUD local thuần túy.

### 7.1. Flow

1. Validate local fields.
2. Nếu username/token trống, trả field error và không gọi network.
3. Chọn endpoint theo `TestMode`; dùng bộ `Username` và `Password` đang nhập trên form.
4. Gọi `SetCustomerDefinedData` bằng candidate config chưa lưu.
5. Parse business response.
6. Nếu API thành công, mã hóa cả năm value và upsert năm row `tblregistrars` trong một database transaction rồi chuyển `Configured`.
7. Nếu API thất bại, không lưu candidate config và giữ nguyên trạng thái/config trước đó.
8. Ghi audit và API log đã redact.

Khi đổi `TestMode`, `Username` hoặc `Password`, cấu hình mới chỉ có hiệu lực sau khi eNom xác minh thành công.

Nếu form edit để trống API Token nhằm biểu thị “giữ token cũ”, backend phải giải mã `Password` hiện tại để verification. Không gửi token rỗng và không ghi đè token cũ. Nếu chưa có `Password` đã lưu thì API Token là bắt buộc.

### 7.2. Observed request contract

```text
uid={Username}
pw={Password}
command=SetCustomerDefinedData
ObjectID=1
Type=1
Key={integration_key}
Value={installation_identifier_or_empty}
DisplayFlag=0
EnteredBy={entered_by}
Engine={engine_name_and_version}
```

WHMCS 9.0 được quan sát dùng:

```text
Key=WHMCS
EnteredBy=WHMCS
Engine=WHMCS9.0
```

Bản clone phải dùng identifier riêng, ví dụ:

```text
Key={product_key}
EnteredBy={product_name}
Engine={product_name_and_version}
```

Không gửi giá trị `WHMCS` nếu sản phẩm không phải WHMCS.

## 8. Purpose of SetCustomerDefinedData

Command ghi customer-defined metadata vào eNom customer/account. Trong flow Save, dữ liệu đóng vai trò marker cho biết application/integration nào kết nối account; `Key`, `EnteredBy` và `Engine` mô tả nguồn metadata.

Do command yêu cầu authentication và IP permission, nó đồng thời xác minh thực tế username/token, endpoint và whitelist. Tuy nhiên đây là write operation có remote side effect, không phải login-check read-only.

`ObjectID=1`, `Type=1` và `DisplayFlag=0` được coi là integration contract quan sát từ WHMCS. Không tự thay đổi nếu chưa xác minh bằng tài liệu hoặc API test. Nhận định mục đích metadata dựa trên command documentation và request thực tế; cần bổ sung chi tiết nếu eNom cung cấp semantics chính xác hơn.

## 9. Response interpretation

HTTP `200` chỉ biểu thị transport thành công. Business result nằm trong response body.

Response đã quan sát:

```text
ErrCount=1
Err1=Bad User name or Password
ResponseNumber1=304155
ResponseString1=Validation error; invalid ; loginid
Done=true
```

Rules:

- `ErrCount > 0` là thất bại.
- `Done=true` chỉ nghĩa là command đã xử lý xong, không phải thành công.
- `304155` map thành `INVALID_CREDENTIALS` hoặc `INVALID_LOGIN_ID`.
- Response rỗng/unparseable làm Save thất bại.
- HTTP/network failure làm Save thất bại.

Success tối thiểu:

```text
transport_success
AND response_parseable
AND ErrCount = 0
AND không có validation failure
```

## 10. Persistence on Save failure

- Module mới ở trạng thái `Active`: API lỗi thì không lưu config và vẫn giữ `Active`.
- Module đã `Configured`: API lỗi khi chỉnh sửa thì không ghi đè cấu hình cũ và vẫn giữ `Configured` với config cũ.
- Network timeout, response rỗng hoặc response không parse được đều được xem là Save thất bại.
- UI hiển thị lỗi do eNom trả về, ưu tiên `ErrN`; có thể kèm `ResponseNumberN` và `ResponseStringN` để admin xác định nguyên nhân. Save thất bại thì không lưu candidate config.

## 11. Error mapping

| eNom result | Internal category | Admin guidance |
|---|---|---|
| Bad username/password, 304155 | INVALID_CREDENTIALS | Kiểm tra username/token có hợp lệ tại endpoint đang chọn không |
| Invalid Client IP/User not permitted | IP_NOT_WHITELISTED | Whitelist outbound IP tại eNom |
| HTTP timeout/empty response | CONNECTION_UNKNOWN | Kiểm tra mạng rồi Save Changes lại |
| Rate limit | RATE_LIMITED | Retry có backoff |
| Unknown validation error | VALIDATION_ERROR | Hiển thị code/message an toàn và tracking key |

## 12. Deactivate

- Khi admin nhấn **Deactivate**, xóa toàn bộ row có `registrar = enom` khỏi `tblregistrars`.
- Năm setting `Username`, `Password`, `TestMode`, `DisableIRTP` và `DefaultNameservers` đều bị xóa.
- Sau khi xóa, module trở về trạng thái `Inactive` và UI hiển thị nút **Activate**.
- Khi activate lại, admin phải nhập lại toàn bộ cấu hình eNom.
- Deactivate không gọi `SetCustomerDefinedData`; API này chỉ được gọi khi **Save Changes**.
