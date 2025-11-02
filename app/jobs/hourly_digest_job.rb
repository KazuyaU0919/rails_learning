# ============================================================
# Job: HourlyDigestJob
# ------------------------------------------------------------
# 毎時実行される通知ジョブ。
# 対象:
# - PaperTrail の更新履歴（update）
# - Googleフォームからの問い合わせ集計
# 結果は AdminDigestMailer 経由で管理者へ通知。
# ============================================================
class HourlyDigestJob < ApplicationJob
  queue_as :default

  # =======================
  # 実行処理（メイン）
  # -----------------------
  # 引数:
  #   window_start / window_end : 対象時間範囲
  # =======================
  def perform(window_start: nil, window_end: nil)
    window_end   ||= 1.hour.ago.end_of_hour
    window_start ||= 1.hour.ago.beginning_of_hour
    send_edits_digest(window_start:, window_end:)
    send_contact_digest(window_start:, window_end:)
  end

  private

  # =======================
  # PaperTrail 更新通知メール
  # =======================
  def send_edits_digest(window_start:, window_end:)
    require "paper_trail"

    # 予防線：クラス解決（PaperTrail::Version が無ければ ::Version を試す）
    version_klass = if defined?(PaperTrail::Version)
      PaperTrail::Version
    elsif defined?(::Version)
      ::Version
    else
      # どちらも無ければ処理不能なので静かに終了（ログにヒントを残す）
      Rails.logger.warn("[HourlyDigestJob] Version model not found (PaperTrail::Version / ::Version). Skipped.")
      return
    end

    versions = version_klass
                .where(event: "update", created_at: window_start..window_end)
                .where(item_type: %w[BookSection QuizQuestion])
                .order(:created_at)

    return if versions.blank?

    edits = versions.map do |v|
      user  = user_from_whodunnit(v.whodunnit)
      title = title_for(v.item_type, v.item_id)
      { at: v.created_at, user:, item_type: v.item_type, item_id: v.item_id, title: }
    end

    AdminDigestMailer.edits_digest(edits:, window_start:, window_end:).deliver_now
  end

  # 操作者ユーザーを whodunnit から取得
  def user_from_whodunnit(whodunnit)
    uid = whodunnit.to_s
    return nil if uid.blank? || uid !~ /\A\d+\z/
    User.find_by(id: uid.to_i)
  end

  # 対象のタイトルを item_type に応じて取得
  def title_for(item_type, item_id)
    case item_type
    when "BookSection"  then BookSection.where(id: item_id).pick(:heading)
    when "QuizQuestion" then QuizQuestion.includes(:quiz_section).find_by(id: item_id)&.quiz_section&.heading
    else nil
    end
  rescue
    nil
  end

  # =======================
  # Googleフォーム集計通知メール
  # =======================
  def send_contact_digest(window_start:, window_end:)
    count = fetch_google_form_count(window_start:, window_end:)
    return if count.to_i == 0
    AdminDigestMailer.contact_digest(count:, window_start:, window_end:).deliver_now
  end

  # Googleフォームの集計結果取得
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
  rescue
    nil
  end
end
