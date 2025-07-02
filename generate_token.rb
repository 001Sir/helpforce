user = User.find_by(email: 'test@example.com')
if user
  token = AccessToken.create!(
    owner: user,
    token: SecureRandom.hex(16)
  )
  puts "New API Token: #{token.token}"
  puts "User ID: #{user.id}"
  account = user.accounts.first
  puts "Account ID: #{account.id}" if account
else
  puts 'User not found'
end