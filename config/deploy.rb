set :application, "exchange"
set :repository,  "git@github.com:ticketevolution/exchange.git"

default_run_options[:pty] = true  # Must be set for the password prompt from git to work

# domain can be per-environment, as well.
# gets passed along to recipes as well
set :domain, 'exchange.ticketevolution.com'

set :cookbook_repository, 'asdf'

set :scm, :git
set :branch, :master
set :deploy_via, :remote_cache

set :deploy_user, 'invoicing'
set :admin_user, 'spike'

set :deploy_to, "/home/#{deploy_user}/#{application}"

## Servers:
#set :gateway, 'spike@gw.tedc.co'

role :web, "192.168.123.130"

# role :web, "app001.staging"                          # Your HTTP server, Apache/etc
# role :app, "app001.staging"                          # This may be the same as your `Web` server
# role :db,  "db001.staging", :primary => true # This is where Rails migrations will run
# role :resque, "resque001.staging"

# site config for nginx
#set :site, File.join(File.dirname(__FILE__), application)

# set(:admin_user) { Capistrano::CLI.prompt "Admin user:" }
# set(:admin_password) { Capistrano::CLI.password_prompt "Admin password:" }

## set ignore_fields for things your recipes aren't interested in.
## TODO

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

@chef_recipes = {}

def chef_recipe(recipe_name, options={})
  @chef_recipes[recipe_name] = options
end

# 
#chef_recipe 'nginx', :roles => :web

# reads
#chef_recipe 'postgres', :roles => :db
chef_recipe 'user' # runs on all

# to run recipes, call config:build task
# can't specify singular recipes to run. will always run all

namespace :config do
  
  task :build do
    configure_chef
    
    # all chef stuff must use sudo
    set :user, admin_user
    @chef_recipes.each do |recipe, options|
      run_recipe recipe, options
    end
  end
  
  desc "Say what you would do with the chef recipes without actually doing it."
  task :dry_run do
    ap :node => build_node_json
  end
  
  if ( exists?(:cookbook_repository) )
    desc "Check-out/clone the cookbook repository"
    task :prepare do
      puts "going to fetch the cookbook repository"
    end
  end
  
end

def build_node_json(run_list=nil)
  #json_data = { :cap => solo_json.dup }
  
  ignored_vars = [
    :source,
    :strategy,
    :logger,
    :password
  ]
  
  json_data = {}
  @variables.each do |k, v|
    begin
      next if ignored_vars.include?(k.to_sym)
      v = v.call if v.respond_to? :call
    
      json_data[k] = v
    rescue
      # do nothing.
    end
  end
  
  unless run_list.nil?
    json_data[:run_list] = run_list
  end
  
  json_data
end

# push all chef configurations to server
def configure_chef
  cookbook_path = File.join(File.dirname(__FILE__), '../cookbooks')

  cookbook_archive_path = "/tmp/cookbooks.tar.gz"

  `tar cfz #{cookbook_archive_path} cookbooks`

  upload cookbook_archive_path, cookbook_archive_path
  run "cd /tmp && tar zxvf #{ File.basename cookbook_archive_path }"
  
  put "file_cache_path '/var/chef-solo'\ncookbook_path '/tmp/cookbooks'", '/tmp/solo.rb'
  
  @chef_configured = true
end

# run a given recipe using the given options
# takes same options as run command
def run_recipe(recipe, options={})  
  json_data = { :cap => solo_json.dup }
  json_data[:run_list] = Array(recipe)
  
  put json_data.to_json, '/tmp/node.json'
  
  run "#{try_sudo} chef-solo -c /tmp/solo.rb -j /tmp/node.json", options
end

##
# returns the necessary json for the current task
# generate solo.json
# should look like:
#
# set :solo_json, Hash[[
#     :application,
#     :repository,
#     :deploy_to,
#     :deploy_user,
#     :use_sudo,
#     :user
#   ].collect { |k| [k, fetch(k, nil)] }]
# 
# solo_json[:capistrano] = @variables

