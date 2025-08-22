# spec/requests/editor_spec.rb
require "rails_helper"

RSpec.describe "Editor API", type: :request do
  describe "POST /editor" do
    let(:client) { instance_double(Judge0::Client) }

    before do
      allow(Judge0::Client).to receive(:new).and_return(client)
    end

    it "code を実行して結果(JSON)を返す（stdout は復号済みが返る前提）" do
      fake = {
        "status" => { "description" => "Accepted" },
        "stdout" => "2\n",
        "stderr" => nil,
        "time"   => "0.01",
        "memory" => 123,
        "token"  => "tok_123"
      }
      expect(client).to receive(:run_ruby).with("puts 1+1", language_id: 72).and_return(fake)

      post editor_path, params: { code: "puts 1+1", language_id: 72 }, as: :json
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("Accepted")
      expect(json["stdout"]).to eq("2\n")
      expect(json).to include("time", "memory", "token")
    end

    it "code が空なら 422 を返す" do
      post editor_path, params: { code: "" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error")
    end

    it "code が 200KB を超えると 422 を返す" do
      big = "a" * 200_001
      post editor_path, params: { code: big }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("error")
    end
  end

  describe "GET /pre_codes/:id/body" do
    let(:user) { create(:user) }
    let!(:pc)  { create(:pre_code, user:, title: "t", body: "p 'hi'") }

    it "対象の body を返す" do
      get pre_code_body_path(pc.id)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(pc.id)
      expect(json["title"]).to eq("t")
      expect(json["body"]).to eq("p 'hi'")
    end

    it "存在しない id は 404" do
      get pre_code_body_path(999_999)
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to include("error")
    end
  end
end
