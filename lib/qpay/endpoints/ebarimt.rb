# frozen_string_literal: true

module QPay
  module Endpoints
    module Ebarimt
      # Creates an ebarimt (electronic tax receipt) for a payment.
      # POST /v2/ebarimt_v3/create
      #
      # @param request [QPay::CreateEbarimtRequest]
      # @return [QPay::EbarimtResponse]
      def create_ebarimt(request)
        data = do_request("POST", "/v2/ebarimt_v3/create", body: serialize(request))
        build_ebarimt_response(data)
      end

      # Cancels an ebarimt by payment ID.
      # DELETE /v2/ebarimt_v3/{id}
      #
      # @param payment_id [String]
      # @return [QPay::EbarimtResponse]
      def cancel_ebarimt(payment_id)
        data = do_request("DELETE", "/v2/ebarimt_v3/#{payment_id}")
        build_ebarimt_response(data)
      end

      private

      def build_ebarimt_response(data)
        return nil if data.nil?

        items = (data["barimt_items"] || []).map do |item|
          QPay::EbarimtItem.new(
            id: item["id"],
            barimt_id: item["barimt_id"],
            merchant_product_code: item["merchant_product_code"],
            tax_product_code: item["tax_product_code"],
            bar_code: item["bar_code"],
            name: item["name"],
            unit_price: item["unit_price"],
            quantity: item["quantity"],
            amount: item["amount"],
            city_tax_amount: item["city_tax_amount"],
            vat_amount: item["vat_amount"],
            note: item["note"],
            created_by: item["created_by"],
            created_date: item["created_date"],
            updated_by: item["updated_by"],
            updated_date: item["updated_date"],
            status: item["status"]
          )
        end

        histories = (data["barimt_histories"] || []).map do |h|
          QPay::EbarimtHistory.new(
            id: h["id"],
            barimt_id: h["barimt_id"],
            ebarimt_receiver_type: h["ebarimt_receiver_type"],
            ebarimt_receiver: h["ebarimt_receiver"],
            ebarimt_register_no: h["ebarimt_register_no"],
            ebarimt_bill_id: h["ebarimt_bill_id"],
            ebarimt_date: h["ebarimt_date"],
            ebarimt_mac_address: h["ebarimt_mac_address"],
            ebarimt_internal_code: h["ebarimt_internal_code"],
            ebarimt_bill_type: h["ebarimt_bill_type"],
            ebarimt_qr_data: h["ebarimt_qr_data"],
            ebarimt_lottery: h["ebarimt_lottery"],
            ebarimt_lottery_msg: h["ebarimt_lottery_msg"],
            ebarimt_error_code: h["ebarimt_error_code"],
            ebarimt_error_msg: h["ebarimt_error_msg"],
            ebarimt_response_code: h["ebarimt_response_code"],
            ebarimt_response_msg: h["ebarimt_response_msg"],
            note: h["note"],
            barimt_status: h["barimt_status"],
            barimt_status_date: h["barimt_status_date"],
            ebarimt_sent_email: h["ebarimt_sent_email"],
            ebarimt_receiver_phone: h["ebarimt_receiver_phone"],
            tax_type: h["tax_type"],
            created_by: h["created_by"],
            created_date: h["created_date"],
            updated_by: h["updated_by"],
            updated_date: h["updated_date"],
            status: h["status"]
          )
        end

        QPay::EbarimtResponse.new(
          id: data["id"],
          ebarimt_by: data["ebarimt_by"],
          g_wallet_id: data["g_wallet_id"],
          g_wallet_customer_id: data["g_wallet_customer_id"],
          ebarimt_receiver_type: data["ebarimt_receiver_type"],
          ebarimt_receiver: data["ebarimt_receiver"],
          ebarimt_district_code: data["ebarimt_district_code"],
          ebarimt_bill_type: data["ebarimt_bill_type"],
          g_merchant_id: data["g_merchant_id"],
          merchant_branch_code: data["merchant_branch_code"],
          merchant_terminal_code: data["merchant_terminal_code"],
          merchant_staff_code: data["merchant_staff_code"],
          merchant_register_no: data["merchant_register_no"],
          g_payment_id: data["g_payment_id"],
          paid_by: data["paid_by"],
          object_type: data["object_type"],
          obj_id: data["object_id"],
          amount: data["amount"],
          vat_amount: data["vat_amount"],
          city_tax_amount: data["city_tax_amount"],
          ebarimt_qr_data: data["ebarimt_qr_data"],
          ebarimt_lottery: data["ebarimt_lottery"],
          note: data["note"],
          barimt_status: data["barimt_status"],
          barimt_status_date: data["barimt_status_date"],
          ebarimt_sent_email: data["ebarimt_sent_email"],
          ebarimt_receiver_phone: data["ebarimt_receiver_phone"],
          tax_type: data["tax_type"],
          merchant_tin: data["merchant_tin"],
          ebarimt_receipt_id: data["ebarimt_receipt_id"],
          created_by: data["created_by"],
          created_date: data["created_date"],
          updated_by: data["updated_by"],
          updated_date: data["updated_date"],
          status: data["status"],
          barimt_items: items,
          barimt_transactions: data["barimt_transactions"] || [],
          barimt_histories: histories
        )
      end
    end
  end
end
