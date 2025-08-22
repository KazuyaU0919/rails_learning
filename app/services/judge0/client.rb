# app/services/judge0/client.rb
require "base64"

module Judge0
  class Error < StandardError; end

  class Client
    include HTTParty
    format :json
    default_timeout 10

    RUBY_LANG_ID = 72

    def initialize
      cfg = Rails.configuration.x.judge0 || {}
      @base = cfg[:base_url].to_s
      raise Error, "Judge0 base_url is not set" if @base.blank?

      @headers = { "Content-Type" => "application/json" }
      if (k = cfg[:api_key]).present?
        @headers["X-RapidAPI-Key"]  = k
        @headers["X-RapidAPI-Host"] = cfg[:host_hdr] if cfg[:host_hdr].present?
      end
    end

    # --- ここから既存の submit/fetch を Base64 送受信に揃える ---
    def submit(source_code:, language_id: RUBY_LANG_ID, stdin: nil)
      body = {
        source_code: Base64.strict_encode64(source_code.to_s.encode("UTF-8")),
        language_id: language_id
      }
      body[:stdin] = Base64.strict_encode64(stdin.to_s.encode("UTF-8")) if stdin
      self.class.post(
        "#{@base}/submissions?base64_encoded=true&wait=false",
        headers: @headers, body: body.to_json
      ).tap { |res| raise_if_bad(res) }
    end

    def fetch(token)
      self.class.get(
        "#{@base}/submissions/#{token}?base64_encoded=true",
        headers: @headers
      ).tap { |res| raise_if_bad(res) }
    end
    # --- ここまで ---

    # Ruby コードを投げて最終結果(JSON)を返す
    def run_ruby(code, language_id: RUBY_LANG_ID, max_wait: 5.0, interval: 0.4)
      token = submit(source_code: code, language_id: language_id).parsed_response["token"]
      raise Error, "submit returns no token" if token.blank?

      waited = 0.0
      loop do
        res = fetch(token).parsed_response
        # ↓↓↓ ここで Base64 を人間可読に変換
        decode_base64_fields!(res)

        status_id = res.dig("status", "id")
        return res if status_id && status_id >= 3

        sleep interval
        waited += interval
        break if waited >= max_wait
      end

      { "status" => { "id" => -1, "description" => "Timeout" } }
    end

    private

    def raise_if_bad(res)
      unless res.code && res.code.between?(200, 299)
        detail = res.parsed_response.is_a?(Hash) ? res.parsed_response : res.body
        raise Error, "Judge0 HTTP #{res.code}: #{detail}"
      end
      res
    end

    # Base64 で返ってくる可能性のあるフィールドをデコード
    def decode_base64_fields!(h)
      return h unless h.is_a?(Hash)
      %w[stdout stderr compile_output message].each do |k|
        v = h[k]
        next unless v.is_a?(String)
        begin
          h[k] = Base64.strict_decode64(v)
        rescue ArgumentError
          # すでに平文／Base64でない場合はそのまま
        end
      end
      h
    end
  end
end
