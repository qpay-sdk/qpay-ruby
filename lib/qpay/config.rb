# frozen_string_literal: true

module QPay
  class Config
    attr_accessor :base_url, :username, :password, :invoice_code, :callback_url

    def initialize(base_url:, username:, password:, invoice_code:, callback_url:)
      @base_url = base_url
      @username = username
      @password = password
      @invoice_code = invoice_code
      @callback_url = callback_url
    end

    # Loads configuration from environment variables.
    # Raises ArgumentError if any required variable is missing.
    def self.from_env
      mapping = {
        "QPAY_BASE_URL" => :base_url,
        "QPAY_USERNAME" => :username,
        "QPAY_PASSWORD" => :password,
        "QPAY_INVOICE_CODE" => :invoice_code,
        "QPAY_CALLBACK_URL" => :callback_url,
      }

      values = {}
      missing = []

      mapping.each do |env_var, key|
        val = ENV[env_var]
        if val.nil? || val.empty?
          missing << env_var
        else
          values[key] = val
        end
      end

      unless missing.empty?
        raise ArgumentError, "required environment variable(s) not set: #{missing.join(", ")}"
      end

      new(**values)
    end
  end
end
