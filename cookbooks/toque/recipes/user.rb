#
# Cookbook Name:: toque
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


deploy_user = node[:deploy_user]

user deploy_user do
  action :create
  shell '/bin/bash'
  home "/home/#{ deploy_user }"
  comment "deploy user for #{ node.cap[:application] }"
  supports :manage_home => true
end

directory "/home/#{ deploy_user }/.ssh" do
  owner deploy_user
  group deploy_user
  mode 0700
end

# now add keys
cookbook_file "/home/#{ deploy_user }/.ssh/authorized_keys2" do
  source node[:deploy_key]
  mode "0600"
  owner deploy_user
  group deploy_user
end
