# Install pnpm before asset compilation
Rake::Task['assets:precompile'].enhance ['pnpm:install']

namespace :pnpm do
  desc 'Install pnpm'
  task :install do
    puts 'Installing pnpm...'
    system('npm install -g pnpm@10.2.0') || raise('Failed to install pnpm')
    puts 'pnpm installed successfully'
  end
end