# frozen_string_literal: true

RSpec.describe QPay::Config do
  describe "#initialize" do
    it "sets all attributes" do
      config = QPay::Config.new(
        base_url: "https://merchant.qpay.mn",
        username: "user",
        password: "pass",
        invoice_code: "INV001",
        callback_url: "https://example.com/cb"
      )

      expect(config.base_url).to eq("https://merchant.qpay.mn")
      expect(config.username).to eq("user")
      expect(config.password).to eq("pass")
      expect(config.invoice_code).to eq("INV001")
      expect(config.callback_url).to eq("https://example.com/cb")
    end

    it "allows attribute updates via accessors" do
      config = QPay::Config.new(
        base_url: "https://old.url",
        username: "user",
        password: "pass",
        invoice_code: "INV001",
        callback_url: "https://old.cb"
      )

      config.base_url = "https://new.url"
      config.callback_url = "https://new.cb"

      expect(config.base_url).to eq("https://new.url")
      expect(config.callback_url).to eq("https://new.cb")
    end
  end

  describe ".from_env" do
    let(:env_vars) do
      {
        "QPAY_BASE_URL" => "https://merchant.qpay.mn",
        "QPAY_USERNAME" => "env_user",
        "QPAY_PASSWORD" => "env_pass",
        "QPAY_INVOICE_CODE" => "ENV_INV",
        "QPAY_CALLBACK_URL" => "https://env.example.com/cb"
      }
    end

    before do
      env_vars.each { |k, v| ENV[k] = v }
    end

    after do
      env_vars.each_key { |k| ENV.delete(k) }
    end

    it "loads configuration from environment variables" do
      config = QPay::Config.from_env

      expect(config.base_url).to eq("https://merchant.qpay.mn")
      expect(config.username).to eq("env_user")
      expect(config.password).to eq("env_pass")
      expect(config.invoice_code).to eq("ENV_INV")
      expect(config.callback_url).to eq("https://env.example.com/cb")
    end

    it "raises ArgumentError when QPAY_BASE_URL is missing" do
      ENV.delete("QPAY_BASE_URL")

      expect { QPay::Config.from_env }.to raise_error(
        ArgumentError, /QPAY_BASE_URL/
      )
    end

    it "raises ArgumentError when QPAY_USERNAME is missing" do
      ENV.delete("QPAY_USERNAME")

      expect { QPay::Config.from_env }.to raise_error(
        ArgumentError, /QPAY_USERNAME/
      )
    end

    it "raises ArgumentError when multiple variables are missing" do
      ENV.delete("QPAY_USERNAME")
      ENV.delete("QPAY_PASSWORD")

      expect { QPay::Config.from_env }.to raise_error(
        ArgumentError, /QPAY_USERNAME.*QPAY_PASSWORD|QPAY_PASSWORD.*QPAY_USERNAME/
      )
    end

    it "raises ArgumentError when a variable is empty string" do
      ENV["QPAY_BASE_URL"] = ""

      expect { QPay::Config.from_env }.to raise_error(
        ArgumentError, /QPAY_BASE_URL/
      )
    end

    it "lists all missing variables in the error message" do
      env_vars.each_key { |k| ENV.delete(k) }

      expect { QPay::Config.from_env }.to raise_error(ArgumentError) do |error|
        env_vars.each_key do |key|
          expect(error.message).to include(key)
        end
      end
    end
  end
end
