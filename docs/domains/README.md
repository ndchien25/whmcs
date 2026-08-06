# Domains Specifications

Tài liệu domain được chia theo nghiệp vụ của dự án, không phụ thuộc cấu trúc menu của WHMCS.

## Configuration

Cấu hình hệ thống trước khi khách đăng ký domain:

1. [Registrar Configuration — eNom](./configuration/registrar-configuration-spec.md)
2. [Lookup Provider Configuration](./configuration/lookup-provider-configuration-spec.md)
3. [TLD Pricing Configuration](./configuration/tld-pricing-spec.md)
4. [Domain Categories Configuration](./configuration/domain-categories-spec.md)

Thứ tự khuyến nghị:

```text
Configure eNom
  -> Configure Lookup Provider
  -> Configure TLD/Pricing
  -> Enable domain registration flow
```

## Registration

- [Domain Registration](./registration/domain-registration-spec.md): Normalize & Validate Input → Check Domain → Configure Domain → Add to Cart.

## Renewals and Transfers

- [Domain Transfer](./renewals-and-transfers/domain-transfer-spec.md): Validate → Check Local System → Check Domain Exists Remotely → Configure Transfer → Add to Cart.
- [Manual Domain Renewal](./renewals-and-transfers/domain-renewal-spec.md): List Managed Domains → Check Eligibility → Select Term → Add to Cart.

## Planned

Chỉ tạo thêm folder/spec khi bắt đầu triển khai nghiệp vụ tương ứng:

```text
domains/
  cart-and-checkout/
  provisioning/
  management/
```
