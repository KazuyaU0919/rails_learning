# lib/tasks/users.rake
# ============================================================
# 目的:
#   同一メールアドレスで複数ユーザーが存在する場合に、最古の1件へ統合する。
#   - 関連（pre_codes / likes / used_codes）の user_id を付け替え
#   - authentications は (provider, uid) の一意制約を考慮して移行
#   - どちらかが admin の場合は keep 側を admin に昇格
#   - 重複ユーザー本体は削除
#
# 安全策:
#   既定は DRY RUN（ログ出力のみ）。適用する場合は EXECUTE=1 を指定。
#
# 実行例:
#   bin/rails users:merge_duplicates            # DRY RUN
#   EXECUTE=1 bin/rails users:merge_duplicates  # 実行
#
# 注意:
#   ここでは処理手順の定義のみ。実際の整合性はモデル側の制約・
#   トランザクションで担保する。
# ============================================================

namespace :users do
  # =======================
  # 重複ユーザー統合（DRY RUN 既定）
  # =======================
  desc "同一メールの重複ユーザーを1つに統合（DRY RUN。適用時は EXECUTE=1）"
  task merge_duplicates: :environment do
    dry = ENV["EXECUTE"] != "1"
    log = ->(msg) { puts msg }

    # -----------------------
    # 重複メールの抽出（lower(email) でグループ化）
    # -----------------------
    emails = User.group("lower(email)").having("count(*) > 1")
                 .pluck(Arel.sql("lower(email)"))

    emails.each do |email_lc|
      User.transaction do
        # 古い順に並べ、先頭を keep（残す）、以降を dups（削除対象）
        users = User.lock.where("lower(email) = ?", email_lc).order(:id)
        keep  = users.first
        dups  = users.offset(1)

        log.call "[#{email_lc}] keep=#{keep.id}, duplicates=#{dups.size}"

        dups.find_each do |dupe|
          # =======================
          # 1) 子テーブルのFKを keep に付け替え
          #    - バリデーションは通さず update_all を使用（大量移行を想定）
          # =======================
          {
            pre_codes:   dupe.pre_codes,
            likes:       dupe.likes,
            used_codes:  dupe.used_codes
          }.each do |name, rel|
            if dry
              log.call "  would move #{name}(#{rel.count}) user_id: #{dupe.id} -> #{keep.id}"
            else
              rel.update_all(user_id: keep.id)
            end
          end

          # =======================
          # 2) authentications の移行（(provider, uid) で一意）
          #    - keep 側に同一キーがある場合はスキップ
          # =======================
          dupe.authentications.find_each do |a|
            if keep.authentications.exists?(provider: a.provider, uid: a.uid)
              log.call "  skip auth #{a.provider}/#{a.uid} (already on keep)"
            else
              if dry
                log.call "  would move auth #{a.provider}/#{a.uid} -> keep"
              else
                a.update!(user_id: keep.id)
              end
            end
          end

          # =======================
          # 3) 片方が admin の場合は keep を admin に昇格
          # =======================
          if dupe.admin? && !keep.admin?
            if dry
              log.call "  would promote keep(#{keep.id}) to admin"
            else
              keep.update!(admin: true)
            end
          end

          # =======================
          # 4) 重複ユーザー本体の削除
          # =======================
          if dry
            log.call "  would destroy user #{dupe.id}"
          else
            dupe.destroy!
          end
        end
      end
    end

    log.call(dry ? "DRY RUN 完了（EXECUTE=1 で適用）" : "統合作業 完了")
  end
end
