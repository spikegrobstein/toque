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

rotate_count = node.cap.logrotate_count || 7

template "/etc/logrotate.d/#{ node.cap.application.gsub(/\s+/, '_').downcase }" do
  source 'rails_log.conf.erb'
  mode '0644'
  variables({
    :logs_path => "#{node.cap.shared_path}/log",
    :rotate_count => rotate_count
  })
end
