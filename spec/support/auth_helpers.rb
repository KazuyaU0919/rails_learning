# spec/support/auth_helpers.rb
# リクエストスペック用: アプリの SessionsController#create に合わせて
# ルート（/session, /login など）とパラメータ形（トップレベル/ネスト）を自動判別してログインします。
module AuthHelpers
  # 既存スペック互換:
  #   sign_in(user, password: "secret123")
  # 追加シンタックス:
  #   sign_in_as(user, password: "secret")
  def sign_in(user = nil, password: nil, as: nil)
    user ||= as
    raise ArgumentError, "user を指定してください" unless user

    path = resolve_login_path

    # 試すパスワード候補（与えられた値 → "secret" → "secret123"）
    pw_candidates = [ password, "secret", "secret123" ].compact.uniq

    success = false
    pw_candidates.each do |pw|
      # まずはトップレベル { email, password } を試す
      post path, params: { email: user.email, password: pw }
      if login_failed?
        # ネスト { session: { email, password } } も試す
        post path, params: { session: { email: user.email, password: pw } }
      end
      unless login_failed?
        success = true
        follow_redirect! if response.redirect?
        break
      end
    end

    raise "sign_in failed: check login path & params (path=#{path})" unless success
  end
  alias_method :sign_in_as, :sign_in

  private

  # ルーティングの違いに備えて候補順に探す
  def resolve_login_path
    candidates = [
      (respond_to?(:session_path)      ? session_path      : nil),
      (respond_to?(:login_path)        ? login_path        : nil),
      (respond_to?(:sign_in_path)      ? sign_in_path      : nil),
      (respond_to?(:user_session_path) ? user_session_path : nil) # Devise 互換
    ].compact
    return candidates.first if candidates.any?
    "/session" # フォールバック
  end

  # ログイン失敗っぽいか簡易判定（フォームが再表示されている等）
  def login_failed?
    (response.status.in?([ 200, 422 ])) && (
      response.body.include?("ログイン") ||
      response.body.include?("Login") ||
      response.body.include?("メールアドレス") ||
      response.body.include?("password")
    )
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
