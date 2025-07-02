namespace :admin do
  desc "Create a super admin account"
  task create: :environment do
    email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    password = ENV['ADMIN_PASSWORD'] || 'Password1!'
    name = ENV['ADMIN_NAME'] || 'Admin'
    
    puts "Creating SuperAdmin account..."
    
    user = User.new(
      name: name,
      email: email,
      password: password,
      type: 'SuperAdmin'
    )
    user.skip_confirmation!
    
    if user.save
      puts "✅ SuperAdmin created successfully!"
      puts "Email: #{email}"
      puts "Password: #{password}"
      
      # Create a default account
      account = Account.create!(name: 'Default Company')
      AccountUser.create!(
        account_id: account.id,
        user_id: user.id,
        role: 'administrator'
      )
      puts "✅ Default account created and linked!"
    else
      puts "❌ Failed to create SuperAdmin:"
      puts user.errors.full_messages.join(", ")
    end
  end
end