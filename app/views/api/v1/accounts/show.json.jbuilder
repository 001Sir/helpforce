json.partial! 'api/v1/models/account', formats: [:json], resource: @account
json.latest_worqchat_version @latest_worqchat_version
json.partial! 'enterprise/api/v1/accounts/partials/account', account: @account if WorqChatApp.enterprise?
