# QPay Ruby SDK

[![CI](https://github.com/qpay-sdk/qpay-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/qpay-sdk/qpay-ruby/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/qpay-sdk.svg)](https://rubygems.org/gems/qpay-sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Ruby SDK for the QPay V2 payment gateway API. Provides a simple, idiomatic Ruby interface with automatic token management, typed request/response structs, and comprehensive error handling.

## Installation

Add to your Gemfile:

```ruby
gem "qpay"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install qpay
```

## Quick Start

```ruby
require "qpay"

# Configure from environment variables
config = QPay::Config.from_env

# Or configure manually
config = QPay::Config.new(
  base_url: "https://merchant.qpay.mn",
  username: "YOUR_USERNAME",
  password: "YOUR_PASSWORD",
  invoice_code: "YOUR_INVOICE_CODE",
  callback_url: "https://yoursite.com/payments/callback"
)

# Create a client (handles authentication automatically)
client = QPay::Client.new(config: config)

# Create an invoice
invoice = client.create_simple_invoice(
  QPay::CreateSimpleInvoiceRequest.new(
    invoice_code: config.invoice_code,
    sender_invoice_no: "ORDER-001",
    invoice_receiver_code: "terminal",
    invoice_description: "Payment for Order #001",
    amount: 10_000,
    callback_url: config.callback_url
  )
)

puts invoice.invoice_id      # => "abc123..."
puts invoice.qpay_short_url  # => "https://qpay.mn/s/..."
puts invoice.qr_text         # => QR code data for rendering
```

## Configuration

### Environment Variables

| Variable | Description |
|---|---|
| `QPAY_BASE_URL` | QPay API base URL (e.g., `https://merchant.qpay.mn`) |
| `QPAY_USERNAME` | QPay merchant username |
| `QPAY_PASSWORD` | QPay merchant password |
| `QPAY_INVOICE_CODE` | Default invoice code |
| `QPAY_CALLBACK_URL` | Payment callback URL |

Load from environment:

```ruby
config = QPay::Config.from_env
```

All five environment variables are required. A missing or empty variable raises `ArgumentError` listing the missing variables.

### Manual Configuration

```ruby
config = QPay::Config.new(
  base_url: "https://merchant.qpay.mn",
  username: "YOUR_USERNAME",
  password: "YOUR_PASSWORD",
  invoice_code: "YOUR_INVOICE_CODE",
  callback_url: "https://yoursite.com/callback"
)
```

## Usage

### Authentication

The client manages tokens automatically. You never need to call `get_token` manually -- every API method calls `ensure_token` internally. However, you can manage tokens explicitly if needed:

```ruby
# Get a new token pair
token = client.get_token
puts token.access_token
puts token.refresh_token
puts token.expires_in

# Refresh the current token
token = client.refresh_token
```

### Create Invoice (Full)

Use `CreateInvoiceRequest` for invoices with full options including branch data, line items, and transactions:

```ruby
invoice = client.create_invoice(
  QPay::CreateInvoiceRequest.new(
    invoice_code: "INV_CODE",
    sender_invoice_no: "ORDER-001",
    sender_branch_code: "BRANCH01",
    sender_branch_data: QPay::SenderBranchData.new(
      register: "REG001",
      name: "Main Branch",
      email: "branch@company.mn",
      phone: "77001234",
      address: QPay::Address.new(
        city: "Ulaanbaatar",
        district: "Khan-Uul",
        street: "Peace Avenue 123"
      )
    ),
    sender_staff_data: QPay::SenderStaffData.new(
      name: "John",
      email: "john@company.mn",
      phone: "88001234"
    ),
    invoice_receiver_code: "terminal",
    invoice_receiver_data: QPay::InvoiceReceiverData.new(
      register: "AA12345678",
      name: "Customer Name",
      email: "customer@example.com",
      phone: "99001234"
    ),
    invoice_description: "Order #001 - 2 items",
    amount: 50_000,
    callback_url: "https://yoursite.com/callback",
    lines: [
      QPay::InvoiceLine.new(
        tax_product_code: "TAX001",
        line_description: "Product A",
        line_quantity: 2,
        line_unit_price: 25_000
      )
    ],
    transactions: [
      QPay::Transaction.new(
        description: "Payment for order",
        amount: 50_000,
        accounts: [
          QPay::Account.new(
            account_bank_code: "050000",
            account_number: "1234567890",
            account_name: "Company Account",
            account_currency: "MNT",
            is_default: true
          )
        ]
      )
    ]
  )
)

puts invoice.invoice_id
puts invoice.qr_text
puts invoice.qr_image         # Base64-encoded QR image
puts invoice.qpay_short_url

# Deep links for mobile bank apps
invoice.urls.each do |url|
  puts "#{url.name}: #{url.link}"
end
```

### Create Simple Invoice

For basic invoices with minimal fields:

```ruby
invoice = client.create_simple_invoice(
  QPay::CreateSimpleInvoiceRequest.new(
    invoice_code: "INV_CODE",
    sender_invoice_no: "ORDER-002",
    invoice_receiver_code: "terminal",
    invoice_description: "Quick payment",
    sender_branch_code: "BRANCH01",
    amount: 5_000,
    callback_url: "https://yoursite.com/callback"
  )
)
```

### Create Ebarimt Invoice

For invoices that include tax (ebarimt) information:

```ruby
invoice = client.create_ebarimt_invoice(
  QPay::CreateEbarimtInvoiceRequest.new(
    invoice_code: "INV_CODE",
    sender_invoice_no: "ORDER-003",
    sender_branch_code: "BRANCH01",
    invoice_receiver_code: "terminal",
    invoice_description: "Tax invoice",
    tax_type: "1",
    district_code: "001",
    callback_url: "https://yoursite.com/callback",
    lines: [
      QPay::EbarimtInvoiceLine.new(
        tax_product_code: "TAX001",
        line_description: "Taxable product",
        line_quantity: 1,
        line_unit_price: 10_000,
        classification_code: "CLS001"
      )
    ]
  )
)
```

### Cancel Invoice

```ruby
client.cancel_invoice("INVOICE_ID")
```

### Get Payment Details

```ruby
payment = client.get_payment("PAYMENT_ID")

puts payment.payment_id
puts payment.payment_status    # => "PAID"
puts payment.payment_amount    # => 10000
puts payment.payment_currency  # => "MNT"
puts payment.payment_wallet
puts payment.payment_date
puts payment.transaction_type
puts payment.object_type
puts payment.obj_id

# Card transactions
payment.card_transactions.each do |ct|
  puts "Card: #{ct.card_number} - #{ct.amount} #{ct.currency}"
end

# P2P transactions
payment.p2p_transactions.each do |pt|
  puts "Bank: #{pt.account_bank_name} - #{pt.amount} #{pt.currency}"
end
```

### Check Payment

Check if a payment has been made for an invoice:

```ruby
result = client.check_payment(
  QPay::PaymentCheckRequest.new(
    object_type: "INVOICE",
    obj_id: "INVOICE_ID",
    offset: QPay::Offset.new(page_number: 1, page_limit: 10)
  )
)

puts result.count        # Number of payments
puts result.paid_amount  # Total paid amount

result.rows.each do |row|
  puts "#{row.payment_id}: #{row.payment_status} - #{row.payment_amount}"
end
```

### List Payments

```ruby
payments = client.list_payments(
  QPay::PaymentListRequest.new(
    object_type: "INVOICE",
    obj_id: "INVOICE_ID",
    start_date: "2024-01-01",
    end_date: "2024-12-31",
    offset: QPay::Offset.new(page_number: 1, page_limit: 20)
  )
)

puts payments.count

payments.rows.each do |item|
  puts "#{item.payment_id}: #{item.payment_amount} #{item.payment_currency} (#{item.payment_status})"
end
```

### Cancel Payment

Cancel a card payment:

```ruby
# Without request body
client.cancel_payment("PAYMENT_ID")

# With callback and note
client.cancel_payment("PAYMENT_ID", request: QPay::PaymentCancelRequest.new(
  callback_url: "https://yoursite.com/cancel-callback",
  note: "Customer requested cancellation"
))
```

### Refund Payment

Refund a card payment:

```ruby
# Without request body
client.refund_payment("PAYMENT_ID")

# With callback and note
client.refund_payment("PAYMENT_ID", request: QPay::PaymentRefundRequest.new(
  callback_url: "https://yoursite.com/refund-callback",
  note: "Refund for defective product"
))
```

### Create Ebarimt (Tax Receipt)

Create an electronic tax receipt for a completed payment:

```ruby
ebarimt = client.create_ebarimt(
  QPay::CreateEbarimtRequest.new(
    payment_id: "PAYMENT_ID",
    ebarimt_receiver_type: "CITIZEN",
    ebarimt_receiver: "AA12345678",
    district_code: "001",
    classification_code: "CLS001"
  )
)

puts ebarimt.id
puts ebarimt.amount
puts ebarimt.vat_amount
puts ebarimt.barimt_status
puts ebarimt.ebarimt_qr_data
puts ebarimt.ebarimt_lottery

ebarimt.barimt_items.each do |item|
  puts "#{item.name}: #{item.amount}"
end
```

### Cancel Ebarimt

```ruby
ebarimt = client.cancel_ebarimt("PAYMENT_ID")

puts ebarimt.barimt_status  # => "CANCELED"
```

## Error Handling

All API errors raise `QPay::Error`, which is a subclass of `StandardError`:

```ruby
begin
  client.create_simple_invoice(request)
rescue QPay::Error => e
  puts e.message      # => "qpay: INVOICE_LINE_REQUIRED - Invoice lines are required (status 400)"
  puts e.status_code  # => 400
  puts e.code         # => "INVOICE_LINE_REQUIRED"
  puts e.raw_body     # => Raw JSON response body
end
```

### Checking Error Type

Use the `QPay.qpay_error?` helper to distinguish QPay errors from other exceptions:

```ruby
begin
  client.get_payment("some_id")
rescue => e
  qpay_err, is_qpay = QPay.qpay_error?(e)
  if is_qpay
    puts "QPay error: #{qpay_err.code}"
  else
    puts "Other error: #{e.message}"
  end
end
```

### Error Code Constants

The SDK defines all QPay error codes as constants for easy comparison:

```ruby
rescue QPay::Error => e
  case e.code
  when QPay::AUTHENTICATION_FAILED
    # Re-authenticate
  when QPay::INVOICE_NOTFOUND
    # Handle missing invoice
  when QPay::INVOICE_PAID
    # Invoice already paid
  when QPay::PAYMENT_NOTFOUND
    # Handle missing payment
  when QPay::PAYMENT_ALREADY_CANCELED
    # Payment was already canceled
  when QPay::INVALID_AMOUNT
    # Amount out of range
  when QPay::PERMISSION_DENIED
    # Access denied
  when QPay::EBARIMT_NOT_REGISTERED
    # Ebarimt not registered
  end
end
```

Full list of error constants:

| Constant | Value |
|---|---|
| `QPay::ACCOUNT_BANK_DUPLICATED` | `"ACCOUNT_BANK_DUPLICATED"` |
| `QPay::ACCOUNT_SELECTION_INVALID` | `"ACCOUNT_SELECTION_INVALID"` |
| `QPay::AUTHENTICATION_FAILED` | `"AUTHENTICATION_FAILED"` |
| `QPay::BANK_ACCOUNT_NOTFOUND` | `"BANK_ACCOUNT_NOTFOUND"` |
| `QPay::BANK_MCC_ALREADY_ADDED` | `"BANK_MCC_ALREADY_ADDED"` |
| `QPay::BANK_MCC_NOT_FOUND` | `"BANK_MCC_NOT_FOUND"` |
| `QPay::CARD_TERMINAL_NOTFOUND` | `"CARD_TERMINAL_NOTFOUND"` |
| `QPay::CLIENT_NOTFOUND` | `"CLIENT_NOTFOUND"` |
| `QPay::CLIENT_USERNAME_DUPLICATED` | `"CLIENT_USERNAME_DUPLICATED"` |
| `QPay::CUSTOMER_DUPLICATE` | `"CUSTOMER_DUPLICATE"` |
| `QPay::CUSTOMER_NOTFOUND` | `"CUSTOMER_NOTFOUND"` |
| `QPay::CUSTOMER_REGISTER_INVALID` | `"CUSTOMER_REGISTER_INVALID"` |
| `QPay::EBARIMT_CANCEL_NOTSUPPERDED` | `"EBARIMT_CANCEL_NOTSUPPERDED"` |
| `QPay::EBARIMT_NOT_REGISTERED` | `"EBARIMT_NOT_REGISTERED"` |
| `QPay::EBARIMT_QR_CODE_INVALID` | `"EBARIMT_QR_CODE_INVALID"` |
| `QPay::INFORM_NOTFOUND` | `"INFORM_NOTFOUND"` |
| `QPay::INPUT_CODE_REGISTERED` | `"INPUT_CODE_REGISTERED"` |
| `QPay::INPUT_NOTFOUND` | `"INPUT_NOTFOUND"` |
| `QPay::INVALID_AMOUNT` | `"INVALID_AMOUNT"` |
| `QPay::INVALID_OBJECT_TYPE` | `"INVALID_OBJECT_TYPE"` |
| `QPay::INVOICE_ALREADY_CANCELED` | `"INVOICE_ALREADY_CANCELED"` |
| `QPay::INVOICE_CODE_INVALID` | `"INVOICE_CODE_INVALID"` |
| `QPay::INVOICE_CODE_REGISTERED` | `"INVOICE_CODE_REGISTERED"` |
| `QPay::INVOICE_LINE_REQUIRED` | `"INVOICE_LINE_REQUIRED"` |
| `QPay::INVOICE_NOTFOUND` | `"INVOICE_NOTFOUND"` |
| `QPay::INVOICE_PAID` | `"INVOICE_PAID"` |
| `QPay::INVOICE_RECEIVER_DATA_ADDRESS_REQUIRED` | `"INVOICE_RECEIVER_DATA_ADDRESS_REQUIRED"` |
| `QPay::INVOICE_RECEIVER_DATA_EMAIL_REQUIRED` | `"INVOICE_RECEIVER_DATA_EMAIL_REQUIRED"` |
| `QPay::INVOICE_RECEIVER_DATA_PHONE_REQUIRED` | `"INVOICE_RECEIVER_DATA_PHONE_REQUIRED"` |
| `QPay::INVOICE_RECEIVER_DATA_REQUIRED` | `"INVOICE_RECEIVER_DATA_REQUIRED"` |
| `QPay::MAX_AMOUNT_ERR` | `"MAX_AMOUNT_ERR"` |
| `QPay::MCC_NOTFOUND` | `"MCC_NOTFOUND"` |
| `QPay::MERCHANT_ALREADY_REGISTERED` | `"MERCHANT_ALREADY_REGISTERED"` |
| `QPay::MERCHANT_INACTIVE` | `"MERCHANT_INACTIVE"` |
| `QPay::MERCHANT_NOTFOUND` | `"MERCHANT_NOTFOUND"` |
| `QPay::MIN_AMOUNT_ERR` | `"MIN_AMOUNT_ERR"` |
| `QPay::NO_CREDENDIALS` | `"NO_CREDENDIALS"` |
| `QPay::OBJECT_DATA_ERROR` | `"OBJECT_DATA_ERROR"` |
| `QPay::P2P_TERMINAL_NOTFOUND` | `"P2P_TERMINAL_NOTFOUND"` |
| `QPay::PAYMENT_ALREADY_CANCELED` | `"PAYMENT_ALREADY_CANCELED"` |
| `QPay::PAYMENT_NOT_PAID` | `"PAYMENT_NOT_PAID"` |
| `QPay::PAYMENT_NOTFOUND` | `"PAYMENT_NOTFOUND"` |
| `QPay::PERMISSION_DENIED` | `"PERMISSION_DENIED"` |
| `QPay::QRACCOUNT_INACTIVE` | `"QRACCOUNT_INACTIVE"` |
| `QPay::QRACCOUNT_NOTFOUND` | `"QRACCOUNT_NOTFOUND"` |
| `QPay::QRCODE_NOTFOUND` | `"QRCODE_NOTFOUND"` |
| `QPay::QRCODE_USED` | `"QRCODE_USED"` |
| `QPay::SENDER_BRANCH_DATA_REQUIRED` | `"SENDER_BRANCH_DATA_REQUIRED"` |
| `QPay::TAX_LINE_REQUIRED` | `"TAX_LINE_REQUIRED"` |
| `QPay::TAX_PRODUCT_CODE_REQUIRED` | `"TAX_PRODUCT_CODE_REQUIRED"` |
| `QPay::TRANSACTION_NOT_APPROVED` | `"TRANSACTION_NOT_APPROVED"` |
| `QPay::TRANSACTION_REQUIRED` | `"TRANSACTION_REQUIRED"` |

## API Reference

### Client Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `get_token` | -- | `TokenResponse` | Authenticate and get token pair |
| `refresh_token` | -- | `TokenResponse` | Refresh access token |
| `create_invoice` | `CreateInvoiceRequest` | `InvoiceResponse` | Create full invoice |
| `create_simple_invoice` | `CreateSimpleInvoiceRequest` | `InvoiceResponse` | Create simple invoice |
| `create_ebarimt_invoice` | `CreateEbarimtInvoiceRequest` | `InvoiceResponse` | Create invoice with tax info |
| `cancel_invoice` | `invoice_id` (String) | `nil` | Cancel an invoice |
| `get_payment` | `payment_id` (String) | `PaymentDetail` | Get payment details |
| `check_payment` | `PaymentCheckRequest` | `PaymentCheckResponse` | Check payment status |
| `list_payments` | `PaymentListRequest` | `PaymentListResponse` | List payments |
| `cancel_payment` | `payment_id`, `request:` (optional) | `nil` | Cancel a payment |
| `refund_payment` | `payment_id`, `request:` (optional) | `nil` | Refund a payment |
| `create_ebarimt` | `CreateEbarimtRequest` | `EbarimtResponse` | Create tax receipt |
| `cancel_ebarimt` | `payment_id` (String) | `EbarimtResponse` | Cancel tax receipt |

### Request/Response Structs

All structs use `keyword_init: true` and can be created with named parameters:

**Auth:** `TokenResponse`

**Invoice:** `CreateInvoiceRequest`, `CreateSimpleInvoiceRequest`, `CreateEbarimtInvoiceRequest`, `InvoiceResponse`

**Payment:** `PaymentCheckRequest`, `PaymentCheckResponse`, `PaymentCheckRow`, `PaymentDetail`, `PaymentListRequest`, `PaymentListResponse`, `PaymentListItem`, `PaymentCancelRequest`, `PaymentRefundRequest`

**Ebarimt:** `CreateEbarimtRequest`, `EbarimtResponse`, `EbarimtItem`, `EbarimtHistory`

**Shared:** `Address`, `SenderBranchData`, `SenderStaffData`, `InvoiceReceiverData`, `Account`, `Transaction`, `InvoiceLine`, `EbarimtInvoiceLine`, `TaxEntry`, `Deeplink`, `Offset`

## Requirements

- Ruby >= 3.0.0
- [Faraday](https://github.com/lostisland/faraday) ~> 2.0

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake spec

# Run tests (alternative)
bundle exec rspec
```

## License

MIT License. See [LICENSE](LICENSE) for details.