#after "deploy:setup", "config:chown_application"

task :runit do
  run_cookbook 'user', 'resque'
end

namespace :config do
  
  namespace :bootstrap do
    task :default do
      set :user, admin_user
      chef.upload_cookbooks
      chef.create_deploy_user
      chef.prep_for_deploy       # all
      
      deploy.setup
      upload_configs
      
      configure_resque      
    end
    
    desc :site do
      nginx.upload_config
      nginx.enable
    end
    
    desc "Set up this application on designated servers and deploy."
    task :cold_deploy do
      set :user, admin_user
      # chef
      chef.upload_cookbooks      # all
      chef.create_deploy_user    # all
      chef.prep_for_deploy       # all
      nginx.upload_config   # appservers
      
      nginx.enable          # appservers
      
      configure_resque      # resque
      
      # capistrano
      deploy.setup
      upload_configs
      deploy
      
      nginx.restart         # appservers
    end
  end
  
  namespace :chef do    
    desc "Create the configured deploy user."
    task :create_deploy_user do
      run_cookbooks('user')
    end
    
    desc "Configure ssh keys for deploying from GitHub"
    task :prep_for_deploy do
      puts "uploading deploy key"
    end
  end
  
  desc "Upload the app configuration (YML files) for this environment"
  task :upload_configs do
    puts "uploading yml configuration"
  end
  
  desc "Configure resque worker daemon start/stop jobs."
  task :configure_resque, :roles => :resque do
    puts "setting up resque worker process control"
    run "echo resque only on `hostname`"
  end
  
  namespace :nginx do
    
    desc "Upload the nginx site configuration."
    task :upload_config, :roles => :app do
      puts "uploading nginx site config"
      run "echo only on `hostname`"
    end
    
    desc "Symlink the site config to sites.d"
    task :enable do
      puts "enabling nginx"
    end
    
    desc "De-symlink the site config to sites.d"
    task :disable do
      puts "disabling nginx"
    end
    
    [ :start, :stop, :reload, :restart ].each do |action|
      desc "#{ action.to_s.capitalize } the nginx daemon."
      task action, :roles => :app do
        run "#{try_sudo} /etc/init.d/nginx #{ action.to_s }"
      end
    end
    
  end
  
  desc "Ensure ownership of the application directory for deploy_user"
  task :chown_application do
    run "#{try_sudo} chown -R #{deploy_user}:#{deploy_user} #{deploy_to}"
  end
  
end

# def check_user(options)
#   set(:user) do
#     options[:admin] ? admin_user : deploy_user  
#   end
# end

# exit
# 
# module ::Capistrano
#   class Configuration
#     module Namespaces
# 
#       # def self.included(base) #:nodoc:
#       #   #super(base)
#       #   base.send :alias_method, :orig_task, :task
#       # end
# 
#       alias_method :orig_task, :task
# 
#       def task(name, options={}, &block)
#         orig_task name, options do
#           puts "processing..."
#           set(:user) { options[:admin] ? admin_user : (@variables[:user] || nil) }
#     
#           block.call
#         end
#       end
# 
#     end
#     
#     include Namespaces
#   end
# end
# 
# after 'deploy:bootstrap', 'deploy:setup'
# 
# #pp task_call_frames
# 
# namespace :deploy do
#   task :bootstrap do
#     run "#{try_sudo} useradd -s /bin/bash -m #{user}"
#   end
# end
# 
# # task :boop, :admin => true do
# #   check_user(options)
# # 
# #   run "I booped your nose."
# # end
# 
# task :generic do
#   run "whoami"
# end
# 
# task :create_user, :admin => true do
#   puts "in task"
#   run "hostname"
#   run "echo is the coolest"
#   run "whoami"
#   run "echo -------"
#   generic
# end
# 
# task :tester do
#   run "echo just testing"
# end