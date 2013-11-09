require 'rubygems'
require 'rake/clean'

CLOBBER.include('doc', '.yardoc')

def gemspec
  @gemspec ||= begin
    file = File.expand_path("../money.gemspec", __FILE__)
    eval(File.read(file), binding, file)
  end
end


task :default => :spec
task :test => :spec


require 'rspec/core/rake_task'

namespace "spec" do
  desc "Run RSpec money examples"
  RSpec::Core::RakeTask.new("core") do |t|
    t.pattern = "spec/money/**/*_spec.rb"
  end

  desc "Run RSpec core extension examples"
  RSpec::Core::RakeTask.new("extensions") do |t|
    t.pattern = "spec/core_extensions_spec.rb"
  end
end

desc "Run RSpec examples"
task :spec => ["spec:core", "spec:extensions"]

require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.options << "--files" << "CHANGELOG.md,LICENSE"
end


require 'rubygems/package_task'

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
end

task :gem => :gemspec

desc "Install the gem locally"
task :install => :gem do
  sh "gem install pkg/#{gemspec.full_name}.gem"
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end


desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r money.rb"
end
