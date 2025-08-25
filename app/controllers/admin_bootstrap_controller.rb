# app/controllers/admin_bootstrap_controller.rb
class AdminBootstrapController < ApplicationController
  before_action :require_login!

  # シンプルな入力フォーム（CSRF付き）
  def form
    # 何もせずビューを表示
  end

  # 昇格実行（POST）
  def promote_me
    token    = params[:token].to_s
    expected = ENV["ADMIN_PROMOTE_TOKEN"].to_s

    unless token.present? && secure_equal?(token, expected)
      redirect_to root_path, alert: "権限がありません" and return
    end

    current_user.update!(admin: true)

    # ここはプロジェクトに合わせて。adminダッシュボードがあるなら admin_root_path へ
    redirect_to (defined?(admin_root_path) ? admin_root_path : root_path),
                notice: "管理者になりました"
  end

  private

  def require_login!
    # 既存のログイン判定に合わせて調整（current_user が無ければログイン画面などへ）
    redirect_to (defined?(new_session_path) ? new_session_path : root_path),
                alert: "ログインしてください" unless current_user
  end

  # 時間一定比較で安全にトークンを照合
  def secure_equal?(a, b)
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(a),
      ::Digest::SHA256.hexdigest(b)
    )
  end
end
