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

# 
#chef_recipe 'nginx', :roles => :web

# reads
#chef_recipe 'postgres', :roles => :db
chef_recipe 'user' # runs on all

