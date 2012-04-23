#
# Cookbook Name:: toque
# Recipe:: logrotate
#
# Copyright 2012, Spike Grobstein
#

# creates a logrotate policy
# uses the shared_path variable to find the logs directory and rotates *.log in there

# TODO:
# support custom logrotate rules?

template "/etc/logrotate.d/#{ node.application.gsub(/\s+/, '_').downcase }" do
  source 'rails_log.conf.erb'
  mode '0644'
  variables({
    :logs_path => "#{node.shared_path}/log"
  })
end
