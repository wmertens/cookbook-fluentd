include_recipe "fluentd::client"
gem_package "daemons"

directory "#{node[:fluentd][:client][:working_dir]}/jobs" do
  recursive true
  action :create
end

fluentd_host = Chef::Search::Query.new.search(:node, node[:fluentd][:meta][:server]).first.first["launch_spec"]["ipv4"]["public"]

# stop all jobs
script "stop-jobs" do
  interpreter "bash"
  code <<-EOS
    ruby #{node[:fluentd][:client][:working_dir]}/runner.rb stop
  EOS
  only_if { File.exists?("#{node[:fluentd][:client][:working_dir]}/runner.rb") }
end

script "empty-jobs" do
  interpreter "bash"
  user "root"
  code <<-EOS
    rm -f #{node[:fluentd][:client][:working_dir]}/jobs/*.rb
  EOS
end

script "cleanup-runner" do
  interpreter "bash"
  user "root"
  code <<-EOS
    rm -f #{node[:fluentd][:client][:working_dir]}/jobs.conf
    rm -f #{node[:fluentd][:client][:working_dir]}/runner.rb
  EOS
  only_if { File.exists?("#{node[:fluentd][:client][:working_dir]}/runner.rb") }
end

# Generate jobs:
node[:fluentd][:client][:jobs].each do |job|
  template "#{node[:fluentd][:client][:working_dir]}/jobs/#{job[:name]}.rb" do
    source "file_monitor_job.rb.erb"
    variables(:job => job,
      :server => { :host => fluentd_host, :port => node[:fluentd][:server][:port] },
      :log_on_term => node[:fluentd][:client][:log_on_term],
      :options => node[:fluentd][:client][:options],
    )
  end
end

template "#{node[:fluentd][:client][:working_dir]}/jobs.conf" do
  source "jobs.conf.erb"
  variables(:jobs => node[:fluentd][:client][:jobs])
  only_if { node[:fluentd][:client][:jobs].size > 0 }
end

template "#{node[:fluentd][:client][:working_dir]}/runner.rb" do
  source "file_monitor_runner.rb.erb"
  variables(:working_dir => node[:fluentd][:client][:working_dir])
  only_if { node[:fluentd][:client][:jobs].size > 0 }
end

# start all jobs
script "start-jobs" do
  interpreter "bash"
  code <<-EOS
    ruby #{node[:fluentd][:client][:working_dir]}/runner.rb start
  EOS
  only_if { node[:fluentd][:client][:jobs].size > 0 }
end