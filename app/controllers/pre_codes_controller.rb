class PreCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: %i[show edit update destroy]

  # GET /pre_codes
  def index
    @pre_codes = current_user.pre_codes
                             .order(id: :desc)
                             .page(params[:page])
  end

  # GET /pre_codes/:id
  def show
  end

  # GET /pre_codes/new
  def new
    @pre_code = current_user.pre_codes.build
  end

  # POST /pre_codes
  def create
    @pre_code = current_user.pre_codes.build(pre_code_params)
    if @pre_code.save
      redirect_to @pre_code, notice: "PreCode を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /pre_codes/:id/edit
  def edit
  end

  # PATCH/PUT /pre_codes/:id
  def update
    if @pre_code.update(pre_code_params)
      redirect_to @pre_code, notice: "PreCode を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /pre_codes/:id
  def destroy
    @pre_code.destroy
    redirect_to pre_codes_path, notice: "PreCode を削除しました"
  end

  private

  # 所有者スコープで取得（他人のIDだと ActiveRecord::RecordNotFound → 404）
  def set_pre_code
    @pre_code = current_user.pre_codes.find(params[:id])
  end

  # Strong Parameters
  def pre_code_params
    params.require(:pre_code).permit(:title, :description, :body)
  end
end
