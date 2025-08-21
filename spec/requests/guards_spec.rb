# spec/requests/guards_spec.rb
require "rails_helper"

RSpec.describe "Guards", type: :request do
  let(:owner) { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:me)    { create(:user,  password: "secret123", password_confirmation: "secret123") }
  let(:pc)    { create(:pre_code, user: owner) }

  #
  # 1) すでにログインしているのに /session/new へ行くと root に戻される
  #
  it "ログイン中に /session/new へ行くと root へ" do
    post session_path, params: { email: owner.email, password: "secret123" }
    get new_session_path
    expect(response).to redirect_to(root_path)
  end

  #
  # 2) CodeLibrary のガード
  #

  it "ゲストが Like をPOSTするとログイン画面へ" do
    post likes_path, params: { pre_code_id: pc.id }
    expect(response).to redirect_to(new_session_path)
  end

  it "ログイン済みは Like を作成できる" do
    sign_in(me)
    expect {
      post likes_path, params: { pre_code_id: pc.id }
    }.to change(Like, :count).by(1)
    expect(response).to have_http_status(:redirect).or have_http_status(:ok) # Turbo/HTMLどちらでもOK
  end

  it "自分の投稿は CodeLibrary の詳細で弾かれて pre_codes へリダイレクト" do
    sign_in(owner)
    get code_library_path(pc)
    expect(response).to redirect_to(pre_codes_path)
  end

  it "Like の削除は自分の Like のみ可能" do
    sign_in(me)
    my_like = create(:like, user: me, pre_code: pc)

    expect {
      delete like_path(my_like)
    }.to change(Like, :count).by(-1)

    # 他人の Like は 404（RecordNotFound → head :not_found）
    other_like = create(:like, user: owner, pre_code: pc)
    expect {
      delete like_path(other_like)
    }.not_to change(Like, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "ゲストが UsedCode をPOSTするとログイン画面へ" do
    post used_codes_path, params: { pre_code_id: pc.id }
    expect(response).to redirect_to(new_session_path)
  end

  it "ログイン済みは UsedCode を1件作成できる（重複作成なし）" do
    sign_in(me)
    expect {
      post used_codes_path, params: { pre_code_id: pc.id }
    }.to change(UsedCode, :count).by(1)

    # 2回目は find_or_create_by! により増えない
    expect {
      post used_codes_path, params: { pre_code_id: pc.id }
    }.not_to change(UsedCode, :count)
  end
end
