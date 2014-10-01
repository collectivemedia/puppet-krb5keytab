require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp"]

desc "Validate manifests, templates, and ruby files"
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['spec/**/*.rb','lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end
desc "download and set required modules and files on spec/fixtures"
task :fixtures do
  sh "puppet module install puppetlabs-stdlib --modulepath=./spec/fixtures/modules"
  sh "mkdir -p ./spec/fixtures/modules/krb5keytab"
  sh "cd ./spec/fixtures/modules/krb5keytab &&  ln -s ../../../../manifests ./manifests"
end
task :clean_fixtures do
  sh "rm -rvf ./spec/fixtures/*"
end
