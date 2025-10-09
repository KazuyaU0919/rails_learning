# app/jobs/hourly_digest_job.rb
class HourlyDigestJob < ApplicationJob
  queue_as :default

  # デフォルトは「直前1時間」。任意ウィンドウ指定も可。
  # perform(window_start: t1, window_end: t2)
  def perform(window_start: nil, window_end: nil)
    window_end   ||= 1.hour.ago.end_of_hour
    window_start ||= 1.hour.ago.beginning_of_hour

    send_edits_digest(window_start:, window_end:)
    send_contact_digest(window_start:, window_end:)
  end

  private

  def send_edits_digest(window_start:, window_end:)
    versions = PaperTrail::Version
                 .where(event: "update", created_at: window_start..window_end)
                 .where(item_type: %w[BookSection QuizQuestion])
                 .order(:created_at)

    return if versions.blank?

    edits = versions.map do |v|
      user  = user_from_whodunnit(v.whodunnit)
      title = title_for(v.item_type, v.item_id)
      { at: v.created_at, user:, item_type: v.item_type, item_id: v.item_id, title: }
    end

    AdminDigestMailer.edits_digest(
      edits:, window_start:, window_end:
    ).deliver_now
  end

  def user_from_whodunnit(whodunnit)
    uid = whodunnit.to_s
    return nil if uid.blank? || uid !~ /\A\d+\z/
    User.find_by(id: uid.to_i)
  end

  def title_for(item_type, item_id)
    case item_type
    when "BookSection"  then BookSection.where(id: item_id).pick(:heading)
    when "QuizQuestion" then QuizQuestion.includes(:quiz_section).find_by(id: item_id)&.quiz_section&.heading
    else nil
    end
  rescue StandardError
    nil
  end

  def send_contact_digest(window_start:, window_end:)
    count = fetch_google_form_count(window_start:, window_end:)
    return if count == 0 # 件数 0 は送らない（nil=不明は送る）
    AdminDigestMailer.contact_digest(count:, window_start:, window_end:).deliver_now
  end

  def fetch_google_form_count(window_start:, window_end:)
    url = ENV["GOOGLE_FORM_COUNT_URL"].to_s
    return nil if url.blank?

    require "net/http"
    require "uri"
    uri = URI.parse(url)
    res = Net::HTTP.get_response(uri)
    return nil unless res.is_a?(Net::HTTPSuccess)
    json = JSON.parse(res.body) rescue {}
    (json["count"] || json[:count]).to_i
  rescue StandardError
    nil
  end
end
