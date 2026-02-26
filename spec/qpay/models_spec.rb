# frozen_string_literal: true

RSpec.describe "QPay Models" do
  describe QPay::TokenResponse do
    it "creates with keyword arguments" do
      token = QPay::TokenResponse.new(
        token_type: "Bearer",
        access_token: "abc",
        refresh_token: "def",
        expires_in: 3600,
        refresh_expires_in: 1_800_000,
        scope: "default",
        not_before_policy: 0,
        session_state: "xyz"
      )

      expect(token.token_type).to eq("Bearer")
      expect(token.access_token).to eq("abc")
      expect(token.refresh_token).to eq("def")
      expect(token.expires_in).to eq(3600)
      expect(token.refresh_expires_in).to eq(1_800_000)
    end

    it "serializes to hash" do
      token = QPay::TokenResponse.new(
        token_type: "Bearer",
        access_token: "abc",
        refresh_token: "def",
        expires_in: 3600,
        refresh_expires_in: 1_800_000
      )

      hash = token.to_h
      expect(hash[:token_type]).to eq("Bearer")
      expect(hash[:access_token]).to eq("abc")
    end

    it "serializes to JSON via to_h" do
      token = QPay::TokenResponse.new(access_token: "abc", token_type: "Bearer")
      json = token.to_h.compact.to_json
      parsed = JSON.parse(json)

      expect(parsed["access_token"]).to eq("abc")
      expect(parsed["token_type"]).to eq("Bearer")
    end
  end

  describe QPay::CreateSimpleInvoiceRequest do
    it "creates with keyword arguments" do
      req = QPay::CreateSimpleInvoiceRequest.new(
        invoice_code: "INV001",
        sender_invoice_no: "SND001",
        invoice_receiver_code: "RCV001",
        invoice_description: "Test invoice",
        amount: 1000,
        callback_url: "https://example.com/cb"
      )

      expect(req.invoice_code).to eq("INV001")
      expect(req.amount).to eq(1000)
      expect(req.callback_url).to eq("https://example.com/cb")
    end

    it "supports compact for omitting nil fields" do
      req = QPay::CreateSimpleInvoiceRequest.new(
        invoice_code: "INV001",
        amount: 1000
      )

      compacted = req.to_h.compact
      expect(compacted).not_to have_key(:sender_invoice_no)
      expect(compacted[:invoice_code]).to eq("INV001")
    end
  end

  describe QPay::CreateInvoiceRequest do
    it "creates with nested structs" do
      req = QPay::CreateInvoiceRequest.new(
        invoice_code: "INV001",
        sender_invoice_no: "SND001",
        amount: 5000,
        callback_url: "https://example.com/cb",
        sender_branch_data: QPay::SenderBranchData.new(
          register: "REG001",
          name: "Branch A",
          email: "branch@example.com"
        ),
        lines: [
          QPay::InvoiceLine.new(
            tax_product_code: "TAX001",
            line_description: "Product A",
            line_quantity: 2,
            line_unit_price: 2500
          )
        ]
      )

      expect(req.sender_branch_data.name).to eq("Branch A")
      expect(req.lines.length).to eq(1)
      expect(req.lines.first.line_quantity).to eq(2)
    end
  end

  describe QPay::InvoiceResponse do
    it "creates with urls as array of Deeplink structs" do
      resp = QPay::InvoiceResponse.new(
        invoice_id: "inv_123",
        qr_text: "qr_data",
        qr_image: "base64data",
        qpay_short_url: "https://qpay.mn/s/123",
        urls: [
          QPay::Deeplink.new(
            name: "Khan Bank",
            description: "Pay with Khan Bank",
            logo: "https://logo.url/khan.png",
            link: "khanbank://pay?id=123"
          )
        ]
      )

      expect(resp.invoice_id).to eq("inv_123")
      expect(resp.urls.length).to eq(1)
      expect(resp.urls.first.name).to eq("Khan Bank")
    end
  end

  describe QPay::PaymentCheckRequest do
    it "creates with nested Offset struct" do
      req = QPay::PaymentCheckRequest.new(
        object_type: "INVOICE",
        obj_id: "inv_123",
        offset: QPay::Offset.new(page_number: 1, page_limit: 10)
      )

      expect(req.object_type).to eq("INVOICE")
      expect(req.offset.page_number).to eq(1)
      expect(req.offset.page_limit).to eq(10)
    end
  end

  describe QPay::PaymentDetail do
    it "creates with all payment fields" do
      detail = QPay::PaymentDetail.new(
        payment_id: "pay_001",
        payment_status: "PAID",
        payment_amount: 10_000,
        payment_currency: "MNT",
        payment_wallet: "qpay",
        card_transactions: [],
        p2p_transactions: []
      )

      expect(detail.payment_id).to eq("pay_001")
      expect(detail.payment_status).to eq("PAID")
      expect(detail.payment_amount).to eq(10_000)
    end
  end

  describe QPay::PaymentCheckResponse do
    it "creates with rows" do
      resp = QPay::PaymentCheckResponse.new(
        count: 1,
        paid_amount: 5000,
        rows: [
          QPay::PaymentCheckRow.new(
            payment_id: "pay_001",
            payment_status: "PAID",
            payment_amount: 5000
          )
        ]
      )

      expect(resp.count).to eq(1)
      expect(resp.rows.first.payment_id).to eq("pay_001")
    end
  end

  describe QPay::PaymentListRequest do
    it "creates with date range and offset" do
      req = QPay::PaymentListRequest.new(
        object_type: "INVOICE",
        obj_id: "inv_123",
        start_date: "2024-01-01",
        end_date: "2024-12-31",
        offset: QPay::Offset.new(page_number: 1, page_limit: 20)
      )

      expect(req.start_date).to eq("2024-01-01")
      expect(req.end_date).to eq("2024-12-31")
      expect(req.offset.page_limit).to eq(20)
    end
  end

  describe QPay::CreateEbarimtRequest do
    it "creates with all fields" do
      req = QPay::CreateEbarimtRequest.new(
        payment_id: "pay_001",
        ebarimt_receiver_type: "CITIZEN",
        ebarimt_receiver: "AA12345678",
        district_code: "001",
        classification_code: "CLS001"
      )

      expect(req.payment_id).to eq("pay_001")
      expect(req.ebarimt_receiver_type).to eq("CITIZEN")
    end
  end

  describe QPay::EbarimtResponse do
    it "creates with nested items and histories" do
      resp = QPay::EbarimtResponse.new(
        id: "eb_001",
        amount: 10_000,
        vat_amount: 1000,
        barimt_status: "CREATED",
        barimt_items: [
          QPay::EbarimtItem.new(
            id: "item_001",
            name: "Product A",
            quantity: 1,
            amount: 10_000
          )
        ],
        barimt_histories: [
          QPay::EbarimtHistory.new(
            id: "hist_001",
            barimt_status: "CREATED"
          )
        ]
      )

      expect(resp.id).to eq("eb_001")
      expect(resp.barimt_items.first.name).to eq("Product A")
      expect(resp.barimt_histories.first.barimt_status).to eq("CREATED")
    end
  end

  describe QPay::Address do
    it "creates with location fields" do
      addr = QPay::Address.new(
        city: "Ulaanbaatar",
        district: "Khan-Uul",
        street: "Peace Avenue",
        zipcode: "14200",
        longitude: 106.9177016,
        latitude: 47.9184676
      )

      expect(addr.city).to eq("Ulaanbaatar")
      expect(addr.longitude).to eq(106.9177016)
    end
  end

  describe QPay::Account do
    it "creates with bank account fields" do
      acc = QPay::Account.new(
        account_bank_code: "050000",
        account_number: "1234567890",
        account_name: "Test Account",
        account_currency: "MNT",
        is_default: true
      )

      expect(acc.account_bank_code).to eq("050000")
      expect(acc.is_default).to be true
    end
  end

  describe QPay::Transaction do
    it "creates with nested accounts" do
      txn = QPay::Transaction.new(
        description: "Payment for order #123",
        amount: 50_000,
        accounts: [
          QPay::Account.new(
            account_bank_code: "050000",
            account_number: "9999999999",
            is_default: true
          )
        ]
      )

      expect(txn.amount).to eq(50_000)
      expect(txn.accounts.first.account_bank_code).to eq("050000")
    end
  end
end
