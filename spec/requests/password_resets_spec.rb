# spec/requests/password_resets_spec.rb
require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  let!(:user) { create(:user, email: "pw@example.com", password: "secret123", password_confirmation: "secret123") }
  let!(:oauth_user) { create(:google_user, email: "oauth@example.com") } # factory 側で provider/uid を持つ

  before { ActionMailer::Base.deliveries.clear }

  describe "POST /password_resets" do
    it "通常ユーザーならトークンを発行し、メール（test配信）を1通積む" do
      perform_enqueued_jobs do
        post password_resets_path, params: { email: user.email }
      end

      user.reload
      expect(user.reset_password_token).to be_present
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(response).to redirect_to(root_path)
    end

    it "外部ログインユーザーは何もしない（トークン発行もdeliveries増えない）" do
      perform_enqueued_jobs do
        post password_resets_path, params: { email: oauth_user.email }
      end

      oauth_user.reload
      expect(oauth_user.reset_password_token).to be_nil
      expect(ActionMailer::Base.deliveries.size).to eq(0)
      expect(response).to redirect_to(root_path)
    end

    it "存在しないメールでも同じレスポンス（情報漏えい防止）" do
      post password_resets_path, params: { email: "nobody@example.com" }
      expect(response).to redirect_to(root_path)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe "GET /password_resets/:token/edit" do
    it "有効トークンなら編集画面を表示できる" do
      post password_resets_path, params: { email: user.email }
      token = user.reload.reset_password_token
      get edit_password_reset_path(token)
      expect(response).to have_http_status(:ok)
    end

    it "期限切れトークンは編集画面に入れない" do
      post password_resets_path, params: { email: user.email }
      token = user.reload.reset_password_token
      travel_to 31.minutes.from_now do
        get edit_password_reset_path(token)
        expect(response).to redirect_to(new_password_reset_path)
        follow_redirect!
        expect(response.body).to include("トークンが無効です").or include("無効") # 文言合わせ
      end
    end
  end

  describe "PATCH /password_resets/:token" do
    before do
      post password_resets_path, params: { email: user.email }
      @token = user.reload.reset_password_token
    end

    it "有効トークンならパスワードを更新し、トークンはクリアされる" do
      patch password_reset_path(@token), params: {
        user: { password: "newsecret", password_confirmation: "newsecret" }
      }
      expect(response).to redirect_to(new_session_path)

      user.reload
      expect(user.authenticate("newsecret")).to be_truthy
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil
    end

    it "バリデーション NG なら 422 で再表示" do
      patch password_reset_path(@token), params: {
        user: { password: "short", password_confirmation: "mismatch" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("エラー").or include("error")
      # トークンはまだ生きている（再送信・やり直し可能）
      expect(user.reload.reset_password_token).to eq(@token)
    end

    it "期限切れなら更新できない" do
      travel_to 31.minutes.from_now do
        patch password_reset_path(@token), params: {
          user: { password: "newsecret", password_confirmation: "newsecret" }
        }
        expect(response).to redirect_to(new_password_reset_path)
        # 期限切れでも通常はトークンは残ったまま（UXにより設計可）
        expect(user.reload.reset_password_token).to eq(@token)
      end
    end
  end
end
