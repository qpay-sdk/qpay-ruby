# frozen_string_literal: true

module QPay
  module Endpoints
    module Invoices
      # Creates a detailed invoice with full options.
      # POST /v2/invoice
      #
      # @param request [QPay::CreateInvoiceRequest]
      # @return [QPay::InvoiceResponse]
      def create_invoice(request)
        data = do_request("POST", "/v2/invoice", body: serialize(request))
        build_invoice_response(data)
      end

      # Creates a simple invoice with minimal fields.
      # POST /v2/invoice
      #
      # @param request [QPay::CreateSimpleInvoiceRequest]
      # @return [QPay::InvoiceResponse]
      def create_simple_invoice(request)
        data = do_request("POST", "/v2/invoice", body: serialize(request))
        build_invoice_response(data)
      end

      # Creates an invoice with ebarimt (tax) information.
      # POST /v2/invoice
      #
      # @param request [QPay::CreateEbarimtInvoiceRequest]
      # @return [QPay::InvoiceResponse]
      def create_ebarimt_invoice(request)
        data = do_request("POST", "/v2/invoice", body: serialize(request))
        build_invoice_response(data)
      end

      # Cancels an existing invoice by ID.
      # DELETE /v2/invoice/{id}
      #
      # @param invoice_id [String]
      # @return [void]
      def cancel_invoice(invoice_id)
        do_request("DELETE", "/v2/invoice/#{invoice_id}")
        nil
      end

      private

      def build_invoice_response(data)
        return nil if data.nil?

        urls = (data["urls"] || []).map do |u|
          QPay::Deeplink.new(
            name: u["name"],
            description: u["description"],
            logo: u["logo"],
            link: u["link"]
          )
        end

        QPay::InvoiceResponse.new(
          invoice_id: data["invoice_id"],
          qr_text: data["qr_text"],
          qr_image: data["qr_image"],
          qpay_short_url: data["qPay_shortUrl"],
          urls: urls
        )
      end
    end
  end
end
