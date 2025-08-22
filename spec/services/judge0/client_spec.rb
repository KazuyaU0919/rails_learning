# spec/services/judge0/client_spec.rb
require "rails_helper"

RSpec.describe Judge0::Client do
  describe "#run_ruby" do
    it "submit→fetch を呼んで結果を返す (HTTParty をスタブ)" do
      client = described_class.new

      submit_res = instance_double(
        HTTParty::Response,
        code: 201,
        parsed_response: { "token" => "tok" }
      )

      fetch_res = instance_double(
        HTTParty::Response,
        code: 200,
        parsed_response: {
          "status" => { "id" => 3, "description" => "Accepted" },
          "stdout" => "OK\n"
        }
      )

      allow(described_class).to receive(:post).and_return(submit_res)
      allow(described_class).to receive(:get).and_return(fetch_res)
      allow(client).to receive(:sleep)              # ループ高速化

      res = client.run_ruby("puts 'OK'")

      expect(res.dig("status", "description")).to eq("Accepted")
      expect(res["stdout"]).to eq("OK\n")
    end
  end
end
