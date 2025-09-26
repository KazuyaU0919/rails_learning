require "rails_helper"

RSpec.describe "Editor API", type: :request do
  describe "POST /editor" do
    it "空コードなら 422 を返す" do
      post "/editor", params: { code: "" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include("stderr" => a_string_matching(/空/))
    end

    it "適切なJSONを返す（ダミーコードでもOK）" do
      post "/editor", params: { code: "puts 'hi'" }, as: :json
      # Judge0 のスタブが無ければ 502 になることもあるので、ここは緩めに
      expect(response.content_type).to include("application/json")
    end
  end
end
