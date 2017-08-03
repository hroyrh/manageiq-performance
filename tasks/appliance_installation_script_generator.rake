require "erb"
require File.expand_path "../support/gem_base64", __FILE__

SCRIPT_FILENAME = "tmp/manageiq-performance-appliance-installation-script.rb"

CLEAN.include SCRIPT_FILENAME

# clobber any renamed generated scripts that might have been renamed
CLOBBER.include "tmp/*_script.rb"

desc "Generate script for installing gem on an appliance"
task :generate_install_script do
  require File.expand_path "../support/template_helper", __FILE__
  include TemplateHelper

  template_dir       = File.expand_path "../support/templates", __FILE__
  template_filename  = "appliance_installation_script.rb.erb"

  @gemspec           = GemBase64.miqperf_gemspec
  @gem_base64_string = GemBase64.gem_as_base64_string
  @template          = File.read File.join(template_dir, template_filename)
  @output_filename   = SCRIPT_FILENAME

  b = binding
  File.write @output_filename, ERB.new(@template, nil, "-").result(b)
end

desc "Add stackprof to install script (use with generate_install_script task)"
task :include_stackprof do
  # Build the gem for our target if it doesn't already exist
  Rake::Task[:build_c_ext_gem].invoke "stackprof"

  @stackprof_gemspec   = GemBase64.find_gemspec_for "stackprof"
  stackprof_gem_tar_io = File.new ext_build_for("stackprof"), "r"

  @stackprof_gem_base64_string = GemBase64.gem_as_base64_string stackprof_gem_tar_io
end

desc <<-DESC
Include a single gem, exclude others (use with generate_install_script task)

Useful when not trying to install `manageiq-performance`, but another gem on an
existing appliance.

Example:

$ rake solo_gem[vcr] generate_install_script

DESC
task :solo_gem, [:gem] do |t, args|
  @solo_gem = true

  new_gem = args[:gem]
  raise "You must include a gem to add..." unless new_gem

  @other_gems ||= []
  @other_gems << {}.tap {|new_gem_entry|
    new_gem_entry[:name]     = new_gem
    new_gem_entry[:env_name] = new_gem.upcase.gsub "-", "_"

    gemspec = GemBase64.find_gemspec_for new_gem
    new_gem_entry[:gemspec] = gemspec


    new_gem_tar_io = File.new gemspec.cache_file, "r"
    new_gem_base64_string = GemBase64.gem_as_base64_string new_gem_tar_io
    new_gem_entry[:gem_base64_string] = new_gem_base64_string
  }
end
