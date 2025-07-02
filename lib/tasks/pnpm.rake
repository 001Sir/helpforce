# Install pnpm before asset compilation
Rake::Task['assets:precompile'].enhance ['pnpm:install'] if ENV['RAILS_ENV'] == 'production'

namespace :pnpm do
  desc 'Install pnpm'
  task :install do
    puts 'Installing pnpm...'
    # Check if npm is available
    if system('which npm > /dev/null 2>&1')
      system('npm install -g pnpm@10.2.0') || puts('Warning: Failed to install pnpm, trying with yarn')
    end
    
    # If pnpm is still not available, try with yarn
    unless system('which pnpm > /dev/null 2>&1')
      if system('which yarn > /dev/null 2>&1')
        puts 'Using yarn as fallback package manager'
        # pnpm is not available, vite_ruby will fall back to yarn
      else
        raise('Neither pnpm nor yarn is available')
      end
    else
      puts 'pnpm installed successfully'
    end
  end
end