require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rspec'
require 'rspec/core/rake_task'
require 'rake/clean'

Rake::TaskManager.record_task_metadata = true

namespace :integration do
  desc 'Build bot config with mock components'
  task :bot_file do
    File.open('config/bot.test.yml', 'w') do |f|
      f.write("adapter:
  type: slack # Enables option alternative adapters
  token: #{ENV['SLACK_TOKEN']}

# Bot ConfigFile
bot:
  name: integration_bot

# Logger
logger_level: info

# Admin Settings
admin:
  users:

# Help Settings
help:
  level: 1
  dm_user: false

plugins:
  location: '../../spec/fixtures/plugins/*.yml'")
    end
  end

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = Dir.glob('spec/*_spec.rb')
  end

  task all: [:bot_file, :spec]
end

namespace :cleanup do
  desc "Bundle Clean"
  task :bundle do
    sh 'bundle clean'
  end

  desc "Clean out scripts"
  task :scripts do
    sh 'rm -f scripts/*'
    sh 'touch scripts/.gitkeep'
  end

  desc "Clean Up Dev Files"
  task :dev_files do
    sh 'rm -f config/bot.test.yml'
  end

  task :all => [:bundle, :scripts, :dev_files]
end

namespace :run do
  desc 'Build bot config with mock components'
  task :bot_file do
    File.open('config/bot.test.yml', 'w') do |f|
      f.write("adapter:
  type: slack
  token: #{ENV['SLACK_TOKEN']}

# Bot ConfigFile
bot:
  name: slapi

# Admin Settings
admin:
  users:

# Help Settings
help:
  level: 1
  dm_user: false

plugins:
  location: '../../config/plugins/*.yml'")
    end
  end

  task :local do
    sh 'bundle exec rackup -E production -p 4567'
  end

  task :docker do
    sh 'docker-compose -f slapi-build-compose.yml up'
  end
end

desc "Runs Integration Tests"
task :integration => 'integration:all'

desc "Cleanup everything"
task :cleanup => 'cleanup:all'

desc "Run Slapi in Docker"
task :docker => ["run:bot_file", "run:docker"]

desc "Run Slapi Locally"
task :local => ["run:bot_file", "run:local"]

desc "Default Tasks"
task :default do
  Rake::application.options.show_tasks = :tasks
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments
end
