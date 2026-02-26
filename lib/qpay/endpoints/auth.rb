# frozen_string_literal: true

module QPay
  module Endpoints
    module Auth
      # Authenticates with QPay using Basic Auth and returns a new token pair.
      # Also stores the token for subsequent requests.
      #
      # @return [QPay::TokenResponse]
      def get_token
        token = get_token_request
        store_token(token)
        token
      end

      # Uses the current refresh token to obtain a new access token.
      #
      # @return [QPay::TokenResponse]
      def refresh_token
        refresh_tok = @mutex.synchronize { @refresh_token }
        token = do_refresh_token_http(refresh_tok)
        store_token(token)
        token
      end

      private

      def get_token_request
        do_basic_auth_request("POST", "/v2/auth/token")
      end

      def do_refresh_token_http(refresh_tok)
        url = "#{@config.base_url}/v2/auth/refresh"
        response = @http.post(url) do |req|
          req.headers["Authorization"] = "Bearer #{refresh_tok}"
        end

        handle_token_response(response)
      end

      def handle_token_response(response)
        body = response.body

        unless response.success?
          parsed = parse_json(body)
          raise QPay::Error.new(
            status_code: response.status,
            code: parsed["error"],
            message: parsed["message"] || body,
            raw_body: body
          )
        end

        parsed = parse_json(body)
        build_token_response(parsed)
      end

      def build_token_response(data)
        QPay::TokenResponse.new(
          token_type: data["token_type"],
          refresh_expires_in: data["refresh_expires_in"],
          refresh_token: data["refresh_token"],
          access_token: data["access_token"],
          expires_in: data["expires_in"],
          scope: data["scope"],
          not_before_policy: data["not-before-policy"],
          session_state: data["session_state"]
        )
      end
    end
  end
end
