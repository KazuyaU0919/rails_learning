# ============================================================
# Service: Judge0::Client
# ------------------------------------------------------------
# Judge0 API クライアント（HTTP）。
# 特徴:
# - Base64 送受信（source_code/stdin の送信、stdout/stderr 等の受信）
# - submit → token 取得 → fetch で完了までポーリング
# - 例外: 通信・不正レスポンスは Judge0::Error
# セキュリティ/可用性:
# - タイムアウトを設定（default_timeout 10s）
# - API キー/ホストヘッダは Rails.configuration.x.judge0 を参照
# ============================================================
require "base64"

module Judge0
  class Error < StandardError; end

  class Client
    include HTTParty
    format :json
    default_timeout 10

    # Judge0 上の Ruby 言語ID（固定値）
    RUBY_LANG_ID = 72

    # =======================
    # 構築
    # -----------------------
    # 設定:
    #   x.judge0.base_url : APIベースURL（必須）
    #   x.judge0.api_key  : RapidAPIキー（任意）
    #   x.judge0.host_hdr : RapidAPIホストヘッダ（任意）
    # =======================
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

    # =======================
    # サブミット（非同期）
    # -----------------------
    # source_code / stdin を Base64 で送信
    # 戻り値: HTTParty::Response（token を含むJSONを期待）
    # =======================
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

    # =======================
    # 取得（ポーリング用）
    # -----------------------
    # 戻り値: HTTParty::Response（結果は base64_encoded=true）
    # =======================
    def fetch(token)
      self.class.get(
        "#{@base}/submissions/#{token}?base64_encoded=true",
        headers: @headers
      ).tap { |res| raise_if_bad(res) }
    end

    # =======================
    # Ruby実行（submit→fetch を隠蔽）
    # -----------------------
    # 返却: 完了済みの結果JSON（stdout/stderr 等は Base64 デコード済）
    # status.id:
    #   1/2: 待機/実行中
    #   3以上: 完了
    #   -1: 内部的にタイムアウト（max_wait超過）
    # =======================
    def run_ruby(code, language_id: RUBY_LANG_ID, max_wait: 5.0, interval: 0.4)
      token = submit(source_code: code, language_id: language_id).parsed_response["token"]
      raise Error, "submit returns no token" if token.blank?

      waited = 0.0
      loop do
        res = fetch(token).parsed_response
        # Base64 項目を可読化
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
    # =======================
    # 共通: レスポンス妥当性チェック
    # =======================
    def raise_if_bad(res)
      unless res.code && res.code.between?(200, 299)
        detail = res.parsed_response.is_a?(Hash) ? res.parsed_response : res.body
        raise Error, "Judge0 HTTP #{res.code}: #{detail}"
      end
      res
    end

    # =======================
    # 共通: Base64 デコード
    # -----------------------
    # stdout / stderr / compile_output / message を対象
    # 失敗したら平文とみなしてそのまま
    # =======================
    def decode_base64_fields!(h)
      return h unless h.is_a?(Hash)
      %w[stdout stderr compile_output message].each do |k|
        v = h[k]
        next unless v.is_a?(String)
        begin
          h[k] = Base64.strict_decode64(v)
        rescue ArgumentError
          # すでに平文の可能性。無視して通す
        end
      end
      h
    end
  end
end
