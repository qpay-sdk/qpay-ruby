# frozen_string_literal: true

RSpec.describe QPay::Client do
  let(:config) { build_test_config }
  let(:client) { QPay::Client.new(config: config) }
  let(:base_url) { "https://merchant.qpay.mn" }

  before { stub_auth_token }

  # ---------------------------------------------------------------------------
  # Auth
  # ---------------------------------------------------------------------------
  describe "#get_token" do
    it "returns a TokenResponse with access and refresh tokens" do
      token = client.get_token

      expect(token).to be_a(QPay::TokenResponse)
      expect(token.access_token).to eq("test-access-token")
      expect(token.refresh_token).to eq("test-refresh-token")
      expect(token.token_type).to eq("Bearer")
    end

    it "raises QPay::Error on authentication failure" do
      stub_request(:post, "#{base_url}/v2/auth/token")
        .to_return(
          status: 401,
          body: { "error" => "AUTHENTICATION_FAILED", "message" => "Bad credentials" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get_token }.to raise_error(QPay::Error) do |e|
        expect(e.status_code).to eq(401)
        expect(e.code).to eq("AUTHENTICATION_FAILED")
      end
    end
  end

  describe "#refresh_token" do
    it "refreshes the token using the refresh token" do
      # First get a token so the client has a refresh token
      client.get_token

      stub_request(:post, "#{base_url}/v2/auth/refresh")
        .to_return(
          status: 200,
          body: {
            "token_type" => "Bearer",
            "access_token" => "new-access-token",
            "refresh_token" => "new-refresh-token",
            "expires_in" => (Time.now.to_i + 7200),
            "refresh_expires_in" => 3_600_000
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      token = client.refresh_token

      expect(token).to be_a(QPay::TokenResponse)
      expect(token.access_token).to eq("new-access-token")
      expect(token.refresh_token).to eq("new-refresh-token")
    end

    it "raises QPay::Error when refresh fails" do
      client.get_token

      stub_request(:post, "#{base_url}/v2/auth/refresh")
        .to_return(
          status: 401,
          body: { "error" => "AUTHENTICATION_FAILED", "message" => "Token expired" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.refresh_token }.to raise_error(QPay::Error)
    end
  end

  # ---------------------------------------------------------------------------
  # Invoices
  # ---------------------------------------------------------------------------
  describe "#create_invoice" do
    let(:invoice_response_body) do
      {
        "invoice_id" => "inv_123",
        "qr_text" => "qpay_qr_data",
        "qr_image" => "base64_image_data",
        "qPay_shortUrl" => "https://qpay.mn/s/abc",
        "urls" => [
          {
            "name" => "Khan Bank",
            "description" => "Pay with Khan Bank",
            "logo" => "https://logo.url/khan.png",
            "link" => "khanbank://pay?id=123"
          },
          {
            "name" => "TDB",
            "description" => "Pay with TDB",
            "logo" => "https://logo.url/tdb.png",
            "link" => "tdb://pay?id=123"
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, "#{base_url}/v2/invoice")
        .to_return(
          status: 200,
          body: invoice_response_body,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a full invoice and returns InvoiceResponse" do
      request = QPay::CreateInvoiceRequest.new(
        invoice_code: "INV001",
        sender_invoice_no: "SND001",
        invoice_description: "Full invoice test",
        amount: 10_000,
        callback_url: "https://example.com/cb"
      )

      response = client.create_invoice(request)

      expect(response).to be_a(QPay::InvoiceResponse)
      expect(response.invoice_id).to eq("inv_123")
      expect(response.qr_text).to eq("qpay_qr_data")
      expect(response.qpay_short_url).to eq("https://qpay.mn/s/abc")
      expect(response.urls.length).to eq(2)
      expect(response.urls.first.name).to eq("Khan Bank")
      expect(response.urls.last.name).to eq("TDB")
    end
  end

  describe "#create_simple_invoice" do
    before do
      stub_request(:post, "#{base_url}/v2/invoice")
        .to_return(
          status: 200,
          body: {
            "invoice_id" => "inv_456",
            "qr_text" => "simple_qr",
            "qr_image" => "simple_img",
            "qPay_shortUrl" => "https://qpay.mn/s/def",
            "urls" => []
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates a simple invoice and returns InvoiceResponse" do
      request = QPay::CreateSimpleInvoiceRequest.new(
        invoice_code: "INV001",
        sender_invoice_no: "SND002",
        invoice_description: "Simple invoice",
        amount: 5000,
        callback_url: "https://example.com/cb"
      )

      response = client.create_simple_invoice(request)

      expect(response).to be_a(QPay::InvoiceResponse)
      expect(response.invoice_id).to eq("inv_456")
      expect(response.urls).to eq([])
    end
  end

  describe "#create_ebarimt_invoice" do
    before do
      stub_request(:post, "#{base_url}/v2/invoice")
        .to_return(
          status: 200,
          body: {
            "invoice_id" => "inv_789",
            "qr_text" => "eb_qr",
            "qr_image" => "eb_img",
            "qPay_shortUrl" => "https://qpay.mn/s/ghi",
            "urls" => []
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates an ebarimt invoice and returns InvoiceResponse" do
      request = QPay::CreateEbarimtInvoiceRequest.new(
        invoice_code: "INV001",
        sender_invoice_no: "SND003",
        invoice_description: "Ebarimt invoice",
        tax_type: "1",
        callback_url: "https://example.com/cb",
        lines: [
          QPay::EbarimtInvoiceLine.new(
            tax_product_code: "TAX001",
            line_description: "Product",
            line_quantity: 1,
            line_unit_price: 5000
          )
        ]
      )

      response = client.create_ebarimt_invoice(request)

      expect(response).to be_a(QPay::InvoiceResponse)
      expect(response.invoice_id).to eq("inv_789")
    end
  end

  describe "#cancel_invoice" do
    before do
      stub_request(:delete, "#{base_url}/v2/invoice/inv_123")
        .to_return(status: 200, body: "", headers: {})
    end

    it "cancels an invoice by ID and returns nil" do
      result = client.cancel_invoice("inv_123")
      expect(result).to be_nil
    end

    it "raises QPay::Error when invoice not found" do
      stub_request(:delete, "#{base_url}/v2/invoice/bad_id")
        .to_return(
          status: 404,
          body: { "error" => "INVOICE_NOTFOUND", "message" => "Invoice not found" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.cancel_invoice("bad_id") }.to raise_error(QPay::Error) do |e|
        expect(e.status_code).to eq(404)
        expect(e.code).to eq("INVOICE_NOTFOUND")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Payments
  # ---------------------------------------------------------------------------
  describe "#get_payment" do
    let(:payment_detail_body) do
      {
        "payment_id" => "pay_001",
        "payment_status" => "PAID",
        "payment_fee" => 0,
        "payment_amount" => 10_000,
        "payment_currency" => "MNT",
        "payment_date" => "2024-06-15 10:00:00",
        "payment_wallet" => "qpay",
        "transaction_type" => "P2P",
        "object_type" => "INVOICE",
        "object_id" => "inv_123",
        "card_transactions" => [],
        "p2p_transactions" => [
          {
            "transaction_bank_code" => "050000",
            "account_bank_code" => "050000",
            "account_bank_name" => "Khan Bank",
            "account_number" => "1234567890",
            "status" => "SUCCESS",
            "amount" => 10_000,
            "currency" => "MNT",
            "settlement_status" => "SETTLED"
          }
        ]
      }.to_json
    end

    before do
      stub_request(:get, "#{base_url}/v2/payment/pay_001")
        .to_return(
          status: 200,
          body: payment_detail_body,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns PaymentDetail with nested transactions" do
      detail = client.get_payment("pay_001")

      expect(detail).to be_a(QPay::PaymentDetail)
      expect(detail.payment_id).to eq("pay_001")
      expect(detail.payment_status).to eq("PAID")
      expect(detail.payment_amount).to eq(10_000)
      expect(detail.obj_id).to eq("inv_123")
      expect(detail.p2p_transactions.length).to eq(1)
      expect(detail.p2p_transactions.first.account_bank_name).to eq("Khan Bank")
      expect(detail.card_transactions).to eq([])
    end

    it "raises QPay::Error when payment not found" do
      stub_request(:get, "#{base_url}/v2/payment/bad_id")
        .to_return(
          status: 404,
          body: { "error" => "PAYMENT_NOTFOUND", "message" => "Payment not found" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.get_payment("bad_id") }.to raise_error(QPay::Error) do |e|
        expect(e.code).to eq("PAYMENT_NOTFOUND")
      end
    end
  end

  describe "#check_payment" do
    let(:check_response_body) do
      {
        "count" => 1,
        "paid_amount" => 10_000,
        "rows" => [
          {
            "payment_id" => "pay_001",
            "payment_status" => "PAID",
            "payment_amount" => 10_000,
            "trx_fee" => 0,
            "payment_currency" => "MNT",
            "payment_wallet" => "qpay",
            "payment_type" => "P2P",
            "card_transactions" => [],
            "p2p_transactions" => []
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, "#{base_url}/v2/payment/check")
        .to_return(
          status: 200,
          body: check_response_body,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "checks payment status and returns PaymentCheckResponse" do
      request = QPay::PaymentCheckRequest.new(
        object_type: "INVOICE",
        obj_id: "inv_123",
        offset: QPay::Offset.new(page_number: 1, page_limit: 10)
      )

      response = client.check_payment(request)

      expect(response).to be_a(QPay::PaymentCheckResponse)
      expect(response.count).to eq(1)
      expect(response.paid_amount).to eq(10_000)
      expect(response.rows.length).to eq(1)
      expect(response.rows.first.payment_status).to eq("PAID")
    end
  end

  describe "#list_payments" do
    let(:list_response_body) do
      {
        "count" => 2,
        "rows" => [
          {
            "payment_id" => "pay_001",
            "payment_date" => "2024-06-15",
            "payment_status" => "PAID",
            "payment_fee" => 0,
            "payment_amount" => 10_000,
            "payment_currency" => "MNT",
            "payment_wallet" => "qpay",
            "payment_name" => "Order #1",
            "payment_description" => "Test payment",
            "object_type" => "INVOICE",
            "object_id" => "inv_123"
          },
          {
            "payment_id" => "pay_002",
            "payment_date" => "2024-06-16",
            "payment_status" => "PAID",
            "payment_fee" => 100,
            "payment_amount" => 20_000,
            "payment_currency" => "MNT",
            "payment_wallet" => "qpay",
            "payment_name" => "Order #2",
            "payment_description" => "Another payment",
            "object_type" => "INVOICE",
            "object_id" => "inv_456"
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, "#{base_url}/v2/payment/list")
        .to_return(
          status: 200,
          body: list_response_body,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns a list of payments" do
      request = QPay::PaymentListRequest.new(
        object_type: "INVOICE",
        obj_id: "inv_123",
        start_date: "2024-06-01",
        end_date: "2024-06-30",
        offset: QPay::Offset.new(page_number: 1, page_limit: 20)
      )

      response = client.list_payments(request)

      expect(response).to be_a(QPay::PaymentListResponse)
      expect(response.count).to eq(2)
      expect(response.rows.length).to eq(2)
      expect(response.rows.first.payment_id).to eq("pay_001")
      expect(response.rows.last.payment_amount).to eq(20_000)
    end
  end

  describe "#cancel_payment" do
    before do
      stub_request(:delete, "#{base_url}/v2/payment/cancel/pay_001")
        .to_return(status: 200, body: "", headers: {})
    end

    it "cancels a payment and returns nil" do
      result = client.cancel_payment("pay_001")
      expect(result).to be_nil
    end

    it "cancels a payment with request body" do
      stub_request(:delete, "#{base_url}/v2/payment/cancel/pay_002")
        .to_return(status: 200, body: "", headers: {})

      request = QPay::PaymentCancelRequest.new(
        callback_url: "https://example.com/cb",
        note: "Customer requested cancellation"
      )

      result = client.cancel_payment("pay_002", request: request)
      expect(result).to be_nil
    end

    it "raises QPay::Error when cancellation fails" do
      stub_request(:delete, "#{base_url}/v2/payment/cancel/pay_bad")
        .to_return(
          status: 400,
          body: { "error" => "PAYMENT_ALREADY_CANCELED", "message" => "Already canceled" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.cancel_payment("pay_bad") }.to raise_error(QPay::Error) do |e|
        expect(e.code).to eq("PAYMENT_ALREADY_CANCELED")
      end
    end
  end

  describe "#refund_payment" do
    before do
      stub_request(:delete, "#{base_url}/v2/payment/refund/pay_001")
        .to_return(status: 200, body: "", headers: {})
    end

    it "refunds a payment and returns nil" do
      result = client.refund_payment("pay_001")
      expect(result).to be_nil
    end

    it "refunds a payment with request body" do
      stub_request(:delete, "#{base_url}/v2/payment/refund/pay_003")
        .to_return(status: 200, body: "", headers: {})

      request = QPay::PaymentRefundRequest.new(
        callback_url: "https://example.com/refund-cb",
        note: "Refund requested"
      )

      result = client.refund_payment("pay_003", request: request)
      expect(result).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # Ebarimt
  # ---------------------------------------------------------------------------
  describe "#create_ebarimt" do
    let(:ebarimt_response_body) do
      {
        "id" => "eb_001",
        "ebarimt_by" => "MERCHANT",
        "g_wallet_id" => "wallet_001",
        "ebarimt_receiver_type" => "CITIZEN",
        "ebarimt_receiver" => "AA12345678",
        "amount" => 10_000,
        "vat_amount" => 1000,
        "city_tax_amount" => 0,
        "barimt_status" => "CREATED",
        "barimt_items" => [
          {
            "id" => "item_001",
            "barimt_id" => "eb_001",
            "name" => "Product A",
            "unit_price" => 10_000,
            "quantity" => 1,
            "amount" => 10_000,
            "status" => "ACTIVE"
          }
        ],
        "barimt_transactions" => [],
        "barimt_histories" => [
          {
            "id" => "hist_001",
            "barimt_id" => "eb_001",
            "barimt_status" => "CREATED",
            "ebarimt_receiver_type" => "CITIZEN"
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, "#{base_url}/v2/ebarimt_v3/create")
        .to_return(
          status: 200,
          body: ebarimt_response_body,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "creates an ebarimt and returns EbarimtResponse" do
      request = QPay::CreateEbarimtRequest.new(
        payment_id: "pay_001",
        ebarimt_receiver_type: "CITIZEN",
        ebarimt_receiver: "AA12345678",
        district_code: "001"
      )

      response = client.create_ebarimt(request)

      expect(response).to be_a(QPay::EbarimtResponse)
      expect(response.id).to eq("eb_001")
      expect(response.amount).to eq(10_000)
      expect(response.vat_amount).to eq(1000)
      expect(response.barimt_status).to eq("CREATED")
      expect(response.barimt_items.length).to eq(1)
      expect(response.barimt_items.first.name).to eq("Product A")
      expect(response.barimt_histories.length).to eq(1)
    end
  end

  describe "#cancel_ebarimt" do
    let(:cancel_ebarimt_body) do
      {
        "id" => "eb_001",
        "barimt_status" => "CANCELED",
        "amount" => 10_000,
        "barimt_items" => [],
        "barimt_transactions" => [],
        "barimt_histories" => []
      }.to_json
    end

    before do
      stub_request(:delete, "#{base_url}/v2/ebarimt_v3/pay_001")
        .to_return(
          status: 200,
          body: cancel_ebarimt_body,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "cancels an ebarimt and returns EbarimtResponse" do
      response = client.cancel_ebarimt("pay_001")

      expect(response).to be_a(QPay::EbarimtResponse)
      expect(response.id).to eq("eb_001")
      expect(response.barimt_status).to eq("CANCELED")
    end
  end

  # ---------------------------------------------------------------------------
  # Auto-token management
  # ---------------------------------------------------------------------------
  describe "automatic token management" do
    it "automatically authenticates before making API requests" do
      stub_request(:post, "#{base_url}/v2/invoice")
        .to_return(
          status: 200,
          body: { "invoice_id" => "inv_auto", "qr_text" => "qr", "urls" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      request = QPay::CreateSimpleInvoiceRequest.new(
        invoice_code: "INV001",
        amount: 1000
      )

      response = client.create_simple_invoice(request)
      expect(response.invoice_id).to eq("inv_auto")

      # Verify auth was called
      expect(WebMock).to have_requested(:post, "#{base_url}/v2/auth/token").once
    end

    it "sends the Bearer token in the Authorization header" do
      stub_request(:get, "#{base_url}/v2/payment/pay_test")
        .to_return(
          status: 200,
          body: {
            "payment_id" => "pay_test",
            "payment_status" => "PAID",
            "payment_amount" => 100,
            "card_transactions" => [],
            "p2p_transactions" => []
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client.get_payment("pay_test")

      expect(WebMock).to have_requested(:get, "#{base_url}/v2/payment/pay_test")
        .with(headers: { "Authorization" => "Bearer test-access-token" })
    end
  end

  # ---------------------------------------------------------------------------
  # Error handling
  # ---------------------------------------------------------------------------
  describe "error handling" do
    it "raises QPay::Error with parsed error details on API failure" do
      stub_request(:post, "#{base_url}/v2/invoice")
        .to_return(
          status: 400,
          body: {
            "error" => "INVOICE_LINE_REQUIRED",
            "message" => "Invoice lines are required"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      request = QPay::CreateSimpleInvoiceRequest.new(invoice_code: "INV", amount: 100)

      expect { client.create_simple_invoice(request) }.to raise_error(QPay::Error) do |e|
        expect(e.status_code).to eq(400)
        expect(e.code).to eq("INVOICE_LINE_REQUIRED")
        expect(e.message).to include("Invoice lines are required")
        expect(e.raw_body).to include("INVOICE_LINE_REQUIRED")
      end
    end

    it "handles 500 server errors" do
      stub_request(:post, "#{base_url}/v2/payment/check")
        .to_return(
          status: 500,
          body: { "error" => "", "message" => "Internal error" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      request = QPay::PaymentCheckRequest.new(object_type: "INVOICE", obj_id: "inv_123")

      expect { client.check_payment(request) }.to raise_error(QPay::Error) do |e|
        expect(e.status_code).to eq(500)
      end
    end
  end
end
