# frozen_string_literal: true

module QPay
  module Endpoints
    module Payments
      # Retrieves payment details by payment ID.
      # GET /v2/payment/{id}
      #
      # @param payment_id [String]
      # @return [QPay::PaymentDetail]
      def get_payment(payment_id)
        data = do_request("GET", "/v2/payment/#{payment_id}")
        build_payment_detail(data)
      end

      # Checks if a payment has been made for an invoice.
      # POST /v2/payment/check
      #
      # @param request [QPay::PaymentCheckRequest]
      # @return [QPay::PaymentCheckResponse]
      def check_payment(request)
        data = do_request("POST", "/v2/payment/check", body: serialize(request))
        build_payment_check_response(data)
      end

      # Returns a list of payments matching the given criteria.
      # POST /v2/payment/list
      #
      # @param request [QPay::PaymentListRequest]
      # @return [QPay::PaymentListResponse]
      def list_payments(request)
        data = do_request("POST", "/v2/payment/list", body: serialize(request))
        build_payment_list_response(data)
      end

      # Cancels a payment (card transactions only).
      # DELETE /v2/payment/cancel/{id}
      #
      # @param payment_id [String]
      # @param request [QPay::PaymentCancelRequest, nil]
      # @return [void]
      def cancel_payment(payment_id, request: nil)
        do_request("DELETE", "/v2/payment/cancel/#{payment_id}", body: request ? serialize(request) : nil)
        nil
      end

      # Refunds a payment (card transactions only).
      # DELETE /v2/payment/refund/{id}
      #
      # @param payment_id [String]
      # @param request [QPay::PaymentRefundRequest, nil]
      # @return [void]
      def refund_payment(payment_id, request: nil)
        do_request("DELETE", "/v2/payment/refund/#{payment_id}", body: request ? serialize(request) : nil)
        nil
      end

      private

      def build_card_transactions(items)
        (items || []).map do |ct|
          QPay::CardTransaction.new(
            card_merchant_code: ct["card_merchant_code"],
            card_terminal_code: ct["card_terminal_code"],
            card_number: ct["card_number"],
            card_type: ct["card_type"],
            is_cross_border: ct["is_cross_border"],
            amount: ct["amount"],
            transaction_amount: ct["transaction_amount"],
            currency: ct["currency"],
            transaction_currency: ct["transaction_currency"],
            date: ct["date"],
            transaction_date: ct["transaction_date"],
            status: ct["status"],
            transaction_status: ct["transaction_status"],
            settlement_status: ct["settlement_status"],
            settlement_status_date: ct["settlement_status_date"]
          )
        end
      end

      def build_p2p_transactions(items)
        (items || []).map do |pt|
          QPay::P2PTransaction.new(
            transaction_bank_code: pt["transaction_bank_code"],
            account_bank_code: pt["account_bank_code"],
            account_bank_name: pt["account_bank_name"],
            account_number: pt["account_number"],
            status: pt["status"],
            amount: pt["amount"],
            currency: pt["currency"],
            settlement_status: pt["settlement_status"]
          )
        end
      end

      def build_payment_detail(data)
        return nil if data.nil?

        QPay::PaymentDetail.new(
          payment_id: data["payment_id"],
          payment_status: data["payment_status"],
          payment_fee: data["payment_fee"],
          payment_amount: data["payment_amount"],
          payment_currency: data["payment_currency"],
          payment_date: data["payment_date"],
          payment_wallet: data["payment_wallet"],
          transaction_type: data["transaction_type"],
          object_type: data["object_type"],
          obj_id: data["object_id"],
          next_payment_date: data["next_payment_date"],
          next_payment_datetime: data["next_payment_datetime"],
          card_transactions: build_card_transactions(data["card_transactions"]),
          p2p_transactions: build_p2p_transactions(data["p2p_transactions"])
        )
      end

      def build_payment_check_response(data)
        return nil if data.nil?

        rows = (data["rows"] || []).map do |row|
          QPay::PaymentCheckRow.new(
            payment_id: row["payment_id"],
            payment_status: row["payment_status"],
            payment_amount: row["payment_amount"],
            trx_fee: row["trx_fee"],
            payment_currency: row["payment_currency"],
            payment_wallet: row["payment_wallet"],
            payment_type: row["payment_type"],
            next_payment_date: row["next_payment_date"],
            next_payment_datetime: row["next_payment_datetime"],
            card_transactions: build_card_transactions(row["card_transactions"]),
            p2p_transactions: build_p2p_transactions(row["p2p_transactions"])
          )
        end

        QPay::PaymentCheckResponse.new(
          count: data["count"],
          paid_amount: data["paid_amount"],
          rows: rows
        )
      end

      def build_payment_list_response(data)
        return nil if data.nil?

        rows = (data["rows"] || []).map do |row|
          QPay::PaymentListItem.new(
            payment_id: row["payment_id"],
            payment_date: row["payment_date"],
            payment_status: row["payment_status"],
            payment_fee: row["payment_fee"],
            payment_amount: row["payment_amount"],
            payment_currency: row["payment_currency"],
            payment_wallet: row["payment_wallet"],
            payment_name: row["payment_name"],
            payment_description: row["payment_description"],
            qr_code: row["qr_code"],
            paid_by: row["paid_by"],
            object_type: row["object_type"],
            obj_id: row["object_id"]
          )
        end

        QPay::PaymentListResponse.new(
          count: data["count"],
          rows: rows
        )
      end
    end
  end
end
