# frozen_string_literal: true

require "faraday"
require "json"

module QPay
  class Client
    include Endpoints::Auth
    include Endpoints::Invoices
    include Endpoints::Payments
    include Endpoints::Ebarimt

    TOKEN_BUFFER_SECONDS = 30

    # Creates a new QPay client.
    #
    # @param config [QPay::Config] the configuration object
    # @param faraday [Faraday::Connection, nil] optional custom Faraday connection
    def initialize(config:, faraday: nil)
      @config = config
      @mutex = Mutex.new
      @access_token = nil
      @refresh_token = nil
      @expires_at = 0
      @refresh_expires_at = 0

      @http = faraday || Faraday.new do |f|
        f.options.timeout = 30
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end

    private

    def ensure_token
      now = Time.now.to_i

      can_refresh = false
      refresh_tok = nil

      @mutex.synchronize do
        # Access token still valid
        if @access_token && now < @expires_at - TOKEN_BUFFER_SECONDS
          return
        end

        can_refresh = @refresh_token && !@refresh_token.empty? && now < @refresh_expires_at - TOKEN_BUFFER_SECONDS
        refresh_tok = @refresh_token
      end

      # Try refresh first
      if can_refresh
        begin
          token = do_refresh_token_http(refresh_tok)
          store_token(token)
          return
        rescue QPay::Error
          # Refresh failed, fall through to get new token
        end
      end

      # Both expired or no tokens, get new token
      token = get_token_request
      store_token(token)
    end

    def store_token(token)
      @mutex.synchronize do
        @access_token = token.access_token
        @refresh_token = token.refresh_token
        @expires_at = token.expires_in
        @refresh_expires_at = token.refresh_expires_in
      end
    end

    def do_request(method, path, body: nil)
      ensure_token

      url = "#{@config.base_url}#{path}"
      access_tok = @mutex.synchronize { @access_token }

      response = @http.run_request(method.downcase.to_sym, url, body, {}) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["Authorization"] = "Bearer #{access_tok}"
      end

      handle_response(response)
    end

    def do_basic_auth_request(method, path)
      url = "#{@config.base_url}#{path}"

      response = @http.run_request(method.downcase.to_sym, url, nil, {}) do |req|
        req.headers["Authorization"] = "Basic #{basic_auth_credentials}"
      end

      body = response.body

      unless response.success?
        parsed = parse_json(body)
        code = parsed["error"]
        message = parsed["message"] || body
        raise QPay::Error.new(
          status_code: response.status,
          code: code.nil? || code.empty? ? status_text(response.status) : code,
          message: message.nil? || message.empty? ? body : message,
          raw_body: body
        )
      end

      parsed = parse_json(body)
      build_token_response(parsed)
    end

    def handle_response(response)
      body = response.body

      unless response.success?
        parsed = parse_json(body)
        code = parsed["error"]
        message = parsed["message"]
        raise QPay::Error.new(
          status_code: response.status,
          code: code.nil? || code.empty? ? status_text(response.status) : code,
          message: message.nil? || message.empty? ? body : message,
          raw_body: body
        )
      end

      return nil if body.nil? || body.empty?

      parse_json(body)
    end

    def serialize(obj)
      hash = obj.to_h.compact.transform_keys { |k| camelize_key(k) }
      deep_serialize(hash).to_json
    end

    def deep_serialize(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          result[k] = deep_serialize(v)
        end
      when Array
        obj.map { |item| deep_serialize(item) }
      when Struct
        deep_serialize(obj.to_h.compact.transform_keys { |k| camelize_key(k) })
      else
        obj
      end
    end

    # Converts Ruby snake_case keys to the JSON keys expected by QPay API.
    # Most keys are simple snake_case, but some need special handling.
    KEY_MAP = {
      "qpay_short_url" => "qPay_shortUrl",
      "obj_id" => "object_id",
    }.freeze

    def camelize_key(key)
      str = key.to_s
      KEY_MAP.fetch(str, str)
    end

    def parse_json(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end

    def basic_auth_credentials
      require "base64"
      Base64.strict_encode64("#{@config.username}:#{@config.password}")
    end

    def status_text(code)
      Rack::Utils::HTTP_STATUS_CODES[code] || "Unknown Status"
    rescue NameError
      # Rack not available, use basic mapping
      HTTP_STATUS_TEXTS.fetch(code, "Unknown Status")
    end

    HTTP_STATUS_TEXTS = {
      200 => "OK",
      201 => "Created",
      204 => "No Content",
      400 => "Bad Request",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      405 => "Method Not Allowed",
      409 => "Conflict",
      422 => "Unprocessable Entity",
      429 => "Too Many Requests",
      500 => "Internal Server Error",
      502 => "Bad Gateway",
      503 => "Service Unavailable",
    }.freeze
  end
end
