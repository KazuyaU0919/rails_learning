# ============================================================
# 管理: PaperTrail バージョン履歴
# ------------------------------------------------------------
# 対象: BookSection / QuizQuestion の変更履歴を管理画面で閲覧・復元。
#
# ■ 役割
# - 履歴一覧/詳細の表示
# - 任意の版へのロールバック（create/destroy/update それぞれの復元動作）
# - 版の削除/一括削除
#
# ■ セキュリティ & 安全性
# - 管理対象は ALLOWED_ITEM_TYPES でホワイトリスト化
# - reify 時の JSON/YAML 差異・非許可クラスに安全に対応 (safe_reify/permit_yaml_classes!)
# - ロールバック時は一時的に楽観ロックを解除 (toggle_lock) して保存整合を取りやすく
# ============================================================
class Admin::VersionsController < Admin::BaseController
  layout "admin"

  # -----------------------
  # 管理対象タイプのホワイトリスト
  # -----------------------
  ALLOWED_ITEM_TYPES = %w[BookSection QuizQuestion].freeze

  # =======================
  # 一覧
  # =======================
  def index
    versions = PaperTrail::Version.order(created_at: :desc)
    versions = versions.where(item_type: params[:item_type]) if params[:item_type].present?
    versions = versions.where(item_id:   params[:item_id])   if params[:item_id].present?
    @versions = versions.page(params[:page])
  end

  # =======================
  # 詳細
  # -----------------------
  # - @record: reify により該当版の直前状態（create のときは nil）
  # - @content_before, @content_after: 指定カラムの前後差分
  # =======================
  def show
    @version = PaperTrail::Version.find(params[:id])
    @record  = safe_reify(@version) # create のときは nil
    @content_before, @content_after = field_before_after(@version, :content)
  end

  # =======================
  # ロールバック（復元）
  # -----------------------
  # event に応じた復元手順:
  # - create   : 作成を取り消す（現在のレコードを削除）
  # - destroy  : 削除を取り消す（削除前状態を復活）
  # - update等 : その版の「更新前」状態で上書き保存
  # 失敗時は競合/エラーを画面に通知。
  # =======================
  def revert
    @version = PaperTrail::Version.find(params[:id])
    # reify は「その版の直前（before）」の状態
    record   = safe_reify(@version)

    begin
      case @version.event
      when "create"
        # 作成を取り消す => 現在のレコードを削除
        klass = safe_model_for_item_type(@version.item_type)
        klass.find_by(id: @version.item_id)&.destroy! if klass
        redirect_to admin_versions_path(item_type: @version.item_type, item_id: @version.item_id),
                    notice: "この作成を取り消しました（削除）"
        nil

      when "destroy"
        # 削除を取り消す => 削除前の状態を復活
        # destroy の reify は復活させたい完全オブジェクト
        raise ActiveRecord::RecordNotFound, "reify failed" unless record
        klass = record.class
        toggle_lock(klass, false) { record.save!(validate: false, touch: false) }
        redirect_to admin_versions_path(item_type: @version.item_type, item_id: @version.item_id),
                    notice: "削除前の版に復元しました"
        nil

      else # "update" など
        # その版の「更新前」の内容で上書き
        raise ActiveRecord::RecordNotFound, "reify failed" unless record
        klass = record.class
        toggle_lock(klass, false) { record.save!(validate: false, touch: false) }
        redirect_to admin_versions_path(item_type: @version.item_type, item_id: @version.item_id),
                    notice: "この版にロールバックしました"
        nil
      end

    rescue ActiveRecord::StaleObjectError
      redirect_back fallback_location: admin_versions_path,
                    alert: "ロールバック中に他の変更と競合しました。もう一度お試しください。"
    rescue => e
      redirect_back fallback_location: admin_versions_path,
                    alert: "ロールバックに失敗しました: #{e.message}"
    end
  end

  # =======================
  # 削除
  # =======================
  def destroy
    v = PaperTrail::Version.find(params[:id])
    v.destroy
    redirect_back fallback_location: admin_versions_path, notice: "版を削除しました"
  end

  # =======================
  # 一括削除
  # =======================
  def bulk_destroy
    ids = Array(params[:version_ids]).map(&:to_i).uniq
    if ids.empty?
      redirect_back fallback_location: admin_versions_path, alert: "削除対象が選択されていません"
      return
    end
    PaperTrail::Version.where(id: ids).in_batches { |rel| rel.delete_all }
    redirect_back fallback_location: admin_versions_path, notice: "#{ids.size}件の版を削除しました"
  end

  private

  # =======================
  # 楽観ロックの ON/OFF を一時的に切替
  # -----------------------
  # PaperTrail の reify 結果を保存する際、lock_version の競合を避けやすくする。
  # =======================
  def toggle_lock(klass, enable)
    prev = klass.lock_optimistically
    klass.lock_optimistically = enable
    yield
  ensure
    klass.lock_optimistically = prev
  end

  # =======================
  # 安全な reify
  # -----------------------
  # JSON/Psych 例外に対処しつつ YAML へフォールバック。
  # YAMLの非許可クラスは permit_yaml_classes! で許可拡張してから retry。
  # =======================
  def safe_reify(version)
    version.reify
  rescue JSON::ParserError
    PaperTrail.serializer = PaperTrail::Serializers::YAML
    begin
      version.reify
    ensure
      PaperTrail.serializer = PaperTrail::Serializers::JSON
    end
  rescue Psych::DisallowedClass
    permit_yaml_classes!
    retry
  end

  # =======================
  # YAML 復元で必要なクラスを明示許可
  # =======================
  def permit_yaml_classes!
    permitted = [ Time, Date, Symbol, ActiveSupport::TimeZone, ActiveSupport::TimeWithZone ]
    if ActiveRecord.respond_to?(:yaml_column_permitted_classes)
      ActiveRecord.yaml_column_permitted_classes |= permitted
    end
  end

  # =======================
  # item_type → モデルの安全解決
  # -----------------------
  # 管理対象以外は nil を返し保守性を担保。
  # =======================
  def safe_model_for_item_type(item_type)
    type = item_type.to_s
    return nil unless ALLOWED_ITEM_TYPES.include?(type)
    type.safe_constantize
  end

  # =======================
  # 指定カラムの before/after を再構築
  # -----------------------
  # changeset に無い場合でも reify を使って推定する。
  # - update  : before/after を双方 reify から取得
  # - create  : before=nil, after=現在(+next版)
  # - destroy : before=削除前, after=nil
  # =======================
  def field_before_after(version, column)
    col = column.to_s
    cs  = version.changeset || {}
    return cs[col] if cs.key?(col)

    if version.event == "update"
      before_rec = safe_reify(version)
      after_rec  = version.next ? safe_reify(version.next) : version.item_type.constantize.find_by(id: version.item_id)
      [ before_rec&.public_send(col), after_rec&.public_send(col) ]
    elsif version.event == "create"
      after_rec = version.next ? safe_reify(version.next) : version.item_type.constantize.find_by(id: version.item_id)
      [ nil, after_rec&.public_send(col) ]
    elsif version.event == "destroy"
      before_rec = safe_reify(version)
      [ before_rec&.public_send(col), nil ]
    else
      [ nil, nil ]
    end
  rescue
    [ nil, nil ]
  end
end
