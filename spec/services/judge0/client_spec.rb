# spec/services/judge0/client_spec.rb
require "rails_helper"
require "base64"

RSpec.describe Judge0::Client do
  describe "#run_ruby" do
    it "submit→fetch を呼び、Base64 フィールドを復号して結果を返す" do
      client = described_class.new

      submit_res = instance_double(
        HTTParty::Response,
        code: 201,
        parsed_response: { "token" => "tok" }
      )

      # Judge0 からの fetch が Base64 で返ってくるケースを模擬
      encoded_stdout = Base64.strict_encode64("OK\n")
      fetch_res = instance_double(
        HTTParty::Response,
        code: 200,
        parsed_response: {
          "status"  => { "id" => 3, "description" => "Accepted" },
          "stdout"  => encoded_stdout,
          "stderr"  => nil,
          "message" => nil
        }
      )

      allow(described_class).to receive(:post).and_return(submit_res)
      allow(described_class).to receive(:get).and_return(fetch_res)
      allow(client).to receive(:sleep) # ループ高速化

      res = client.run_ruby("puts 'OK'")

      expect(res.dig("status", "description")).to eq("Accepted")
      expect(res["stdout"]).to eq("OK\n")  # ← 復号されていること
    end
  end
end
