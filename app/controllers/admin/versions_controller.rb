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
  end

  def revert
    version = PaperTrail::Version.find(params[:id])
    record  = safe_reify(version)

    if record.nil?
      # create の巻き戻し = 現在存在するレコードを削除
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

  # ＝＝＝＝ 単体削除 ＝＝＝＝
  def destroy
    v = PaperTrail::Version.find(params[:id])
    v.destroy
    redirect_back fallback_location: admin_versions_path, notice: "版を削除しました"
  end

  # ＝＝＝＝ 一括削除 ＝＝＝＝
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
    # まず JSON (現行設定) でトライ
    version.reify
  rescue JSON::ParserError
    # YAML の可能性が高い → YAML serializer で再トライ
    PaperTrail.serializer = PaperTrail::Serializers::YAML
    begin
      version.reify
    ensure
      # 終わったら必ず JSON に戻す
      PaperTrail.serializer = PaperTrail::Serializers::JSON
    end
  rescue Psych::DisallowedClass
    permit_yaml_classes!
    retry
  end

  # 一時的に PaperTrail の serializer を YAML にしてブロックを実行
  def with_yaml_serializer
    PaperTrail.request do |req|
      prev = req.serializer
      req.serializer = PaperTrail::Serializers::YAML
      begin
        return yield
      ensure
        req.serializer = prev
      end
    end
  end

  # YAML 安全読み込みの許可クラスを追加
  def permit_yaml_classes!
    permitted = [
      Time, Date, Symbol,
      ActiveSupport::TimeZone,
      ActiveSupport::TimeWithZone
    ]
    if ActiveRecord.respond_to?(:yaml_column_permitted_classes)
      ActiveRecord.yaml_column_permitted_classes |= permitted
    end
  end

  def safe_model_for_item_type(item_type)
    type = item_type.to_s
    return nil unless ALLOWED_ITEM_TYPES.include?(type)
    type.safe_constantize
  end
end
