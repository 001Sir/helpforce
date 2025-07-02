# frozen_string_literal: true

class Api::V1::Accounts::Captain::CopilotThreadsController < Api::V1::Accounts::BaseController
  include EnterpriseFeatures

  before_action :current_account
  before_action :ensure_captain_ai_enabled
  before_action :ensure_message, only: :create

  def index
    @copilot_threads = Current.account.copilot_threads
                              .where(user_id: Current.user.id)
                              .includes(:user, :assistant)
                              .order(created_at: :desc)
                              .page(permitted_params[:page] || 1)
                              .per(5)
  end

  def create
    ActiveRecord::Base.transaction do
      @copilot_thread = Current.account.copilot_threads.create!(
        title: copilot_thread_params[:message],
        user: Current.user,
        assistant: assistant
      )

      copilot_message = @copilot_thread.copilot_messages.create!(
        message_type: :user,
        message: { content: copilot_thread_params[:message] }
      )

      build_copilot_response(copilot_message)
    end
  end

  private

  def ensure_captain_ai_enabled
    render json: { error: 'Captain AI not available' }, status: :forbidden unless has_captain_ai?
  end

  def build_copilot_response(copilot_message)
    # Simplified version without usage limits for now
    copilot_message.enqueue_response_job(copilot_thread_params[:conversation_id], Current.user.id)
  end

  def ensure_message
    return render_could_not_create_error(I18n.t('captain.copilot_message_required')) if copilot_thread_params[:message].blank?
  end

  def assistant
    Current.account.captain_assistants.find(copilot_thread_params[:assistant_id])
  end

  def copilot_thread_params
    params.permit(:message, :assistant_id, :conversation_id)
  end

  def permitted_params
    params.permit(:page)
  end
end