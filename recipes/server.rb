package "curl"

directory "#{node[:fluentd][:server][:log_dir]}" do
  user "td-agent"
  group "td-agent"
  recursive true
  action :create
end

gem_package "fluent-plugin-webhdfs" do
  action :install
  only_if { node[:fluentd][:server][:enable_hdfs_output] == true }
end
gem_package "fluent-plugin-mongo" do
  action :install
  only_if { node[:fluentd][:server][:enable_mongo_output] == true }
end
gem_package "fluent-plugin-s3" do
  action :install
  only_if { node[:fluentd][:server][:enable_s3_output] == true }
end

script "install-fluentd" do
  interpreter "bash"
  user "root"
  code <<-EOS
    curl -L http://toolbelt.treasure-data.com/sh/install-ubuntu-precise.sh | sh
  EOS
  only_if { not File.exist?("/etc/td-agent/td-agent.conf") }
end

template "/etc/security/limits.conf" do
  source "limits.conf.erb"
  mode 0644
end

script "reload-sysctl" do
  interpreter "bash"
  user "root"
  code <<-EOS
    sysctl -w
  EOS
  action :nothing
end

template "/etc/sysctl.conf" do
  source "sysctl.conf.erb"
  notifies :run, "script[reload-sysctl]", :immediately
end

script "restart-fluentd" do
  interpreter "bash"
  user "root"
  code <<-EOS
    /etc/init.d/td-agent restart
  EOS
  action :nothing
end

client_matches = {}
clients = Chef::Search::Query.new.search(:node, node[:fluentd][:meta][:client]).first
clients.each do |client|
  if client.override.has_key?("fluentd") and client.override["fluentd"].has_key?("client") and client.override["fluentd"]["client"].has_key?("matches")
    client_matches.merge! client.override["fluentd"]["client"]["matches"]
  end
end

template "/etc/td-agent/td-agent.conf" do
  source "td-agent.conf.erb"
  variables( :client_matches => client_matches )
  notifies :run, "script[restart-fluentd]", :immediately
end