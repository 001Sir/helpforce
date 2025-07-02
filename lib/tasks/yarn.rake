# Ensure yarn is available for asset compilation
Rake::Task['assets:precompile'].enhance ['yarn:install'] if ENV['RAILS_ENV'] == 'production'
Rake::Task['assets:precompile'].enhance ['vite:set_node_options'] if ENV['RAILS_ENV'] == 'production'

namespace :yarn do
  desc 'Install dependencies with yarn'
  task :install do
    puts 'Installing dependencies with yarn...'
    
    if system('which yarn > /dev/null 2>&1')
      # Run yarn install
      system('yarn install --frozen-lockfile') || system('yarn install') || raise('Failed to install dependencies')
      puts 'Dependencies installed successfully with yarn'
    else
      puts 'ERROR: yarn is not available'
      raise('yarn is required but not found')
    end
  end
end

namespace :vite do
  desc 'Set Node.js memory options'
  task :set_node_options do
    ENV['NODE_OPTIONS'] = '--max_old_space_size=2048'
    puts 'Node.js memory limit set to 2GB'
  end
end