class OmniauthCallbacksController < ApplicationController
  def create
    auth = request.env["omniauth.auth"] # OmniAuthが入れてくれる認証情報

    user = User.find_or_initialize_by(provider: auth["provider"], uid: auth["uid"])
    if user.new_record?
      user.name  = auth.dig("info", "name") || auth.dig("info", "nickname") || "No Name"
      # GitHub は email が返らないことがあるのでフォールバックを用意
      user.email = auth.dig("info", "email").presence || "#{auth['uid']}@#{auth['provider']}.example"
      # 外部ログインのみのユーザはパスワード不要。has_secure_passwordならダミーを入れておく
      user.password = SecureRandom.hex(16)
      user.save!
    end

    session[:user_id] = user.id
    redirect_to root_path, notice: "ログインしました"
  rescue => e
    Rails.logger.error("[OmniAuth] callback error: #{e.class} #{e.message}")
    redirect_to root_path, alert: "外部ログインに失敗しました"
  end

  def failure
    redirect_to root_path, alert: (params[:message] || "外部ログインがキャンセルされました")
  end
end
