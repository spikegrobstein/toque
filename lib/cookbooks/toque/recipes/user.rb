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


home_path = node.cap[:deploy_user_home] || "/home/#{ node.cap.deploy_user }"

user node.cap.deploy_user do
  action :create
  shell     node.cap[:deploy_user_shell]    || '/bin/bash'
  home      home_path
  comment   node.cap[:deploy_user_comment]  || "deploy user for #{ node.cap.application }"
  supports  :manage_home => true
end

# create the user's .ssh directory
directory "#{ home_path }/.ssh" do
  owner node.cap.deploy_user
  group node.cap.deploy_user
  mode 0744
end

# configure the deploy key if there's a deploy key configured
if node.cap.attribute?(:authorized_keys)

  # build the content of the authorized_keys2 file
  keys = [*node.cap.authorized_keys].join "\n"

  # now add keys
  file "#{ home_path }/.ssh/authorized_keys2" do
    content keys
    backup 0
    mode "0600"
    owner node.cap.deploy_user
    group node.cap.deploy_user

    # will always overwrite the file. this way, you can easily manage this file
    action :create
  end

end

# set up the github deploy key
if node.cap.attribute?(:deploy_key)

  deploy_key_filename = "github-deploy-key"

  # write the deploy_key
  file "#{ home_path }/.ssh/#{deploy_key_filename}" do
    content node.cap.deploy_key

    mode "0600"
    owner node.cap.deploy_user
    group node.cap.deploy_user
  end

  # create the ssh config
  # FIXME: currently, this overwrites the entire ssh config
  file "#{ home_path }/.ssh/config" do
    content "Host github.com\nIdentityFile #{ home_path }/.ssh/#{ deploy_key_filename }\n"
    mode "0644"
    owner node.cap.deploy_user
    group node.cap.deploy_user
  end

end
