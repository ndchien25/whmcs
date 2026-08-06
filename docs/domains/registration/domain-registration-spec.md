# Domain Registration Specification

**Version:** 0.2  
**Status:** Draft  
**Operation:** Register Domain

## 1. References

- [WHMCS 9.0 — Selling and Managing Domains](https://docs.whmcs.com/9-0/domains/selling-and-managing-domains/)
- [WHMCS 9.0 — Domain Pricing](https://docs.whmcs.com/9-0/domains/pricing-and-configuration/domain-pricing/)
- [WHMCS 9.0 — Add Spotlight TLD Logos](https://docs.whmcs.com/9-0/domains/domain-registration-tutorials/add-spotlight-tld-logos/)
- [WHMCS 9.0 — Set Domain Length Restrictions](https://docs.whmcs.com/9-0/domains/domain-registration-tutorials/set-domain-length-restrictions/)
- [WHMCS 9.0 — Set Default Nameservers](https://docs.whmcs.com/9-0/domains/domain-registration-tutorials/set-default-nameservers/)
- [WHMCS 9.0 — Custom Domain Fields](https://docs.whmcs.com/9-0/domains/pricing-and-configuration/custom-domain-fields/)
- [WHMCS 9.0 — International Domain Names](https://docs.whmcs.com/9-0/domains/pricing-and-configuration/international-domain-names/)
- [WHMCS 9.0 — eNom Registrar Module](https://docs.whmcs.com/9-0/domains/domain-registrar-modules/enom/)
- [eNom API — Check](https://api.enom.com/docs/check)
- [eNom API — GetNameSuggestions](https://api.enom.com/docs/getnamesuggestions)
- [eNom API — GetIDNCodes](https://api.enom.com/docs/get-idn-codes)
- [eNom API — GetExtAttributes](https://api.enom.com/docs/get-ext-attributes)
- [`resources/domains/dist.additionalfields.php`](../../../resources/domains/dist.additionalfields.php)

## 2. Purpose

Đặc tả luồng khách tìm domain, validate domain, cấu hình domain và đưa domain vào cart.

## 3. Dependencies

- Admin đã bật **Allow clients to register domains with you** trong Domain settings.
- Cấu hình **Allow IDN Domains** quyết định hệ thống có chấp nhận domain chứa IDN hay không.
- TLD và registration term được cấu hình theo [TLD Pricing Spec](../configuration/tld-pricing-spec.md).
- Availability lookup sử dụng provider theo [Lookup Provider Configuration Spec](../configuration/lookup-provider-configuration-spec.md).
- Nếu Lookup Provider là eNom, module eNom phải ở trạng thái `Configured` theo [Registrar Configuration Spec](../configuration/registrar-configuration-spec.md).

## 4. Scope

Trong phạm vi:

```text
Normalize & Validate Input -> Check Domain -> Configure Domain -> Add to Cart
```

Ngoài phạm vi hiện tại:

- Tính cart total, discount và tax.
- Checkout, tạo order và invoice.
- Payment.
- Gửi lệnh register đến eNom.
- Retry, reconciliation, notification và audit sau đăng ký.
- Transfer, renewal và quản lý domain sau đăng ký.

Các nghiệp vụ ngoài phạm vi sẽ được đặc tả sau khi hoàn tất flow đưa domain vào cart.

## 5. Enable Client Domain Registration

Admin có một global setting **Allow clients to register domains with you**.

```text
Enabled
  -> Client Area hiển thị chức năng Register Domain
  -> cho phép vào flow Check Domain

Disabled
  -> ẩn chức năng Register Domain khỏi Client Area
  -> không cho phép client bắt đầu hoặc tiếp tục flow register
```

Rules:

- Đây là global gate của toàn bộ client domain registration flow.
- Có TLD Pricing, Lookup Provider và eNom configuration không tự động bật chức năng này.
- UI phải ẩn link/menu/button Register Domain khi setting tắt.
- Nếu client truy cập trực tiếp Register Domain URL khi setting tắt, server phải từ chối flow thay vì chỉ dựa vào việc ẩn UI.
- Check Domain và Add to Cart cho operation `register` đều phải kiểm tra setting này.
- Nếu setting bị tắt sau khi client đã bắt đầu cấu hình domain, lần server validation tiếp theo phải chặn Add to Cart.

## 6. Register Domain Page

Khi global domain registration đang bật, trang Register Domain hiển thị:

- Form tìm kiếm domain.
- Spotlight TLD cards hợp lệ.
- Category filter.
- Bảng giá các TLD trong Domain Pricing.

### 6.1. Spotlight cards

Danh sách candidate lấy từ các TLD đã bật Spotlight theo Spotlight display order.

Một candidate chỉ được render thành card khi có logo tương ứng trong `assets/img/tld_logos/`:

```text
.com   -> com.png
.co.uk -> couk.png
```

Nếu không có logo, bỏ qua Spotlight card đó. TLD vẫn xuất hiện trong category/bảng giá nếu tồn tại trong Domain Pricing.

Spotlight card hiển thị registration price theo rule chọn giá tại mục 6.3. Không có registration price hợp lệ thì hiển thị `N/A`.

### 6.2. TLD pricing list

Bảng TLD được nhóm/lọc theo [Domain Categories Configuration Spec](../configuration/domain-categories-spec.md) và sắp xếp theo TLD display order.

Mỗi row gồm:

- Extension và Sales Group badge nếu có.
- New Price — Registration.
- Transfer.
- Renewal.
- Grace Period.
- Redemption Period.

TLD vẫn xuất hiện trong list khi một hoặc cả ba operation không có giá hợp lệ; operation đó hiển thị `N/A`.

### 6.3. Display price and term

Giá được chọn riêng cho Registration, Transfer và Renewal theo currency hiện tại của client:

1. Đọc term theo thứ tự tăng dần từ 1 đến 10 năm.
2. Bỏ qua term không Enable cho currency hiện tại.
3. Bỏ qua operation price bằng `-1.00` hoặc không có price.
4. Chọn term hợp lệ đầu tiên và hiển thị cả amount, currency và số năm.
5. Không có term hợp lệ thì hiển thị `N/A`.

Ví dụ:

```text
Registration 1 Year: disabled hoặc -1.00
Registration 2 Years: enabled, 2,000 JPY

=> hiển thị 2,000 JPY / 2 Years
```

Nếu year đang Enable nhưng toàn bộ price của operation đều là `-1.00`, operation vẫn hiển thị `N/A`.

Rule này chỉ chọn giá đại diện để hiển thị trên Register Domain page. Khi Configure Domain, khách vẫn chọn trong toàn bộ registration term hợp lệ.

### 6.4. Grace and Redemption columns

Hai cột hiển thị duration và fee đã cấu hình cho từng TLD:

```text
{duration} Days
({fee} {currency})
```

Rule duration áp dụng riêng cho Grace Period và Redemption Period:

| Configured days | Display |
|---:|---|
| `>= 0` | Hiển thị đúng số ngày đã cấu hình |
| `-1` | Hiển thị default `30 Days` |

Rule fee:

| Configured fee | Display |
|---:|---|
| `> 0` | Hiển thị amount theo currency hiện tại của client |
| `0` | Hiển thị `0` theo currency hiện tại |
| `-1` | Hiển thị `N/A` |

Ví dụ:

```text
graceDays = -1
graceFee = 0
-> 30 Days
   (0 JPY)

redemptionDays = -1
redemptionFee = 15584
-> 30 Days
   (15,584 JPY)
```

Fallback `30 Days` là default của phạm vi spec hiện tại. Việc cấu hình default duration khác sẽ được mô tả trong spec Grace/Redemption riêng sau này.

## 7. Normalize and Validate Input

Normalization và validation là cùng một bước nghiệp vụ trước Check Domain.

Khách được phép nhập một trong hai dạng:

```text
example      // chỉ domain label
example.com  // full domain
```

Trong một lần xử lý input, hệ thống:

1. Trim khoảng trắng ở đầu và cuối.
2. Chuẩn hóa lowercase.
3. Với IDN, giữ Unicode để hiển thị và tạo ASCII/punycode dùng để validate.
4. Xác định normalized input là label-only hay full domain.
5. Validate ngay normalized value theo các rules bên dưới.

Chưa kết hợp label với TLD tại bước này.

### 7.1. Rules

- Input không rỗng.
- Không chứa khoảng trắng ở giữa.
- Label-only là input hợp lệ; không yêu cầu phải có extension.
- Không có label rỗng hoặc hai dấu chấm liên tiếp.
- Mỗi label chỉ chứa ký tự domain/IDN được hỗ trợ.
- Dấu gạch ngang không nằm ở đầu hoặc cuối label.
- Label generic không vượt quá 63 ký tự sau khi chuyển sang ASCII/punycode.

Nếu normalization hoặc validation lỗi thì hiển thị lỗi và không bắt đầu Check Domain. Chỉ normalized value hợp lệ được chuyển sang Check Domain.

### 7.2. IDN validation

Config:

| Config | Type | Meaning |
|---|---|---|
| `allow_idn_domains` | Boolean | Tương ứng **Allow IDN Domains — Check to enable Internationalized Domain Names (IDN) support** |

Validation phải kiểm tra cả SLD và TLD đã normalize:

```text
SLD có IDN hoặc TLD có IDN
  -> allow_idn_domains = true: tiếp tục validation
  -> allow_idn_domains = false: trả Invalid và không gọi Lookup Provider
```

Rules:

- Một domain được coi là IDN nếu SLD hoặc TLD chứa ký tự ngoài ASCII.
- Dạng ASCII/punycode có label bắt đầu bằng `xn--` cũng được coi là IDN; không được dùng punycode để bỏ qua config.
- Với label-only, kiểm tra IDN trên label ngay trong bước Normalize and Validate Input.
- Với full domain, kiểm tra riêng IDN của SLD và exact TLD trong cùng bước validation.
- Với candidate được tạo bằng cách ghép label-only và TLD, kiểm tra lại cả SLD và TLD trước lookup vì TLD được thêm vào có thể là IDN.
- Khi config tắt, domain ASCII thông thường vẫn tiếp tục; chỉ candidate chứa IDN bị loại.
- Khi config bật, domain chưa tự động hợp lệ: vẫn phải qua validation ký tự, script/language được TLD hỗ trợ, độ dài và các rules còn lại.
- Giữ Unicode dạng người dùng nhập để hiển thị; dùng ASCII/punycode tương ứng cho validation kỹ thuật và request đến provider.

### 7.3. Domain length restrictions

Kiểm tra độ dài thuộc bước validation, không thuộc Lookup Provider.

- Với label-only, validate ngay label không rỗng và không vượt quá `63` ký tự.
- Với full domain, xác định exact TLD rồi validate theo giới hạn riêng của TLD ngay trong bước này.
- Khi label-only được kết hợp với từng TLD để tạo candidate, mỗi candidate phải dùng lại quy tắc validation độ dài của exact TLD trước khi được gửi đến Lookup Provider.

Admin có thể custom giới hạn độ dài riêng cho từng extension tương tự WHMCS. Ví dụ:

| Extension | Min | Max |
|---|---:|---:|
| `.asia` | 3 | 63 |
| `.ws` | 4 | 63 |

Project không bắt buộc lưu config giống WHMCS, nhưng model cấu hình phải tương đương:

```text
extension -> min_length, max_length
```

#### Precedence

```text
Custom restriction của exact TLD
  -> fallback: không có minimum tùy chỉnh, maximum 63
```

Rules:

- Label luôn phải có ít nhất một ký tự; đây là validation bắt buộc, không phải `min_length` tùy chỉnh.
- Nếu exact TLD không có custom restriction thì không áp minimum riêng của TLD; chỉ kiểm tra label không rỗng và maximum `63`.
- Input bắt đầu bằng dấu chấm như `.blue` hoặc `.sub.blue` có domain label rỗng nên trả lỗi `The domain name input is empty.`
- Match exact extension; `.uk` không được dùng thay rule của `.co.uk`.
- Chỉ đếm domain label nằm bên trái extension, không tính dấu chấm và extension.
- `example.co.uk` dùng label `example`, độ dài `7`.
- Với IDN, validate độ dài trên ASCII/punycode label sẽ gửi đến lookup provider/registry.
- `min_length` và `max_length` là inclusive.
- `max_length` tùy chỉnh không được lớn hơn giới hạn hệ thống `63`.
- Custom config chỉ có min thì dùng maximum fallback `63`; nếu không có min thì không áp minimum riêng ngoài điều kiện label không rỗng.
- `min_length` không được lớn hơn `max_length`.
- Domain ngắn hơn min trả lỗi `Domain must be at least {min} characters`.
- Domain dài hơn max trả lỗi `Domain must not exceed {max} characters`.
- Lặp lại cùng validation trước Add to Cart.

## 8. Check Domain

Kết quả Check Domain gồm ba phần:

1. **Exact Match** — domain chính xác theo input.
2. **Spotlight Domains** — cùng SLD với các TLD Spotlight.
3. **Suggested Domains** — các tên domain khác do provider hỗ trợ suggestion trả về.

### 8.1. Check domain in local system

Trước khi gọi Lookup Provider, hệ thống kiểm tra normalized full domain đã tồn tại trong dữ liệu domain nội bộ hay chưa.

```text
Đã tồn tại trong hệ thống
  -> coi là Unavailable cho operation Register
  -> không gọi Lookup Provider cho domain đó

Chưa tồn tại trong hệ thống
  -> tiếp tục provider lookup
```

Rules:

- So sánh bằng ASCII/punycode domain đã lowercase để Unicode và punycode không tạo hai record khác nhau.
- Kiểm tra cả domain record đang được quản lý và register/transfer item trùng domain đang có trong cart.
- Local result có ưu tiên cao hơn remote result; provider trả Available cũng không cho đăng ký trùng domain đã có trong hệ thống.
- Áp dụng riêng cho Exact Match, từng Spotlight Domain và từng Suggested Domain.

### 8.2. Exact Match

- Nếu nhập full domain, kiểm tra chính xác full domain đó.
- Nếu nhập label-only, tạo exact domain theo TLD đang được tìm kiếm trên màn hình.
- Không thay đổi SLD khách nhập để tạo Exact Match.
- Hiển thị `Available`, `Unavailable`, `Premium` hoặc lỗi của exact domain.
- Chỉ Exact Match available/premium mới hiển thị giá và **Add to Cart**.

### 8.3. Spotlight Domains

- Lấy SLD của Exact Match và kết hợp với các TLD được đánh dấu Spotlight trong Domain Pricing.
- Mỗi Spotlight TLD tạo thành một full domain riêng và được lookup availability.
- Chỉ hiển thị Spotlight domain có Registration price hợp lệ; kết quả available hiển thị giá và nút **Add**.
- Kết quả được sắp xếp theo display order của TLD Pricing.
- Spotlight chỉ thay extension, không tạo biến thể khác của SLD.

Ví dụ SLD `example`, Spotlight gồm `.com` và `.net`:

```text
example.com
example.net
```

### 8.4. Suggested Domains

- Suggested Domains tách biệt với Exact Match và Spotlight Domains.
- Suggestion có thể thay đổi SLD, TLD hoặc cả hai tùy kết quả provider.
- Danh sách do suggestion provider trả về chưa được coi là available.
- Phải lookup lại từng full domain được gợi ý; chỉ hiển thị suggestion được xác nhận available và có Registration price hợp lệ.
- Nếu provider không trả suggestion hợp lệ, hiển thị `The system could not find any suggestions.`
- Availability của suggestion phải được kiểm tra lại theo thời gian thực khi khách nhấn **Add**.

### 8.5. Standard WHOIS lookup

Với provider `Standard WHOIS`:

1. Giữ nguyên chính xác SLD khách nhập.
2. Tạo full domain cho Exact Match và từng TLD bổ sung/Spotlight cần kiểm tra.
3. Gọi đúng WHOIS registry rule của từng exact TLD trong `dist.whois.json`.
4. Không dùng Standard WHOIS để tự tạo biến thể SLD.

Ví dụ nhập `example` và cần kiểm tra `.com`, `.net`:

```text
WHOIS check example.com
WHOIS check example.net
```

Mỗi domain là một kết quả độc lập. `.com` unavailable không ảnh hưởng kết quả `.net`.

### 8.6. Domain Registrar — eNom lookup

Với provider `Domain Registrar (eNom)`:

1. Gọi eNom `Check` với exact `SLD` và `TLD` cho Exact Match và từng Spotlight domain.
2. `RRPCode=210` là available; `RRPCode=211` là unavailable.
3. Đọc premium classification và price data từ response khi Premium Domains được bật.
4. Gọi `GetNameSuggestions` để lấy danh sách Suggested Domains.
5. Với từng suggestion eNom trả về, tạo full domain từ `Sld` và `Tld`, sau đó gọi `Check` lại để xác nhận availability.
6. Chỉ giữ suggestion có `Check` trả `RRPCode=210`; loại kết quả unavailable, lỗi hoặc không có Registration price hợp lệ.

Mapping cấu hình eNom vào `GetNameSuggestions`:

| Lookup config | API parameter |
|---|---|
| `suggestMaxResultCount` | `MaxResult` |
| `suggestOnlyGeneralAvailability=on` | `AllGA=True` |
| `suggestAdultDomains=on` | `Adult=True` |
| `suggestTlds` | `TldList` |

`GetNameSuggestions` dùng `SearchTerm` là SLD đã normalize. Kết quả `Premium`, `Idn` hoặc `In_GA` từ API suggestion chỉ là metadata; không thay cho validation local và không thay cho kết quả availability từ `Check`.

Nếu `Check` xác định domain là Premium nhưng config **Premium Domains** đang tắt, hệ thống chuẩn hóa kết quả thành `Unavailable`. Không hiển thị premium price và không cho **Add/Add to Cart**.

Nếu một lần gọi eNom lỗi, domain tương ứng trả `Unknown/Error`; không suy diễn thành Available. Exact Match, từng Spotlight domain và Suggested Domains là các kết quả riêng biệt.

### 8.7. Lookup results

Kết quả hỗ trợ:

| Result | Meaning |
|---|---|
| `Available` | Domain có thể tiếp tục sang Configure Domain |
| `Unavailable` | Domain đã được đăng ký hoặc không thể mua |
| `Premium` | Domain available nhưng dùng premium pricing; chỉ có khi eNom lookup và Premium Domains đang bật |
| `Unsupported` | TLD không được provider hỗ trợ |
| `Unknown/Error` | Không xác định được do lookup lỗi |

`Invalid` là kết quả local của input/candidate validation, không phải provider lookup result. Chỉ `Available` hoặc `Premium` được tiếp tục. `Unknown/Error` không được coi là Available.

### 8.8. Display price

Giá hiển thị phụ thuộc kết quả `Check` của từng domain:

```text
Available, không phải Premium
  -> dùng Registration price trong TLD Pricing

Premium
  -> Premium Domains tắt: coi là Unavailable
  -> Premium Domains bật: tính premium selling price từ premium cost eNom và Premium Domain Levels
  -> premium selling price override Registration price trong TLD Pricing
```

Rules:

- Override áp dụng riêng cho exact domain được eNom xác định là Premium, bao gồm Exact Match, Spotlight Domain hoặc Suggested Domain.
- Không ghi đè price matrix của TLD; chỉ thay giá hiển thị và quote của domain premium đó.
- Không hiển thị normal Registration price cạnh premium price như một lựa chọn thay thế.
- Nếu không tính được premium selling price thì không cho **Add/Add to Cart** domain đó.
- Khi khách nhấn **Add**, gọi `Check` lại; nếu premium status hoặc premium cost thay đổi thì tính lại và override bằng giá mới trước khi tiếp tục.

### 8.9. IDN Language

Đây là cấu hình trên màn **Check Domain**, sau khi domain IDN được xác nhận available và trước khi chuyển sang **Configure Domain**.

Nếu domain là IDN và TLD đang cấu hình **Auto Registration = eNom**, hệ thống hiển thị dropdown **Choose IDN Language** cạnh kết quả domain.

Flow:

1. Xác định domain available là IDN từ SLD hoặc TLD Unicode/punycode.
2. Kiểm tra Auto Registration registrar của exact TLD.
3. Nếu registrar là `enom`, gọi eNom `GetIDNCodes` để lấy danh sách language/country code eNom hỗ trợ cho TLD đó.
4. Hiển thị danh sách trả về trong dropdown **Choose IDN Language**.
5. Khách phải chọn một giá trị trước khi nhấn **Add/Add to Cart** để chuyển sang Configure Domain.

Rules:

- Dropdown chỉ hiển thị cho IDN domain có Auto Registration là eNom.
- Lookup Provider có thể là Standard WHOIS hoặc eNom; điều kiện hiển thị dropdown dựa trên Auto Registration registrar của TLD.
- Không tự chọn language/country code thay khách; trạng thái mặc định là **Choose IDN Language**.
- Nếu `GetIDNCodes` lỗi hoặc không trả code phù hợp thì không cho tiếp tục với domain IDN qua eNom.
- Giá trị được chọn phải là code có trong response `GetIDNCodes` gần nhất của exact TLD.
- Lựa chọn được giữ lại khi chuyển sang Configure Domain và được lưu vào domain cart item.
- Domain ASCII không hiển thị dropdown này.

## 9. Configure Domain

Khách cấu hình domain đã chọn:

- Registration term đang Enable.
- DNS Management nếu TLD hỗ trợ và đang bật.
- Email Forwarding nếu TLD hỗ trợ và đang bật.
- ID Protection nếu TLD hỗ trợ và đang bật.
- Nameserver theo policy bên dưới.
- Custom domain fields bắt buộc của TLD nếu có.

Không hiển thị term hoặc addon đã bị disable trong TLD Pricing.

### 9.1. Domain Addons

Màn Configure Domain chỉ hiển thị addon đang được bật trên exact TLD:

| TLD config | Addon hiển thị |
|---|---|
| DNS Management bật | DNS Management |
| ID Protection bật | ID Protection |
| Email Forwarding bật | Email Forwarding |

Rules:

- Addon tắt trên TLD thì không hiển thị và client không thể chọn.
- Addon bật thì hiển thị checkbox, mô tả, giá và registration term tương ứng.
- Giá `0` hiển thị `FREE`; giá lớn hơn `0` lấy từ addon pricing hiện tại.
- Addon là tùy chọn độc lập; chọn addon không thay đổi base Registration price.

### 9.2. Nameservers

Admin cấu hình tối đa 5 **Default Nameservers** trong Domain settings:

```text
default_nameserver_1
default_nameserver_2
default_nameserver_3
default_nameserver_4
default_nameserver_5
```

Khi mở Configure Domain:

1. Điền sẵn các ô Nameserver 1–5 bằng default nameserver tương ứng của admin.
2. Client có thể giữ nguyên hoặc custom lại từng nameserver.
3. Giá trị client xác nhận trên màn hình là nameserver được lưu vào cart item.

Rules:

- Nameserver 1 và Nameserver 2 là bắt buộc; Nameserver 3–5 là tùy chọn.
- Bỏ qua default slot đang để trống.
- Mỗi giá trị không rỗng phải đúng hostname format.
- Không tự ghi đè custom nameserver của client bằng default value khi Continue.
- Validate lại toàn bộ nameserver trước khi thêm domain vào cart.

### 9.3. Custom Domain Fields

Một số TLD yêu cầu thông tin bổ sung khi register. Field chỉ hiển thị khi exact TLD có definition trong [`resources/domains/dist.additionalfields.php`](../../../resources/domains/dist.additionalfields.php).

Flow:

1. Match exact TLD trong file mặc định; TLD nhiều cấp phải match đầy đủ, ví dụ `.co.uk`.
2. Nếu không có definition thì không hiển thị Custom Domain Fields.
3. Nếu có definition, render field theo `Name`, `Type`, `Options`, `Size` và rule required/conditional required trong file.
4. Nếu exact TLD có **Auto Registration = eNom**, gọi `GetExtAttributes` với exact TLD để lấy extended attributes eNom hỗ trợ.
5. Map field value client nhập sang eNom attribute `Name` và `Value` tương ứng để lưu cùng domain configuration.

Rules:

- File mặc định quyết định field nào xuất hiện trên Configure Domain.
- `GetExtAttributes` không tự tạo field cho TLD không có trong file mặc định của dự án.
- `Required=1` là bắt buộc; `Required=0` là tùy chọn; child attribute chỉ bắt buộc theo giá trị field cha mà eNom trả về.
- Với option field, hiển thị `Title` cho client nhưng lưu/gửi `Value` cho eNom.
- Field bắt buộc thiếu hoặc value không thuộc option hợp lệ thì không cho Continue.
- Nếu Auto Registration không phải eNom thì không gọi `GetExtAttributes`; vẫn hiển thị và validate field từ file mặc định.
- Nếu Auto Registration là eNom nhưng `GetExtAttributes` lỗi, không cho tiếp tục với TLD đang cần extended attributes.
- Lưu cả field name nội bộ, giá trị client nhập và eNom attribute mapping để dùng ở bước register sau payment.

## 10. Add to Cart

Khi khách nhấn **Continue/Add to Cart**:

1. Xác nhận global setting **Allow clients to register domains with you** vẫn đang bật.
2. Validate lại domain và toàn bộ cấu hình ở server.
3. Xác nhận kết quả lookup gần nhất vẫn cho phép tiếp tục.
4. Xác nhận TLD và registration term vẫn đang Enable.
5. Xác nhận addon/custom fields/nameserver và IDN language/country code hợp lệ.
6. Tạo một domain cart item với operation `register`.

Domain cart item lưu:

- Unicode domain nếu có.
- ASCII/punycode domain chuẩn hóa.
- TLD.
- Operation `register`.
- Registration term.
- Kết quả normal hoặc premium.
- Addon đã chọn.
- Danh sách nameserver cuối cùng sau khi client giữ nguyên hoặc custom default nameserver.
- Custom domain fields và eNom extended-attribute mapping nếu có.
- IDN language/country code đã chọn nếu domain IDN dùng Auto Registration eNom.

Sau khi thêm thành công, chuyển khách đến cart. Việc tính tổng tiền, discount, tax, checkout, order và invoice không thuộc spec này
