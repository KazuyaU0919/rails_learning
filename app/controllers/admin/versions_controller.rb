# app/controllers/admin/versions_controller.rb
class Admin::VersionsController < Admin::BaseController
  layout "admin"

  ALLOWED_ITEM_TYPES = %w[BookSection QuizQuestion].freeze

  def index
    versions = PaperTrail::Version.order(created_at: :desc)
    versions = versions.where(item_type: params[:item_type]) if params[:item_type].present?
    versions = versions.where(item_id:   params[:item_id])   if params[:item_id].present?
    @versions = versions.page(params[:page])
  end

  def show
    @version = PaperTrail::Version.find(params[:id])
    @record  = safe_reify(@version) # create のときは nil
    @content_before, @content_after = field_before_after(@version, :content)
  end

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

  def destroy
    v = PaperTrail::Version.find(params[:id])
    v.destroy
    redirect_back fallback_location: admin_versions_path, notice: "版を削除しました"
  end

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

  # 楽観ロックの ON/OFF を一時的に切り替えるユーティリティ
  def toggle_lock(klass, enable)
    prev = klass.lock_optimistically
    klass.lock_optimistically = enable
    yield
  ensure
    klass.lock_optimistically = prev
  end

  # YAML/JSON どちらでも安全に reify する
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

  def permit_yaml_classes!
    permitted = [ Time, Date, Symbol, ActiveSupport::TimeZone, ActiveSupport::TimeWithZone ]
    if ActiveRecord.respond_to?(:yaml_column_permitted_classes)
      ActiveRecord.yaml_column_permitted_classes |= permitted
    end
  end

  def safe_model_for_item_type(item_type)
    type = item_type.to_s
    return nil unless ALLOWED_ITEM_TYPES.include?(type)
    type.safe_constantize
  end

  # ---- 指定カラムの before/after を、changeset に無い場合でも再構築 ----
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
