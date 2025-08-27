# lib/tasks/users.rake
namespace :users do
  desc "同一メールの重複ユーザーを1つに統合（DRY RUN。適用したいときは EXECUTE=1 を付ける）"
  task merge_duplicates: :environment do
    dry = ENV["EXECUTE"] != "1"
    log = ->(msg) { puts msg }

    # lower(email) でグルーピングし、2件以上あるメールのみ対象
    emails = User.group("lower(email)").having("count(*) > 1")
                 .pluck(Arel.sql("lower(email)"))

    emails.each do |email_lc|
      User.transaction do
        users = User.lock.where("lower(email) = ?", email_lc).order(:id) # 古い順に
        keep  = users.first
        dups  = users.offset(1)

        log.call "[#{email_lc}] keep=#{keep.id}, duplicates=#{dups.size}"

        dups.find_each do |dupe|
          # ---- 子テーブルのFKを keep に付け替え（バリデーションを通さない update_all） ----
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

          # ---- authentications は [provider,uid] 一意制約があるので衝突回避しつつ移行 ----
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

          # ---- 片方が admin なら keep を admin に昇格 ----
          if dupe.admin? && !keep.admin?
            if dry
              log.call "  would promote keep(#{keep.id}) to admin"
            else
              keep.update!(admin: true)
            end
          end

          # ---- 重複ユーザー本体を削除 ----
          if dry
            log.call "  would destroy user #{dupe.id}"
          else
            dupe.destroy!
          end
        end
      end
    end

    log.call dry ? "DRY RUN 完了（EXECUTE=1 で適用）" : "統合作業 完了"
  end
end
