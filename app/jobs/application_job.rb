# ============================================================
# Base Job
# ------------------------------------------------------------
# 全ての ActiveJob の親クラス。
# 各ジョブ共通設定をここに定義。
# ============================================================
class ApplicationJob < ActiveJob::Base
  # Deadlock 時の再試行設定例（無効化中）
  # retry_on ActiveRecord::Deadlocked

  # レコード消滅時など無視してよい例外設定（無効化中）
  # discard_on ActiveJob::DeserializationError
end
