# frozen_string_literal: true

module QPay
  # --- Auth ---

  TokenResponse = Struct.new(
    :token_type, :refresh_expires_in, :refresh_token,
    :access_token, :expires_in, :scope,
    :not_before_policy, :session_state,
    keyword_init: true
  )

  # --- Common nested types ---

  Address = Struct.new(
    :city, :district, :street, :building,
    :address, :zipcode, :longitude, :latitude,
    keyword_init: true
  )

  SenderBranchData = Struct.new(
    :register, :name, :email, :phone, :address,
    keyword_init: true
  )

  SenderStaffData = Struct.new(
    :name, :email, :phone,
    keyword_init: true
  )

  InvoiceReceiverData = Struct.new(
    :register, :name, :email, :phone, :address,
    keyword_init: true
  )

  Account = Struct.new(
    :account_bank_code, :account_number, :iban_number,
    :account_name, :account_currency, :is_default,
    keyword_init: true
  )

  Transaction = Struct.new(
    :description, :amount, :accounts,
    keyword_init: true
  )

  InvoiceLine = Struct.new(
    :tax_product_code, :line_description, :line_quantity,
    :line_unit_price, :note, :discounts, :surcharges, :taxes,
    keyword_init: true
  )

  EbarimtInvoiceLine = Struct.new(
    :tax_product_code, :line_description, :barcode,
    :line_quantity, :line_unit_price, :note,
    :classification_code, :taxes,
    keyword_init: true
  )

  TaxEntry = Struct.new(
    :tax_code, :discount_code, :surcharge_code,
    :description, :amount, :note,
    keyword_init: true
  )

  Deeplink = Struct.new(
    :name, :description, :logo, :link,
    keyword_init: true
  )

  # --- Invoice ---

  CreateInvoiceRequest = Struct.new(
    :invoice_code, :sender_invoice_no, :sender_branch_code,
    :sender_branch_data, :sender_staff_data, :sender_staff_code,
    :invoice_receiver_code, :invoice_receiver_data, :invoice_description,
    :enable_expiry, :allow_partial, :minimum_amount,
    :allow_exceed, :maximum_amount, :amount,
    :callback_url, :sender_terminal_code, :sender_terminal_data,
    :allow_subscribe, :subscription_interval, :subscription_webhook,
    :note, :transactions, :lines,
    keyword_init: true
  )

  CreateSimpleInvoiceRequest = Struct.new(
    :invoice_code, :sender_invoice_no, :invoice_receiver_code,
    :invoice_description, :sender_branch_code, :amount, :callback_url,
    keyword_init: true
  )

  CreateEbarimtInvoiceRequest = Struct.new(
    :invoice_code, :sender_invoice_no, :sender_branch_code,
    :sender_staff_data, :sender_staff_code, :invoice_receiver_code,
    :invoice_receiver_data, :invoice_description, :tax_type,
    :district_code, :callback_url, :lines,
    keyword_init: true
  )

  InvoiceResponse = Struct.new(
    :invoice_id, :qr_text, :qr_image, :qpay_short_url, :urls,
    keyword_init: true
  )

  # --- Payment ---

  Offset = Struct.new(
    :page_number, :page_limit,
    keyword_init: true
  )

  PaymentCheckRequest = Struct.new(
    :object_type, :obj_id, :offset,
    keyword_init: true
  )

  PaymentCheckResponse = Struct.new(
    :count, :paid_amount, :rows,
    keyword_init: true
  )

  PaymentCheckRow = Struct.new(
    :payment_id, :payment_status, :payment_amount,
    :trx_fee, :payment_currency, :payment_wallet,
    :payment_type, :next_payment_date, :next_payment_datetime,
    :card_transactions, :p2p_transactions,
    keyword_init: true
  )

  PaymentDetail = Struct.new(
    :payment_id, :payment_status, :payment_fee,
    :payment_amount, :payment_currency, :payment_date,
    :payment_wallet, :transaction_type, :object_type,
    :obj_id, :next_payment_date, :next_payment_datetime,
    :card_transactions, :p2p_transactions,
    keyword_init: true
  )

  CardTransaction = Struct.new(
    :card_merchant_code, :card_terminal_code, :card_number,
    :card_type, :is_cross_border, :amount,
    :transaction_amount, :currency, :transaction_currency,
    :date, :transaction_date, :status,
    :transaction_status, :settlement_status, :settlement_status_date,
    keyword_init: true
  )

  P2PTransaction = Struct.new(
    :transaction_bank_code, :account_bank_code, :account_bank_name,
    :account_number, :status, :amount,
    :currency, :settlement_status,
    keyword_init: true
  )

  PaymentListRequest = Struct.new(
    :object_type, :obj_id, :start_date, :end_date, :offset,
    keyword_init: true
  )

  PaymentListResponse = Struct.new(
    :count, :rows,
    keyword_init: true
  )

  PaymentListItem = Struct.new(
    :payment_id, :payment_date, :payment_status,
    :payment_fee, :payment_amount, :payment_currency,
    :payment_wallet, :payment_name, :payment_description,
    :qr_code, :paid_by, :object_type, :obj_id,
    keyword_init: true
  )

  PaymentCancelRequest = Struct.new(
    :callback_url, :note,
    keyword_init: true
  )

  PaymentRefundRequest = Struct.new(
    :callback_url, :note,
    keyword_init: true
  )

  # --- Ebarimt ---

  CreateEbarimtRequest = Struct.new(
    :payment_id, :ebarimt_receiver_type, :ebarimt_receiver,
    :district_code, :classification_code,
    keyword_init: true
  )

  EbarimtResponse = Struct.new(
    :id, :ebarimt_by, :g_wallet_id, :g_wallet_customer_id,
    :ebarimt_receiver_type, :ebarimt_receiver, :ebarimt_district_code,
    :ebarimt_bill_type, :g_merchant_id, :merchant_branch_code,
    :merchant_terminal_code, :merchant_staff_code, :merchant_register_no,
    :g_payment_id, :paid_by, :object_type, :obj_id,
    :amount, :vat_amount, :city_tax_amount,
    :ebarimt_qr_data, :ebarimt_lottery, :note,
    :barimt_status, :barimt_status_date, :ebarimt_sent_email,
    :ebarimt_receiver_phone, :tax_type, :merchant_tin,
    :ebarimt_receipt_id, :created_by, :created_date,
    :updated_by, :updated_date, :status,
    :barimt_items, :barimt_transactions, :barimt_histories,
    keyword_init: true
  )

  EbarimtItem = Struct.new(
    :id, :barimt_id, :merchant_product_code, :tax_product_code,
    :bar_code, :name, :unit_price, :quantity,
    :amount, :city_tax_amount, :vat_amount, :note,
    :created_by, :created_date, :updated_by, :updated_date, :status,
    keyword_init: true
  )

  EbarimtHistory = Struct.new(
    :id, :barimt_id, :ebarimt_receiver_type, :ebarimt_receiver,
    :ebarimt_register_no, :ebarimt_bill_id, :ebarimt_date,
    :ebarimt_mac_address, :ebarimt_internal_code, :ebarimt_bill_type,
    :ebarimt_qr_data, :ebarimt_lottery, :ebarimt_lottery_msg,
    :ebarimt_error_code, :ebarimt_error_msg,
    :ebarimt_response_code, :ebarimt_response_msg,
    :note, :barimt_status, :barimt_status_date,
    :ebarimt_sent_email, :ebarimt_receiver_phone, :tax_type,
    :created_by, :created_date, :updated_by, :updated_date, :status,
    keyword_init: true
  )
end
