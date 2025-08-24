# spec/requests/admin/authorization_smoke_spec.rb
require "rails_helper"

RSpec.describe "Admin Authorization", type: :request do
  let(:user)  { create(:user, admin: false) }
  let(:admin) { create(:user, admin: true)  }

  # /admin 配下で最低限チェックしたいURLをここに並べる
  ADMIN_PATH_HELPERS = %i[
    admin_root_path
    admin_books_path
    admin_book_sections_path
  ].freeze

  ADMIN_PATH_HELPERS.each do |path_helper|
    describe "#{path_helper}" do
      it "非adminはアクセスできずリダイレクトされる" do
        sign_in_as(user)
        get public_send(path_helper)

        # 302 → root へ
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)

        # フラッシュやログイン促し等の文言（環境差があるので緩めに判定）
        follow_redirect!
        expect(response.body).to match(/(管理|権限|ログイン)/)
      end

      it "admin はアクセスできる" do
        sign_in_as(admin)
        get public_send(path_helper)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
