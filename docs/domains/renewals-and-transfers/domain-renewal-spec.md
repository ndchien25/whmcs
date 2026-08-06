# Manual Domain Renewal Specification

**Version:** 0.1  
**Status:** Draft  
**Operation:** Renew Domain

## 1. References

- [WHMCS 8.0.9 — Domain Renewals](https://docs.whmcs.com/8-0-9/domains/renewals-and-transfers/domain-renewals/)
- [WHMCS 8.0.9 — Set Domain Renewal Restrictions](https://docs.whmcs.com/8-0-9/domains/domain-registration-tutorials/set-domain-renewal-restrictions/)
- [WHMCS 9.0 — Grace and Redemption Periods](https://docs.whmcs.com/9-0/domains/renewals-and-transfers/grace-and-redemption-periods/)
- [eNom — TLD Reference Chart](https://support.enom.com/support/solutions/articles/201000065359-tld-reference-chart)
- [TLD Pricing Configuration](../configuration/tld-pricing-spec.md)

## 2. Purpose

Đặc tả manual/on-demand renewal: client chủ động chọn domain đang được hệ thống quản lý, chọn kỳ hạn renewal và đưa renewal item vào cart.

## 3. Scope

Trong phạm vi:

```text
List Managed Domains
  -> Check Renewal Eligibility
  -> Select Renewal Term
  -> Calculate Current Renewal Price
  -> Add to Cart
```

Ngoài phạm vi:

- Automatic renewal invoice.
- Payment và invoice processing.
- Tự động gọi registrar khi invoice được thanh toán.
- Admin nhấn registrar command **Renew** để gửi lệnh trực tiếp.
- Renewal completion, retry, sync và notification.

## 4. Dependencies

- Admin đã bật **Enable Renewal Orders — Check to show the Domain Renewals cart category allowing clients to place renewal orders early if they wish**.
- Domain đã tồn tại trong hệ thống và thuộc client hiện tại.
- Exact TLD tồn tại trong Domain Pricing.
- TLD có ít nhất một Renewal term đang Enable và price khác `-1.00`.
- Domain có expiry date hợp lệ.
- Domain nằm trong renewal window của exact TLD.

Khi **Enable Renewal Orders** tắt:

- Không hiển thị Domain Renewals cart category.
- Client không thể tạo manual/on-demand renewal order.
- Không ảnh hưởng automatic renewal invoice hoặc admin registrar command **Renew**.

Không dùng Lookup Provider để renew. Availability lookup không quyết định một domain nội bộ có được renewal hay không.

## 5. Domain List

Màn Domain Renewals chỉ hiển thị domain của client có thể xét renewal.

Màn này chỉ khả dụng khi **Enable Renewal Orders** đang bật.

Mỗi row hiển thị:

- Domain name.
- Current expiry date.
- Số ngày còn lại hoặc đã quá hạn.
- Các renewal term hợp lệ.
- Renewal price tương ứng.

Không hiển thị domain của client khác hoặc domain chưa tồn tại trong hệ thống.

## 6. Renewal Eligibility

Một domain chỉ được chọn khi đồng thời thỏa:

1. Domain thuộc client đang đăng nhập.
2. Domain là domain được hệ thống quản lý, không phải cart item chưa hoàn tất.
3. Domain không ở trạng thái Pending, Pending Registration, Pending Transfer, Transferred Away hoặc Cancelled.
4. Exact TLD có Renewal pricing hợp lệ.
5. Ngày hiện tại nằm trong renewal window.
6. Không có renewal item hoặc unpaid renewal invoice trùng cùng domain và cùng kỳ hạn đang chờ xử lý.

Eligibility chỉ cho phép tạo renewal order; registrar vẫn có thể từ chối khi request được gửi sau payment.

## 7. Renewal Restrictions and Expiry Lifecycle

Renewal trước expiry và renewal sau expiry dùng hai nhóm config khác nhau:

| Config | Meaning |
|---|---|
| `renewal_advance_days` | Chỉ cho renewal khi còn không quá số ngày này trước expiry |
| **Domain Grace and Redemption Fees** | Global gate cho phép renewal sau expiry qua Grace và Redemption |
| Grace Period days/fee | Thời lượng và phí Grace theo exact TLD |
| Redemption Period days/fee | Thời lượng và phí Redemption theo exact TLD |

`renewal_advance_days` không quyết định lifecycle sau expiry. Grace và Redemption chỉ có hiệu lực khi global config **Domain Grace and Redemption Fees** đang bật.

### 7.1. Earliest renewal date

```text
earliestRenewalDate = expiryDate - renewalAdvanceDays
```

- Nếu current date trước `earliestRenewalDate`, domain chưa được phép manual renewal.
- Nếu TLD không có `renewal_advance_days`, không áp giới hạn minimum advance riêng; domain có thể renew sớm nếu vẫn thỏa maximum expiry rule.

Ví dụ `.co.uk` có `renewal_advance_days=180`: chỉ cho renewal từ 180 ngày trước expiry.

### 7.2. Lifecycle after expiry

```text
Domain Grace and Redemption Fees = false
  -> domain vừa hết hạn: không hiển thị renewal price, không cho renewal order

Domain Grace and Redemption Fees = true
  -> Grace Period
  -> Redemption Period
  -> hết Redemption: không hiển thị price, không cho renewal order
```

Effective period của exact TLD:

- Days `0`: period đó bị tắt và được bỏ qua.
- Days `-1`: dùng fallback `30` ngày trong phạm vi hiện tại.
- Days lớn hơn `0`: dùng đúng số ngày đã cấu hình.

Khi Auto Registration của TLD là eNom, admin dùng **eNom TLD Reference Chart** để đối chiếu:

- TLD có hỗ trợ explicit/manual renewal hay không.
- Số ngày Grace Period và Redemption Period.
- `N` nghĩa là TLD không có Grace hoặc Redemption tương ứng.
- Grace period được eNom ghi nhận nhưng không được bảo đảm tuyệt đối.

Project không tự đọc bảng này trong runtime. Admin cấu hình effective days/fee trong TLD Pricing theo chính sách eNom hiện hành; hệ thống dùng config đã lưu để hiển thị lifecycle và price. Registrar eNom vẫn là bên xác nhận cuối cùng khi nhận renewal command.

```text
graceEnd = expiryDate + effectiveGraceDays
redemptionEnd = graceEnd + effectiveRedemptionDays
```

- Sau expiry và chưa quá `graceEnd`: trạng thái Grace.
- Sau Grace và chưa quá `redemptionEnd`: trạng thái Redemption.
- Sau `redemptionEnd`: domain hết renewal lifecycle; hiển thị `N/A` và không cho Add to Cart.

### 7.3. Maximum resulting expiry

Sau khi cộng kỳ hạn:

```text
newExpiryDate <= currentDate + 9 years 364 days
```

Term làm expiry vượt giới hạn phải bị ẩn. Renewal 10 Years luôn Disable và bằng `-1.00` theo TLD Pricing spec.

## 8. Renewal Terms

Từ Renewal matrix của exact TLD:

1. Đọc term 1–9 năm theo thứ tự tăng dần.
2. Chỉ lấy term đang Enable.
3. Bỏ term không có price hoặc price `-1.00`.
4. Bỏ term làm new expiry vượt maximum resulting expiry.
5. Hiển thị các term còn lại để client chọn.

Nếu không còn term nào hợp lệ, domain không thể manual renewal tại thời điểm đó.

## 9. Renewal Price

Manual/on-demand renewal dùng **Renewal price hiện tại** trong Domain Pricing tại thời điểm tạo cart item.

```text
renewalSubtotal = currentRenewalPrice(selectedTerm)
```

Rules:

- Không dùng Registration hoặc Transfer price.
- Không dùng recurring amount cũ của domain cho manual renewal.
- Việc thay đổi TLD Renewal price ảnh hưởng manual renewal order mới.
- Giá của renewal item đã tạo không tự thay đổi; server phải xác nhận price hiện hành lại trước khi tạo item.
- Premium classification lúc đăng ký không làm premium override cho renewal trong spec hiện tại; dùng Renewal matrix đã cấu hình.

Automatic renewal invoice dùng recurring amount là nghiệp vụ khác và không thuộc spec này.

## 10. Price by Domain Lifecycle

### 10.1. Before expiry

```text
renewalSubtotal = currentRenewalPrice(selectedTerm)
```

### 10.2. Grace Period

Khi **Domain Grace and Redemption Fees** bật và domain đang trong Grace:

```text
renewalSubtotal = currentRenewalPrice(selectedTerm) + effectiveGraceFee
```

- Grace fee `0` nghĩa là không thu thêm phí.
- Grace fee `-1` hiển thị `N/A` và không cho renewal trong Grace.

### 10.3. Redemption Period

Khi **Domain Grace and Redemption Fees** bật và domain đang trong Redemption:

```text
renewalSubtotal = currentRenewalPrice(selectedTerm) + effectiveRedemptionFee
```

- Redemption fee `0` nghĩa là không thu thêm phí.
- Redemption fee `-1` hiển thị `N/A` và không cho renewal trong Redemption.

### 10.4. No renewal price

Không hiển thị renewal price và không cho tạo renewal order khi:

- Domain đã hết hạn và **Domain Grace and Redemption Fees** đang tắt.
- Domain đã đi qua cả effective Grace Period và Redemption Period.
- Period hiện tại bị tắt hoặc không có fee hợp lệ để bán.

## 11. Add to Cart

Khi client chọn term và nhấn **Add to Cart**:

1. Xác nhận **Enable Renewal Orders** vẫn đang bật.
2. Load lại domain record từ hệ thống.
3. Xác nhận ownership và status.
4. Tính lại renewal window theo current date và expiry date hiện tại.
5. Xác nhận selected term vẫn Enable và không làm expiry vượt giới hạn.
6. Xác định lifecycle hiện tại rồi load Renewal price và Grace/Redemption fee tương ứng.
7. Kiểm tra không có renewal cart item hoặc unpaid renewal invoice trùng.
8. Tạo domain cart item với operation `renew`.

Renewal cart item lưu:

- Domain record ID.
- Unicode và ASCII/punycode domain.
- Exact TLD.
- Operation `renew`.
- Current expiry date dùng để tính.
- Selected renewal term.
- Renewal price snapshot.
- Grace fee snapshot nếu áp dụng.
- Redemption fee snapshot nếu áp dụng.
- Expected new expiry date.

Không gọi registrar tại bước Add to Cart.

## 12. Manual Admin Registrar Renewal

Admin manual renewal là flow riêng:

```text
Client Profile -> Domains -> Registrar Commands -> Renew
```

Flow này gửi renew command trực tiếp đến registrar cho domain được chọn và không phải client on-demand cart flow. Cần quyền admin và confirmation riêng. Chi tiết API eNom, cập nhật expiry và xử lý lỗi sẽ được đặc tả trong provisioning/registrar-action phase.

## 13. Rules

1. Chỉ domain đã được hệ thống quản lý mới có thể renew.
2. Client manual renewal chỉ hoạt động khi **Enable Renewal Orders** bật.
3. Manual renewal không gọi Lookup Provider.
4. Chỉ dùng Renewal price hiện tại của exact TLD.
5. Không cho tạo renewal trùng khi đã có cart item hoặc unpaid renewal invoice đang chờ.
6. Renewal sau expiry chỉ hoạt động khi **Domain Grace and Redemption Fees** bật.
7. Domain đi theo Grace → Redemption → không còn price sau khi hết Redemption.
8. Add to Cart không thay đổi expiry date và không gửi registrar command.
