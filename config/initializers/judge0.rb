Rails.application.configure do
  config.x.judge0 = {
    base_url: ENV["JUDGE0_BASE_URL"],
    api_key:  ENV["JUDGE0_RAPIDAPI_KEY"],
    host_hdr: ENV["JUDGE0_HOST_HEADER"]
  }
end
