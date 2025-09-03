# spec/requests/pre_codes_spec.rb
require "rails_helper"

RSpec.describe "PreCodes", type: :request do
  let(:user)      { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:other_user) { create(:user, password: "secret123", password_confirmation: "secret123") }

  describe "ガードと所有チェック" do
    it "未ログインで /pre_codes にアクセスするとログイン画面へ" do
      get pre_codes_path
      expect(response).to redirect_to(new_session_path)
    end

    it "ログイン後 /pre_codes は200で、自分のレコードだけが表示される" do
      mine_pre_codes = create_list(:pre_code, 2, user:, title: "mine")
      others_pre     = create(:pre_code, user: other_user, title: "others")

      sign_in(user)
      get pre_codes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("mine")
      expect(response.body).not_to include("others")
    end

    it "他人の /pre_codes/:id を叩ききると 404 を返す" do
      record = create(:pre_code, user: other_user)
      sign_in(user)
      get pre_code_path(record)
      expect(response).to have_http_status(:not_found)
      # もし実装で index にリダイレクトしているなら下を使う
      # expect(response).to redirect_to(pre_codes_path)
    end
  end

  describe "バリデーション失敗時の再描画" do
    before { sign_in(user) }

    it "new → create 失敗で 422 とエラー表示" do
      post pre_codes_path, params: { pre_code: { title: "", body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("error").or include("エラー").or include("invalid")
    end

    it "edit → update 失敗で 422 とエラー表示" do
      rec = create(:pre_code, user:)
      patch pre_code_path(rec), params: { pre_code: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "ページネーション" do
    before { sign_in(user) }

    it "index はページネーションされる" do
      # Kaminari デフォルト 25件想定。26件作って2ページ目を発生させる
      create_list(:pre_code, 26, user:, title: "p")

      # 1ページ目には「次へ」が出るはず
      get pre_codes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('rel="next"')

      # 2ページ目には「前へ」が出るはず
      get pre_codes_path(page: 2)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('rel="prev"')
    end
  end
end
