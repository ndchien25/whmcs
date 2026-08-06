# Domain Pricing Configuration Specification

**Version:** 0.3  
**Status:** Draft  
**Registrar hiện tại:** eNom

## 1. References

- [WHMCS 9.0 — Domain Pricing](https://docs.whmcs.com/9-0/domains/pricing-and-configuration/domain-pricing/)
- [WHMCS 9.0 — Domain Renewals](https://docs.whmcs.com/9-0/domains/renewals-and-transfers/domain-renewals/)
- [WHMCS 9.0 — eNom Registrar Module](https://docs.whmcs.com/9-0/domains/domain-registrar-modules/enom/)
- [WHMCS 8.0.9 — Registrar Pricing Sync](https://docs.whmcs.com/8-0-9/domains/pricing-and-configuration/registrar-pricing-sync/)
- [eNom API — PE_GetDomainPricing](https://api.enom.com/docs/pe_getdomainpricing)
- [ICANN — Renewing Domain Names](https://www.icann.org/resources/pages/renew-domain-name-2018-12-07-en)
- [ICANN — Transfer Policy](https://www.icann.org/en/contracted-parties/accredited-registrars/resources/domain-name-transfers/policy)

## 2. Purpose

Đặc tả màn hình và logic cấu hình Domain Pricing theo WHMCS 9.0. Cấu hình này dùng chung cho registration, transfer và renewal.

## 3. Dependencies

- Module eNom đã được cấu hình theo [Registrar Configuration Spec](./registrar-configuration-spec.md) trước khi chọn eNom cho Auto Registration.
- Hệ thống có hai currency active: `JPY` và `USD`.
- `JPY` là default currency của hệ thống; eNom trả registrar cost mặc định bằng `USD`.

## 4. Domains/TLDs list

Danh sách hiển thị toàn bộ TLD đã cấu hình. Mỗi TLD là một row và có các cấu hình:

- Extension.
- Spotlight.
- Sales Group.
- DNS Management.
- Email Forwarding.
- ID Protection.
- EPP Code.
- Auto Registration registrar.
- Grace Period và fee.
- Redemption Period và fee.
- Pricing matrix.
- Display order.

## 5. Add a New TLD

Admin thêm TLD bằng cách nhập extension tại row cuối danh sách. Người dùng không cần nhập dấu chấm ở đầu; hệ thống tự thêm dấu `.` khi lưu.

Rules:

- Nếu input chưa bắt đầu bằng dấu `.`, hệ thống tự prepend một dấu `.`.
- Ví dụ `com` được lưu thành `.com`; input nhiều nhãn như `t.t.t` được giữ nguyên cấu trúc và thêm dấu chấm đầu thành `.t.t.t`.
- Nếu input đã bắt đầu bằng dấu `.`, không thêm dấu chấm thứ hai ở đầu.
- Chuẩn hóa lowercase.
- Không tạo extension trùng.
- TLD mới chưa bán được cho đến khi có ít nhất một registration price được Enable.
- Các config addon, EPP, registrar và grace/redemption dùng giá trị mặc định cho đến khi admin thay đổi.

## 6. Spotlight TLDs

Spotlight dùng để làm nổi bật TLD trên trang Register Domain.

- Tối đa tám Spotlight TLD.
- Click biểu tượng lightbulb để thêm.
- Click X để bỏ.
- Kéo thả trong khu vực Spotlight để thay đổi thứ tự.
- Một TLD có thể đồng thời là Spotlight và thuộc Sales Group.
- Spotlight TLD chỉ xuất hiện thành card khi có logo tương ứng trong `assets/img/tld_logos/`.
- Không có logo thì không hiển thị Spotlight card, dù TLD vẫn giữ Spotlight config và vẫn xuất hiện trong bảng/category thông thường.

Logo rules:

- Dùng file `.png`, ưu tiên transparent background.
- Tên file lấy từ extension sau khi bỏ toàn bộ dấu chấm.
- `.com -> assets/img/tld_logos/com.png`.
- `.co.uk -> assets/img/tld_logos/couk.png`.
- Thêm logo file không tự bật Spotlight; admin vẫn phải bật lightbulb cho TLD.

Spotlight chỉ ảnh hưởng trình bày, không thay đổi availability hoặc giá.

## 7. Sales Groups

Mỗi TLD có một trong các giá trị:

- `HOT`.
- `NEW`.
- `SALE`.
- `NONE`.

Sales Group hiển thị label cạnh tất cả kết quả thuộc TLD đó. Nó không tự áp dụng discount; giá vẫn lấy từ pricing matrix.

## 8. Pricing Matrix

Admin mở pricing của từng TLD bằng nút **Pricing/Open Pricing**.

### 8.1. Pricing Slab

Menu **Pricing Slab for** cho phép chọn:

- Default pricing.
- Một Client Group cụ thể.

Client Group slab override giá mặc định cho khách thuộc group trên TLD đó.

Nếu custom slab bị **Deactivate Pricing Slab**:

- Order mới của client group dùng regular/default price.
- Domain hiện hữu đã mua với custom price vẫn giữ recurring price hiện tại.
- Không tự cập nhật giá domain hiện hữu.

### 8.2. Year and Enable

Pricing matrix hỗ trợ:

- Term từ 1 đến 10 năm.
- Hai currency `JPY` và `USD`, trong đó JPY là default.
- Checkbox **Enable** cho từng year/currency.

Chỉ tổ hợp year/currency đã Enable mới được dùng để bán. Registration, Transfer, Renewal và addon price được lưu riêng cho JPY và USD.

### 8.3. Price columns

Mỗi term/currency có ba giá độc lập:

| Column | Meaning |
|---|---|
| Registration | Giá đăng ký domain mới |
| Transfer | Giá transfer domain vào |
| Renewal | Giá gia hạn domain |

Không dùng Registration price thay cho Transfer hoặc Renewal price.

### 8.4. Disable a term

- Nhập `-1.00` vào Transfer hoặc Renewal để vô hiệu operation cho term đó.
- Một inter-registrar transfer hoàn tất chỉ gia hạn thêm đúng một năm vào thời hạn đăng ký hiện tại; tổng thời hạn còn lại không được vượt quá 10 năm theo ICANN Transfer Policy.
- Vì transfer không phải operation mua thêm kỳ hạn từ 2–10 năm, hệ thống chỉ cho cấu hình giá `Transfer 1 Year`.
- `Transfer 2–10 Years` mặc định là `-1.00`, luôn bị disable trên UI và không được dùng để tạo transfer order. Rule này áp dụng chung, không chỉ riêng eNom.
- Renewal 10 Years luôn bị WHMCS disable và tự đặt thành `-1.00`.
- Lý do: expiry date sau renewal không được vượt quá 9 năm 364 ngày tính từ ngày hiện tại, nhằm giữ tổng thời hạn đăng ký dưới giới hạn 10 năm.
- Nếu domain ban đầu được đăng ký 10 năm, renewal term tối đa mà WHMCS cho phép là 9 năm. Sau khi registration hoàn tất, WHMCS tự chọn kỳ renewal hợp lệ cao nhất tiếp theo.
- Khi hiển thị renewal term cho một domain cụ thể, ngoài bảng giá còn phải xét expiry date hiện tại; chỉ hiển thị term không làm expiry vượt giới hạn trên.

### 8.5. Save Changes

Khi Save Changes:

1. Validate các price được Enable.
2. Lưu Registration, Transfer và Renewal theo TLD, client-group slab, term và currency (`JPY` hoặc `USD`).
3. Giá mới áp dụng cho registration/transfer order mới.
4. Không tự thay đổi recurring amount của domain hiện hữu.
5. Muốn đổi renewal amount của domain hiện hữu phải dùng quy trình Bulk Pricing Updater riêng.

## 9. Domain Addons

Mỗi TLD có ba tùy chọn:

- DNS Management.
- Email Forwarding.
- ID Protection.

Rules:

- Chỉ bật addon nếu registrar/TLD hỗ trợ.
- Giá addon được cấu hình trong Domain Pricing.
- Giá `0.00` nghĩa là addon miễn phí và hiển thị là Free trong cart.
- Bật addon không làm thay đổi base Registration/Transfer/Renewal price.

## 10. EPP Code

- Bật **EPP Code** để yêu cầu authorization code khi transfer TLD đó.
- Chỉ ảnh hưởng transfer, không yêu cầu EPP khi register domain mới.
- eNom hỗ trợ EPP Code.

## 11. Auto Registration

Mỗi TLD chọn registrar dùng để tự động gửi registration và transfer request. Giai đoạn hiện tại chỉ có lựa chọn eNom hoặc không chọn registrar.

### eNom selected

- Sau khi client thanh toán, hệ thống tự gửi request tới eNom.
- Không gửi registration trước khi nhận payment.
- Module eNom phải đang `Configured`.

### No registrar selected

- Không tự gửi request sau payment.
- Admin phải review và accept order thủ công trước khi gửi registrar action.

Cấu hình nằm theo từng TLD nên các TLD khác nhau có thể chọn registrar khác nhau khi hệ thống hỗ trợ thêm registrar trong tương lai.

## 12. Grace and Redemption Periods

Mỗi TLD có:

- Grace Period length.
- Grace Period fee.
- Redemption Period length.
- Redemption Period fee.

Rules:

- Nhấn biểu tượng gear của TLD để cấu hình.
- Length bằng `0` để tắt period tương ứng.
- Các giá trị chỉ phục vụ renewal sau expiry, không ảnh hưởng registration price.
- Workflow grace/redemption không nằm trong Domain Registration spec.

## 13. Reorder TLDs

- Kéo biểu tượng up/down của row để thay đổi thứ tự.
- Thứ tự được lưu trong `tbldomainpricing.order`.
- Đây là display order dùng chung cho tất cả màn hình, component và API lấy danh sách TLD đã cấu hình, không chỉ riêng màn Domain Pricing.
- Các nơi hiển thị TLD phải giữ cùng thứ tự reorder mà admin nhìn thấy tại Domain Pricing.
- Query lấy danh sách TLD sắp xếp theo `tbldomainpricing.order ASC`, sau đó `tbldomainpricing.id ASC` để có thứ tự ổn định khi nhiều row có cùng giá trị `order`.
- Reorder không thay đổi pricing hoặc domain hiện hữu.

Query order quan sát từ WHMCS:

```sql
SELECT *
FROM tbldomainpricing
ORDER BY tbldomainpricing.order ASC, tbldomainpricing.id ASC;
```

## 14. Delete a TLD

- Click biểu tượng delete và xác nhận để xóa TLD khỏi danh sách cấu hình.
- Hệ thống đọc row `tbldomainpricing` theo `id` để lấy TLD và dữ liệu liên quan.
- Xóa row TLD khỏi `tbldomainpricing`.
- Xóa toàn bộ pricing row có cùng `relid` trong `tblpricing` cho ba type:
  - `domainregister`.
  - `domaintransfer`.
  - `domainrenew`.
- Ghi `tblactivitylog` với nội dung `Domain Pricing TLD Removed: '{extension}'`.
- Đọc config `SpotlightTLDs` trong `tblconfiguration`, loại TLD vừa xóa khỏi danh sách rồi lưu lại. Trong log kiểm thử xóa `.com`, `SpotlightTLDs` được cập nhật thành chuỗi rỗng vì không còn Spotlight TLD nào.
- Hệ thống đọc `tbldomain_lookup_configuration` với `registrar='WhmcsWhois'` và `setting='suggestTlds'`. Log kiểm thử không có câu SQL update/delete tiếp theo cho setting này, nên không kết luận rằng Delete TLD luôn sửa `suggestTlds`.
- Không có câu SQL xóa hoặc cập nhật domain khách hàng hiện hữu trong `tbldomains` ở lần kiểm thử này.
- Sau khi xóa, TLD và pricing của nó không còn dùng được cho order mới.

Chuỗi SQL quan sát được:

```text
SELECT * FROM tbldomainpricing WHERE id = {tld_id} LIMIT 1
DELETE FROM tbldomainpricing WHERE id = {tld_id}
DELETE FROM tblpricing WHERE type = 'domainregister' AND relid = {tld_id}
DELETE FROM tblpricing WHERE type = 'domaintransfer' AND relid = {tld_id}
DELETE FROM tblpricing WHERE type = 'domainrenew' AND relid = {tld_id}
INSERT INTO tblactivitylog (..., "Domain Pricing TLD Removed: '{extension}'", ...)
UPDATE tblconfiguration SET value = {spotlight_without_deleted_tld}
WHERE setting = 'SpotlightTLDs'
```

Các câu delete được log theo thứ tự riêng lẻ; log không cho thấy `START TRANSACTION`/`COMMIT` bao quanh chuỗi thao tác này.

## 15. Lookup Provider

Lookup Provider dùng để kiểm tra availability trong domain checker/cart. Hệ thống hỗ trợ `Standard WHOIS` và `Domain Registrar (eNom)`.

`Standard WHOIS` không hỗ trợ Premium Domains. Khi chuyển sang `Domain Registrar (eNom)`, tùy chọn Premium Domains trở nên khả dụng nhưng admin vẫn phải chủ động bật.

Nếu chuyển Lookup Provider từ eNom về Standard WHOIS, hệ thống tự tắt Premium Domains.

Việc chọn provider, cấu hình TLD lookup và hành vi từng provider được mô tả tại [Lookup Provider Configuration Spec](./lookup-provider-configuration-spec.md).

## 16. Premium Domains

- Chỉ có thể bật khi Lookup Provider là `Domain Registrar (eNom)`; `Standard WHOIS` không hỗ trợ Premium Domains.
- Đổi Lookup Provider từ Standard WHOIS sang eNom không tự bật Premium Domains; nó chỉ cho phép admin bật tính năng này.
- Đổi Lookup Provider từ eNom về Standard WHOIS tự động tắt Premium Domains.
- Nếu eNom lookup xác định một domain là Premium khi config Premium Domains đang tắt, domain đó được coi là `Unavailable` và không được bán.
- Khi bật, eNom trả premium cost price real-time cho domain được lookup.
- Premium cost không lấy từ Registration price trong normal pricing matrix.
- Chỉ bật khi eNom được dùng làm lookup provider và capability premium khả dụng.

### 16.1. Configure Premium Domain Levels

Admin cấu hình các price band trong modal **Configure Premium Domain Levels**. Mỗi band gồm:

| Field | Meaning |
|---|---|
| `Price <` | Cận trên của premium cost dùng cho band |
| `Markup %` | Phần trăm markup áp dụng khi cost nằm trong band |

Band cuối cùng là catch-all `>= {cận trên cuối}` và chỉ cấu hình `Markup %`.

Ví dụ cấu hình:

| Premium cost JPY | Markup |
|---|---:|
| `< 200` | 20% |
| `>= 200` và `< 500` | 25% |
| `>= 500` và `< 1000` | 30% |
| `>= 1000` | 20% |

Rules:

- Các threshold phải là số dương và tăng dần.
- `Markup %` phải là số không âm.
- Không được có khoảng trống hoặc chồng lấn giữa các band.
- Admin có thể thêm threshold mới bằng row **New Price < / New Markup %**.
- Admin có thể xóa threshold; hệ thống tính lại khoảng của các band còn lại.
- Luôn phải có band cuối `>=` để mọi premium cost đều tìm được markup.
- Premium level được hiển thị và cấu hình theo default currency `JPY`. Premium cost USD từ eNom phải được quy đổi sang JPY trước khi chọn band.

### 16.2. Premium selling price

Khi eNom trả premium cost:

1. Xác định band bằng premium cost JPY.
2. Lấy `Markup %` của band đó.
3. Tính giá bán:

```text
premiumSellingPrice = premiumCost + (premiumCost × markupPercent / 100)
```

4. Làm tròn theo precision của JPY trước khi hiển thị và tạo quote.

Ví dụ: cost `400 JPY` thuộc band `>= 200` và `< 500`, markup `25%`, giá bán trước bước làm tròn là `500 JPY`.

Premium quote phải lưu cost, band/markup được áp dụng và selling price. Nếu eNom trả cost mới khi recheck thì phải tính lại từ các band đang có hiệu lực.

Premium selling price override normal Registration price lấy từ pricing matrix cho chính domain premium đó. Override không cập nhật price matrix của TLD và không ảnh hưởng các normal domain khác cùng extension.

Chi tiết flow mua premium domain thuộc Domain Registration spec.

## 17. Bulk Management

Bulk Management cập nhật hàng loạt cho tất cả TLD đã cấu hình trong currency đang được chọn trên form:

- Registration amount từ 1–10 năm.
- Transfer amount từ 1–10 năm.
- Renewal amount từ 1–10 năm.
- Grace Period length/fee.
- Redemption Period length/fee.

Tùy chọn **Set 2-10 years based on 1 year price** tự tính giá năm 2–10 dựa trên giá một năm.

Bulk save chỉ thay đổi cấu hình TLD pricing; không tự cập nhật recurring amount của domain hiện hữu.

## 18. Registrar Pricing Sync

Registrar Pricing Sync lấy danh sách TLD và cost price từ eNom rồi tạo hoặc cập nhật Domain Pricing theo margin do admin cấu hình.

Admin truy cập tại **Utilities > Registrar TLD Sync**. Trong phạm vi dự án, registrar duy nhất được hiển thị là eNom.

### 18.1. Prerequisites

- eNom đang ở trạng thái `Configured`.
- eNom module hỗ trợ TLD Pricing Sync.
- Hệ thống kết nối được đến đúng eNom endpoint theo `TestMode` và credential hiện tại.
- Hệ thống có `JPY` và `USD`; JPY là default currency.
- eNom trả registrar cost mặc định bằng USD.
- Phải có exchange rate USD → JPY hợp lệ trong bảng currency để hiển thị và import giá JPY.

Nếu credential, API hoặc exchange rate không hợp lệ, không cho import các price không thể xác định.

### 18.2. Load registrar pricing

Khi admin chọn eNom:

1. Hệ thống gọi eNom API với command `PE_GetDomainPricing` để lấy domain pricing của reseller account.
2. Hiển thị các sync options.
3. Hiển thị danh sách TLD eNom trả về theo category.
4. Với mỗi TLD, hiển thị selling status, minimum registration period và registrar cost USD cho:
   - Registration.
   - Renewal.
   - Transfer.
   - Redemption nếu eNom cung cấp.
5. Hiển thị thêm exchange rate và registrar cost đã quy đổi sang default currency JPY.
6. Nếu TLD đang được bán, hiển thị thêm selling price hiện tại và margin.
7. Selling price thấp hơn registrar cost sau khi đưa về cùng currency phải được đánh dấu là đang bán lỗ.

Load pricing chỉ để preview; chưa thay đổi Domain Pricing cho đến khi admin thực hiện **Import TLDs**.

API request dùng:

```text
POST {enomEndpoint}/interface.asp
uid={Username}
pw={Password}
command=PE_GetDomainPricing
responsetype=XML
```

Để lấy pricing theo số năm, command hỗ trợ:

- `UseQtyEngine=1`: yêu cầu eNom trả pricing theo multi-year quantity engine.
- `Years`: chỉ nhận các giá trị eNom hỗ trợ là `1`, `2`, `5` hoặc `10`; mặc định là `1`.

Hệ thống có thể gọi command nhiều lần cho các `Years` cần lấy. Không tự gửi giá trị năm ngoài tập eNom hỗ trợ.

Endpoint và credential được lấy từ eNom Registrar Configuration, bao gồm `TestMode`. HTTP 200 không tự động được coi là thành công; nếu eNom trả `ErrCount > 0` thì load pricing thất bại và không được dùng response để import.

Pricing table phải thể hiện rõ conversion thay vì chỉ hiển thị một amount:

| Column | Meaning |
|---|---|
| Registrar Cost (USD) | Cost gốc do eNom trả về |
| USD → JPY Rate | Exchange rate đang được hệ thống sử dụng |
| Converted Cost (JPY) | Cost USD sau khi quy đổi sang default currency |
| Current Selling Price (JPY) | Giá JPY hiện đang lưu trong Domain Pricing nếu TLD đã tồn tại |
| Margin | Margin hiện tại sau khi so sánh cost và selling price trong cùng currency |

```text
registrarCostJPY = registrarCostUSD × usdToJpyRate
```

Conversion column là dữ liệu preview bắt buộc để admin biết giá JPY được tính từ cost USD và tỷ giá nào trước khi import.

### 18.3. Sync options

| Option | Meaning |
|---|---|
| Margin Type | Chọn `Percentage` hoặc `Fixed` |
| Profit Margin | Phần trăm hoặc số tiền cố định theo default currency JPY cộng vào registrar cost |
| Sync Redemption/Grace Fee | Đồng bộ grace/redemption fee và áp cùng margin |
| Automatic Registration | Gán Auto Registration của TLD được import thành eNom |

Dự án không cung cấp option **Round to Next/Round to Nearest**. Sau conversion và margin, hệ thống luôn làm tròn lên.

#### Percentage margin

```text
sellingPriceJPY = registrarCostJPY + (registrarCostJPY × profitMargin / 100)
```

#### Fixed margin

```text
sellingPriceJPY = registrarCostJPY + fixedMarginJPY
```

Registrar Pricing Sync chỉ tính và ghi selling price cho default currency JPY. Sau conversion và margin, luôn làm tròn lên:

```text
sellingPriceJPY = ceil(sellingPriceJPY)
```

Nếu amount đã là số nguyên JPY thì giữ nguyên. Không làm tròn xuống và không có cấu hình chọn đuôi giá như `x.95` hoặc `x.99`.

Margin hiển thị cho một price hiện hữu được tính:

```text
displayMarginPercent = ((currentSellingPrice - registrarCostInSameCurrency) / registrarCostInSameCurrency) × 100
```

### 18.4. Select TLDs

- Admin có thể chọn thủ công từng extension để import.
- **Auto-select TLDs associated with Registrar** chọn các TLD đã tồn tại trong Domain Pricing và đang có Auto Registration là eNom.
- Việc nhóm TLD theo category và đồng bộ selection giữa các category tuân theo [Domain Categories Configuration Spec](./domain-categories-spec.md).
- Chỉ các TLD được chọn mới bị tạo hoặc cập nhật khi Import TLDs.

### 18.5. Import TLDs

Khi admin nhấn **Import TLDs**, xử lý từng TLD được chọn:

1. Chuẩn hóa extension theo rule Add TLD.
2. Nếu extension chưa tồn tại, tạo row TLD mới trong Domain Pricing.
3. Nếu extension đã tồn tại, dùng row hiện hữu.
4. Giữ registrar cost gốc bằng USD và quy đổi sang JPY bằng exchange rate hiện tại.
5. Áp margin rồi luôn làm tròn lên giá JPY theo rule cố định.
6. Chỉ cập nhật Registration, Renewal và Transfer price của default currency `JPY` ở các term/cost eNom hỗ trợ.
7. Không tạo hoặc cập nhật price của currency `USD`; giá USD hiện hữu được giữ nguyên.
8. Giữ `Transfer 2–10 Years = -1.00`; registrar transfer chỉ dùng kỳ hạn một năm.
9. Giữ `Renewal 10 Years = -1.00` theo rule renewal term.
10. Nếu bật **Sync Redemption/Grace Fee**, chỉ cập nhật grace/redemption fee JPY từ eNom sau khi áp margin. Chỉ cập nhật grace fee nếu eNom có trả dữ liệu này.
11. Nếu bật **Automatic Registration**, đặt Auto Registration của TLD thành `enom`.

Nếu một TLD lỗi, hiển thị lỗi riêng cho TLD đó. Không được báo toàn bộ import thành công khi còn TLD xử lý thất bại.

### 18.6. Effect on existing pricing

- Sync cập nhật Domain Pricing dùng cho registration, transfer và renewal order mới.
- Sync không cập nhật recurring amount đã lưu trên domain hiện hữu.
- Renewal invoice của domain hiện hữu tiếp tục dùng recurring amount hiện tại cho đến khi được thay đổi bằng Bulk Pricing Updater hoặc quy trình cập nhật riêng.
- Thao tác **Pricing** trên một TLD trong màn sync mở pricing matrix để admin chỉnh thủ công; việc chỉnh tại đây tuân theo cùng rule trên.
