# Domain Categories Configuration Specification

**Version:** 0.1  
**Status:** Draft

## 1. References

- [WHMCS 8.0.9 — Domain Categories](https://docs.whmcs.com/8-0-9/domains/pricing-and-configuration/domain-categories/)
- [`resources/domains/dist.categories.json`](../../../resources/domains/dist.categories.json)
- [TLD Pricing Specification](./tld-pricing-spec.md)

## 2. Purpose

Domain Categories nhóm các TLD trên màn Register Domain để khách dễ lọc và tìm extension, ví dụ `Popular`, `Business` hoặc `Shopping`.

Category chỉ điều khiển cách nhóm/hiển thị. Nó không thay đổi availability, registrar, registration term hoặc price của TLD.

## 3. Configuration Files

Hệ thống đọc hai file:

| File | Purpose |
|---|---|
| `resources/domains/dist.categories.json` | Danh sách category mặc định đi kèm hệ thống |
| `resources/domains/categories.json` | Custom category và thay đổi do dự án quản lý |

Rules:

- Không chỉnh sửa `dist.categories.json`.
- Customization chỉ ghi vào `categories.json`.
- Cả hai file phải là JSON object hợp lệ.
- Không có `categories.json` thì chỉ dùng category mặc định.
- Update hệ thống có thể thay `dist.categories.json` nhưng không được ghi đè `categories.json`.

## 4. JSON Structure

Mỗi property thông thường là tên category; value là array các extension:

```json
{
  "Domains A-F": [
    ".biz",
    ".ca",
    ".com",
    ".co.uk",
    ".de",
    ".eu"
  ]
}
```

Rules:

- Category name không được rỗng.
- Extension phải có dấu chấm đầu và được chuẩn hóa lowercase.
- Hỗ trợ TLD nhiều cấp như `.co.uk`.
- Một TLD có thể thuộc nhiều category.
- TLD trùng trong cùng một category chỉ hiển thị một lần; giữ vị trí xuất hiện đầu tiên.

## 5. Merge Default and Custom Categories

Khi load configuration:

1. Đọc category mặc định từ `dist.categories.json`.
2. Đọc `categories.json` nếu tồn tại.
3. Category mới trong custom file được thêm vào danh sách.
4. Nếu custom file dùng tên category đã tồn tại, các TLD custom được thêm vào category đó.
5. Loại duplicate TLD trong từng category.
6. Áp dụng block `REMOVE` sau cùng.

Ví dụ vừa thêm category vừa xóa TLD khỏi category mặc định:

```json
{
  "Domains A-F": [
    ".biz",
    ".ca",
    ".com",
    ".co.uk",
    ".de",
    ".eu"
  ],
  "REMOVE": {
    "Popular": [
      ".com",
      ".net"
    ]
  }
}
```

`REMOVE` là reserved key và không được hiển thị thành category.

## 6. Remove TLDs from Categories

Block `REMOVE` có cấu trúc:

```json
{
  "REMOVE": {
    "Popular": [
      ".com",
      ".net"
    ]
  }
}
```

Kết quả: `.com` và `.net` không còn xuất hiện trong category `Popular`. Việc remove khỏi một category không xóa TLD khỏi Domain Pricing và không ảnh hưởng các category khác.

## 7. Client Area Display

Trên màn Register Domain:

1. Load danh sách category đã merge.
2. Với mỗi category, lấy phần giao giữa category TLDs và các TLD hiện còn tồn tại trong Domain Pricing.
3. TLD vẫn được tính vào category và hiển thị trong pricing list khi chưa có price hợp lệ; operation tương ứng hiển thị `N/A` theo Domain Registration spec.
4. Category không còn TLD nào tồn tại trong Domain Pricing thì không hiển thị.
5. Chọn category chỉ lọc danh sách TLD; không tự thực hiện lookup và không thêm domain vào cart.

Một TLD thuộc nhiều category được hiển thị trong từng category tương ứng nhưng vẫn tham chiếu cùng một TLD Pricing configuration.

## 8. Category Translation

Category name trong JSON là translation key ổn định.

Khi hiển thị:

1. Tìm bản dịch theo language hiện tại và category key.
2. Có bản dịch thì hiển thị translated label.
3. Không có bản dịch thì hiển thị nguyên category name trong JSON.

Việc đổi translated label không thay đổi category key hoặc TLD membership.

## 9. Interaction with TLD Pricing

- Thêm TLD vào category không tự thêm TLD vào Domain Pricing.
- TLD có trong category file nhưng chưa có trong Domain Pricing bị bỏ qua khi hiển thị.
- Xóa TLD khỏi Domain Pricing không sửa `dist.categories.json` hoặc `categories.json`; TLD tự biến mất khỏi category do bước lấy phần giao.
- Nếu sau đó thêm lại TLD vào Domain Pricing, nó tự xuất hiện lại trong các category đã khai báo.
- Reorder TLD trong Domain Pricing không thay đổi category membership.

## 10. Registrar Pricing Sync

Màn Registrar Pricing Sync có thể dùng Domain Categories để nhóm danh sách TLD eNom trả về.

- Category chỉ phục vụ grouping trên màn sync.
- Một TLD xuất hiện trong nhiều category vẫn là cùng một selection.
- Chọn hoặc bỏ chọn TLD ở một category phải cập nhật selection của cùng extension trong các category khác.
- Category không có TLD trong response của eNom thì không hiển thị.
- Import TLD không tự ghi thay đổi vào category files.

## 11. Invalid Configuration

- Nếu `categories.json` không phải JSON hợp lệ, không áp dụng một phần dữ liệu custom.
- Hệ thống vẫn có thể dùng `dist.categories.json` nếu file mặc định hợp lệ.
- Category value không phải array hoặc extension không phải string bị coi là cấu hình không hợp lệ.
- Lỗi category configuration không được làm thay đổi Domain Pricing.
