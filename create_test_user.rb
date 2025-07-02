account = Account.first || Account.create!(name: 'Test Company')
user = account.users.where(email: 'test@example.com').first
unless user
  user = User.new(name: 'Test User', email: 'test@example.com', password: 'password123', confirmed_at: Time.now)
  user.save!(validate: false)
  account.account_users.create!(user: user, role: 'administrator')
end
# Create access token for user
access_token = AccessToken.where(owner: user).first
access_token = AccessToken.create!(owner: user) if access_token.nil?
puts 'Account ID: ' + account.id.to_s
puts 'User ID: ' + user.id.to_s
puts 'User email: ' + user.email
puts 'API Token: ' + access_token.token