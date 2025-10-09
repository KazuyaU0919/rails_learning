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

    # BookSection 用 fallback（changesetにcontentが無くても拾う）
    @content_before, @content_after = field_before_after(@version, :content)
  end

  def revert
    version = PaperTrail::Version.find(params[:id])
    record  = safe_reify(version)

    if record.nil?
      model_klass = safe_model_for_item_type(version.item_type)
      if model_klass
        model_klass.find_by(id: version.item_id)&.destroy!
      end
      redirect_to admin_versions_path(item_type: version.item_type, item_id: version.item_id),
                  notice: "この作成を取り消しました（削除）"
      return
    end

    record.save!
    redirect_to admin_versions_path(item_type: version.item_type, item_id: version.item_id),
                notice: "この版にロールバックしました"
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
    if cs.key?(col)
      before, after = cs[col]
      return [ before, after ]
    end

    # update: reify が「更新前」。現在（または next 版の reify）が「更新後」
    if version.event == "update"
      before_rec = safe_reify(version)
      after_rec  = version.next ? safe_reify(version.next) : version.item_type.constantize.find_by(id: version.item_id)
      return [ before_rec&.public_send(col), after_rec&.public_send(col) ]
    end

    # create: after のみ
    if version.event == "create"
      after_rec = version.next ? safe_reify(version.next) : version.item_type.constantize.find_by(id: version.item_id)
      return [ nil, after_rec&.public_send(col) ]
    end

    # destroy: before のみ
    if version.event == "destroy"
      before_rec = safe_reify(version)
      return [ before_rec&.public_send(col), nil ]
    end

    [ nil, nil ]
  rescue
    [ nil, nil ]
  end
end
