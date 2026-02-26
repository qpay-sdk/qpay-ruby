# frozen_string_literal: true

module QPay
  class Error < StandardError
    attr_reader :status_code, :code, :raw_body

    def initialize(status_code:, code: nil, message: nil, raw_body: nil)
      @status_code = status_code
      @code = code
      @raw_body = raw_body
      super(build_message(message))
    end

    private

    def build_message(msg)
      "qpay: #{@code} - #{msg} (status #{@status_code})"
    end
  end

  # Returns [QPay::Error, true] if the error is a QPay::Error, [nil, false] otherwise.
  def self.qpay_error?(err)
    if err.is_a?(QPay::Error)
      [err, true]
    else
      [nil, false]
    end
  end

  # Error code constants
  ACCOUNT_BANK_DUPLICATED              = "ACCOUNT_BANK_DUPLICATED"
  ACCOUNT_SELECTION_INVALID            = "ACCOUNT_SELECTION_INVALID"
  AUTHENTICATION_FAILED                = "AUTHENTICATION_FAILED"
  BANK_ACCOUNT_NOTFOUND                = "BANK_ACCOUNT_NOTFOUND"
  BANK_MCC_ALREADY_ADDED               = "BANK_MCC_ALREADY_ADDED"
  BANK_MCC_NOT_FOUND                   = "BANK_MCC_NOT_FOUND"
  CARD_TERMINAL_NOTFOUND               = "CARD_TERMINAL_NOTFOUND"
  CLIENT_NOTFOUND                      = "CLIENT_NOTFOUND"
  CLIENT_USERNAME_DUPLICATED           = "CLIENT_USERNAME_DUPLICATED"
  CUSTOMER_DUPLICATE                   = "CUSTOMER_DUPLICATE"
  CUSTOMER_NOTFOUND                    = "CUSTOMER_NOTFOUND"
  CUSTOMER_REGISTER_INVALID            = "CUSTOMER_REGISTER_INVALID"
  EBARIMT_CANCEL_NOTSUPPERDED          = "EBARIMT_CANCEL_NOTSUPPERDED"
  EBARIMT_NOT_REGISTERED               = "EBARIMT_NOT_REGISTERED"
  EBARIMT_QR_CODE_INVALID              = "EBARIMT_QR_CODE_INVALID"
  INFORM_NOTFOUND                      = "INFORM_NOTFOUND"
  INPUT_CODE_REGISTERED                = "INPUT_CODE_REGISTERED"
  INPUT_NOTFOUND                       = "INPUT_NOTFOUND"
  INVALID_AMOUNT                       = "INVALID_AMOUNT"
  INVALID_OBJECT_TYPE                  = "INVALID_OBJECT_TYPE"
  INVOICE_ALREADY_CANCELED             = "INVOICE_ALREADY_CANCELED"
  INVOICE_CODE_INVALID                 = "INVOICE_CODE_INVALID"
  INVOICE_CODE_REGISTERED              = "INVOICE_CODE_REGISTERED"
  INVOICE_LINE_REQUIRED                = "INVOICE_LINE_REQUIRED"
  INVOICE_NOTFOUND                     = "INVOICE_NOTFOUND"
  INVOICE_PAID                         = "INVOICE_PAID"
  INVOICE_RECEIVER_DATA_ADDRESS_REQUIRED  = "INVOICE_RECEIVER_DATA_ADDRESS_REQUIRED"
  INVOICE_RECEIVER_DATA_EMAIL_REQUIRED    = "INVOICE_RECEIVER_DATA_EMAIL_REQUIRED"
  INVOICE_RECEIVER_DATA_PHONE_REQUIRED    = "INVOICE_RECEIVER_DATA_PHONE_REQUIRED"
  INVOICE_RECEIVER_DATA_REQUIRED          = "INVOICE_RECEIVER_DATA_REQUIRED"
  MAX_AMOUNT_ERR                       = "MAX_AMOUNT_ERR"
  MCC_NOTFOUND                         = "MCC_NOTFOUND"
  MERCHANT_ALREADY_REGISTERED          = "MERCHANT_ALREADY_REGISTERED"
  MERCHANT_INACTIVE                    = "MERCHANT_INACTIVE"
  MERCHANT_NOTFOUND                    = "MERCHANT_NOTFOUND"
  MIN_AMOUNT_ERR                       = "MIN_AMOUNT_ERR"
  NO_CREDENDIALS                       = "NO_CREDENDIALS"
  OBJECT_DATA_ERROR                    = "OBJECT_DATA_ERROR"
  P2P_TERMINAL_NOTFOUND                = "P2P_TERMINAL_NOTFOUND"
  PAYMENT_ALREADY_CANCELED             = "PAYMENT_ALREADY_CANCELED"
  PAYMENT_NOT_PAID                     = "PAYMENT_NOT_PAID"
  PAYMENT_NOTFOUND                     = "PAYMENT_NOTFOUND"
  PERMISSION_DENIED                    = "PERMISSION_DENIED"
  QRACCOUNT_INACTIVE                   = "QRACCOUNT_INACTIVE"
  QRACCOUNT_NOTFOUND                   = "QRACCOUNT_NOTFOUND"
  QRCODE_NOTFOUND                      = "QRCODE_NOTFOUND"
  QRCODE_USED                          = "QRCODE_USED"
  SENDER_BRANCH_DATA_REQUIRED          = "SENDER_BRANCH_DATA_REQUIRED"
  TAX_LINE_REQUIRED                    = "TAX_LINE_REQUIRED"
  TAX_PRODUCT_CODE_REQUIRED            = "TAX_PRODUCT_CODE_REQUIRED"
  TRANSACTION_NOT_APPROVED             = "TRANSACTION_NOT_APPROVED"
  TRANSACTION_REQUIRED                 = "TRANSACTION_REQUIRED"
end
