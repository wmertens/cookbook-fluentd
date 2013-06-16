default[:fluentd][:server][:port] = 24224
default[:fluentd][:server][:log_dir] = "/var/log/td-agent"
default[:fluentd][:server].merge! {
  :enable_hdfs_output => true,
  :enable_mongo_output => true,
  :enable_s3_output => true,
  :matches => {
    "td.*.*" => {
      :type => "tdlog",
      :apikey => "YOUR_API_KEY",
      :auto_create_table => nil,
      :buffer_type => "file",
      :buffer_path => "#{default[:fluentd][:server][:log_dir]}/buffer/td"
    },
    "debug.**" => {
      :type => "stdout",
    }
  },
  :sources => [
    {
      :type => "forward",
      :port => default[:fluentd][:server][:port],
    },
    {
      :type => "debug_agent",
      :bind => "127.0.0.1",
      :port => 24230,
    },
  ]
}

default[:fluentd][:client] = {
  :working_dir => "/etc/fluentd-client",
  :matches => [],
  :log_on_term => nil, # set a string to have a message logged when log observer is about to be turned off
  :options => "-n 0",
  :jobs => [],
}

default[:fluentd][:meta] = {
  :server => "role:fluentd_server",
  :client => "role:fluentd_client",
}