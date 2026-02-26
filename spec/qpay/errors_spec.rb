# frozen_string_literal: true

RSpec.describe QPay::Error do
  describe "#initialize" do
    it "builds a formatted error message" do
      error = QPay::Error.new(
        status_code: 401,
        code: "AUTHENTICATION_FAILED",
        message: "Invalid credentials",
        raw_body: '{"error":"AUTHENTICATION_FAILED"}'
      )

      expect(error.message).to eq("qpay: AUTHENTICATION_FAILED - Invalid credentials (status 401)")
    end

    it "stores status_code, code, and raw_body" do
      error = QPay::Error.new(
        status_code: 404,
        code: "INVOICE_NOTFOUND",
        message: "Not found",
        raw_body: '{"error":"INVOICE_NOTFOUND"}'
      )

      expect(error.status_code).to eq(404)
      expect(error.code).to eq("INVOICE_NOTFOUND")
      expect(error.raw_body).to eq('{"error":"INVOICE_NOTFOUND"}')
    end

    it "is a subclass of StandardError" do
      error = QPay::Error.new(status_code: 500, code: "ERR", message: "fail")
      expect(error).to be_a(StandardError)
    end

    it "handles nil code and message" do
      error = QPay::Error.new(status_code: 500)
      expect(error.message).to eq("qpay:  -  (status 500)")
      expect(error.code).to be_nil
      expect(error.raw_body).to be_nil
    end
  end
end

RSpec.describe QPay do
  describe ".qpay_error?" do
    it "returns [error, true] for QPay::Error instances" do
      error = QPay::Error.new(status_code: 400, code: "BAD", message: "bad")
      result, is_qpay = QPay.qpay_error?(error)

      expect(result).to eq(error)
      expect(is_qpay).to be true
    end

    it "returns [nil, false] for other error types" do
      error = StandardError.new("generic error")
      result, is_qpay = QPay.qpay_error?(error)

      expect(result).to be_nil
      expect(is_qpay).to be false
    end

    it "returns [nil, false] for non-error objects" do
      result, is_qpay = QPay.qpay_error?("not an error")

      expect(result).to be_nil
      expect(is_qpay).to be false
    end
  end

  describe "error code constants" do
    it "defines AUTHENTICATION_FAILED" do
      expect(QPay::AUTHENTICATION_FAILED).to eq("AUTHENTICATION_FAILED")
    end

    it "defines INVOICE_NOTFOUND" do
      expect(QPay::INVOICE_NOTFOUND).to eq("INVOICE_NOTFOUND")
    end

    it "defines PAYMENT_NOTFOUND" do
      expect(QPay::PAYMENT_NOTFOUND).to eq("PAYMENT_NOTFOUND")
    end

    it "defines PERMISSION_DENIED" do
      expect(QPay::PERMISSION_DENIED).to eq("PERMISSION_DENIED")
    end

    it "defines INVOICE_PAID" do
      expect(QPay::INVOICE_PAID).to eq("INVOICE_PAID")
    end

    it "defines PAYMENT_ALREADY_CANCELED" do
      expect(QPay::PAYMENT_ALREADY_CANCELED).to eq("PAYMENT_ALREADY_CANCELED")
    end

    it "defines INVALID_AMOUNT" do
      expect(QPay::INVALID_AMOUNT).to eq("INVALID_AMOUNT")
    end

    it "defines MERCHANT_NOTFOUND" do
      expect(QPay::MERCHANT_NOTFOUND).to eq("MERCHANT_NOTFOUND")
    end

    it "defines NO_CREDENDIALS" do
      expect(QPay::NO_CREDENDIALS).to eq("NO_CREDENDIALS")
    end

    it "defines EBARIMT_NOT_REGISTERED" do
      expect(QPay::EBARIMT_NOT_REGISTERED).to eq("EBARIMT_NOT_REGISTERED")
    end
  end
end
