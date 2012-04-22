#
# Cookbook Name:: toque
# Recipe:: user
#
# Copyright 2012, Spike Grobstein
#

# supports the following variables intitialized from capistrano:
# * deploy_user -- the user to deploy
# * deploy_user_shell -- the shell for the deploy user
# * deploy_user_home -- the path to the home directory for the deploy user
# * deploy_user_comment -- the GECOS comment field for the deploy user
# * authorized_keys -- an array of public keys to add to the user's authorized_keys2 file

# TODO: yet to implement:
# uid
# gid
# github private deploy key - key for deploying the application with ssh config file
# groups for this user to belong to
# base template configuration for ssh config


user node.deploy_user do
  action :create
  shell     node[:deploy_user_shell]    || '/bin/bash'
  home      node[:deploy_user_home]     || "/home/#{ node.deploy_user }"
  comment   node[:deploy_user_comment]  || "deploy user for #{ node.application }"
  supports  :manage_home => true
end

# configure the deploy key if there's a deploy key configured
if node.attribute?(:authorized_keys)
  
  # create the user's .ssh directory
  directory "/home/#{ deploy_user }/.ssh" do
    owner node.deploy_user
    group node.deploy_user
    mode 0744
  end
  
  # build the content of the authorized_keys2 file
  keys = [*node.authorized_keys].join "\n"

  # now add keys
  file "/home/#{ deploy_user }/.ssh/authorized_keys2" do
    content keys
    backup :false
    mode "0600"
    owner deploy_user
    group deploy_user
    
    # will always overwrite the file. this way, you can easily manage this file
    action :create
  end
  
end