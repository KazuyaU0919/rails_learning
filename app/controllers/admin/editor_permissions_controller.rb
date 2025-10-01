# app/controllers/admin/editor_permissions_controller.rb
class Admin::EditorPermissionsController < Admin::BaseController
  layout "admin"

  before_action :set_permission, only: %i[show edit update destroy]

  # このコントローラで許可する対象タイプ（ホワイトリスト）
  TARGET_TYPES = %w[BookSection QuizQuestion].freeze

  def index
    @q_user_id    = params[:user_id]
    @q_type       = params[:target_type]
    @q_role       = params[:role]

    @perms = EditorPermission.includes(:user).order(created_at: :desc)
    @perms = @perms.where(user_id: @q_user_id) if @q_user_id.present?
    @perms = @perms.where(target_type: @q_type) if @q_type.present?
    @perms = @perms.where(role: @q_role)       if @q_role.present?
    @perms = @perms.page(params[:page])
  end

  def show; end
  def new;  @perm = EditorPermission.new; end
  def edit; end

  def create
    @perm = EditorPermission.new(perm_params)
    if @perm.save
      redirect_to admin_editor_permissions_path, notice: "編集権限を付与しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @perm.update(perm_params)
      redirect_to admin_editor_permission_path(@perm), notice: "編集権限を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @perm.destroy
    redirect_to admin_editor_permissions_path, notice: "編集権限を解除しました"
  end

  # ---------- 一括付与 ----------
  def bulk_new
    @perm = EditorPermission.new
  end

  def bulk_create
    # :role は受け取らない（サーバ側で固定）
    raw      = params.require(:editor_permission).permit(:user_id, :target_type)
    user_id  = Integer(raw[:user_id])
    type     = raw[:target_type].to_s

    # type のホワイトリスト検証
    unless TARGET_TYPES.include?(type)
      raise ActionController::BadRequest, "invalid target_type"
    end

    # role はフォーム値を無視して固定（sub_editor のみ）
    fixed_role = :sub_editor

    raw_ids = params[:target_ids_text].to_s
    ids     = raw_ids.scan(/\d+/).map(&:to_i).uniq

    created = []
    skipped = []

    EditorPermission.transaction do
      ids.each do |tid|
        rec = EditorPermission.find_or_initialize_by(user_id: user_id, target_type: type, target_id: tid)
        if rec.persisted?
          skipped << tid
        else
          rec.role = fixed_role
          rec.save!
          created << tid
        end
      end
    end

    msg = []
    msg << "作成: #{created.size}件(#{created.take(10).join(', ')}#{'…' if created.size > 10})" if created.any?
    msg << "重複スキップ: #{skipped.size}件" if skipped.any?
    redirect_to admin_editor_permissions_path, notice: msg.presence || "対象IDが指定されていません"
  rescue ArgumentError
    @perm = EditorPermission.new(user_id: raw[:user_id], target_type: type, role: fixed_role)
    flash.now[:alert] = "作成に失敗しました: invalid id"
    render :bulk_new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    @perm = EditorPermission.new(user_id: raw[:user_id], target_type: type, role: fixed_role)
    flash.now[:alert] = "作成に失敗しました: #{e.message}"
    render :bulk_new, status: :unprocessable_entity
  end

  # ---------- Ajax: ID → 人間向けラベル ----------
  def describe_target
    type = params[:target_type].to_s
    id   = params[:target_id].to_s

    label =
      if TARGET_TYPES.include?(type)
        case type
        when "BookSection"
          if (rec = BookSection.find_by(id: id))
            book = rec.try(:book)&.title
            sec  = rec.try(:heading) || rec.try(:title)
            [ "BookSection##{id}", [ book, sec ].compact.join(" / ") ].reject(&:blank?).join(" — ")
          end
        when "QuizQuestion"
          if (rec = QuizQuestion.find_by(id: id))
            quiz = rec.try(:quiz)&.title
            sect = rec.try(:quiz_section)&.heading
            qpos = rec.try(:position)
            [ "QuizQuestion##{id}", [ quiz, sect, ("Q#{qpos}" if qpos) ].compact.join(" / ") ].reject(&:blank?).join(" — ")
          end
        end
      end

    render json: { label: label.presence || "#{type}##{id}（見つかりません）" }
  end

  # ---------- Ajax: ユーザーのロール（admin/editor?） ----------
  def user_status
    u = User.find_by(id: params[:user_id])
    if u
      render json: {
        ok: true,
        admin:  u.admin?,
        editor: u.editor?,
        label:  (u.admin? ? "管理者" : (u.editor? ? "編集者" : nil))
      }
    else
      render json: { ok: false }
    end
  end

  private

  def set_permission
    @perm = EditorPermission.find(params[:id])
  end

  # Strong Parameters の“見た目”は保ちつつ、最終的に安全な固定値/型へ変換して返す
  def perm_params
    raw = params.require(:editor_permission).permit(:user_id, :target_type, :target_id)
    type = raw[:target_type].to_s

    # target_type はホワイトリストで厳格化
    raise ActionController::BadRequest, "invalid target_type" unless TARGET_TYPES.include?(type)

    {
      user_id: Integer(raw[:user_id]),
      target_type: type,
      target_id: Integer(raw[:target_id]),
      role: :sub_editor # ここで固定（フォーム値は無視）
    }
  rescue ArgumentError
    # Integer() 失敗時など
    raise ActionController::BadRequest, "invalid id"
  end
end
