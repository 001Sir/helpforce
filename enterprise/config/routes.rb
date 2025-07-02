# frozen_string_literal: true

namespace :api, defaults: { format: 'json' } do
  namespace :v1 do
    resources :accounts, only: [] do
      namespace :captain do
        resources :assistants do
          resources :assistant_responses, path: 'responses'
        end
        resources :documents
        resources :inboxes
        resources :copilot_threads, path: 'copilot/threads' do
          resources :copilot_messages, path: 'messages'
        end
        resources :bulk_actions, only: [:create]
      end

      resources :sla_policies do
        member do
          get :metrics
        end
      end

      resources :applied_slas, only: [:index, :show] do
        collection do
          get :metrics
          get :download
        end
      end

      resources :custom_roles
      resources :audit_logs, only: [:show]
    end
  end
end