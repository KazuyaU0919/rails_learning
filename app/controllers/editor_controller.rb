# app/controllers/editor_controller.rb
class EditorController < ApplicationController
  def index
    head :ok
  end

  def create
    head :ok
  end

  def pre_code_body
    render json: { id: params[:id].to_i, title: "stub", body: "" }
  end
end
