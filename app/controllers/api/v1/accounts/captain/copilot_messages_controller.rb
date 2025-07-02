# frozen_string_literal: true

class Api::V1::Accounts::Captain::CopilotMessagesController < Api::V1::Accounts::BaseController
  include EnterpriseFeatures

  before_action :current_account
  before_action :ensure_captain_ai_enabled
  before_action :set_copilot_thread

  def index
    @copilot_messages = @copilot_thread
                        .copilot_messages
                        .includes(:copilot_thread)
                        .order(created_at: :asc)
                        .page(permitted_params[:page] || 1)
                        .per(1000)
  end

  def create
    @copilot_message = @copilot_thread.copilot_messages.create!(
      message: { content: params[:message] },
      message_type: :user
    )
    @copilot_message.enqueue_response_job(params[:conversation_id], Current.user.id)
  end

  private

  def ensure_captain_ai_enabled
    render json: { error: 'Captain AI not available' }, status: :forbidden unless has_captain_ai?
  end

  def set_copilot_thread
    @copilot_thread = Current.account.copilot_threads.find_by!(
      id: params[:copilot_thread_id],
      user: Current.user
    )
  end

  def permitted_params
    params.permit(:page)
  end
end