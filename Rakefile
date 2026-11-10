# frozen_string_literal: true

require "bundler/setup"
require "sequel"
require "sequel/extensions/migration"
require "rake"
require "rake/testtask"

Sequel.extension :migration

DB = Sequel.sqlite(File.join(__dir__, "db", "development.sqlite3"))

task :load_db do
  file = File.join(__dir__, "db", "development.sqlite3")
  FileUtils.mkdir_p(File.dirname(file))
end

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: [:test]

namespace :db do
  desc "Create the database"
  task create: :load_db

  desc "Run migrations"
  task migrate: :load_db do
    Sequel::Migrator.run(DB, File.join(__dir__, "lib", "migrations"))
  end

  desc "Roll back the last migration"
  task rollback: :load_db do
    Sequel::Migrator.run(DB, File.join(__dir__, "lib", "migrations"), revert: true)
  end
end
