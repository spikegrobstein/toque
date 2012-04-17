# app-specific components

  * per-environment
    * config/*.yml -- offline
  * common
    * nginx config
    * deploy key -- offline
    * deploy user
    * resque configuration
    
  * capistrano configuration
    * `deploy_user` -- the user that deployment happens as
    * `admin_user` -- user with sudo access

## Offline resources

Some resources should not be stored with the code in the repository. These items should be fetched from an outside source or be placed in an accessible location by an administrator in order to run the recipe/task.

## Proposal:

directory structure:

 * `deploy/`
   * `config/`
     * `<environment>` -- the configs for that environment
   * `deploy_key` -- private deploy key
   * `deploy_key.pub` -- public deploy key (not required)
   * `deploy.rb` -- custom capistrano recipe?
   * `templates/` -- directory containing template files which will be passed variables from capistrano
   * `site/` -- nginx configuration files
   
## functionality

 * **admin** create deploy_user (if necessary)
 * install private deploy key
 * deploy:setup
 * push configs to shared directory
 * **admin** configure nginx (do **not** restart it)
 * **admin** configure resque as a service on resque servers
 * deploy application
 * restart nginx (if necessary)
 
some things to do in the future:

check for Procfile and use Foreman to generate upstart jobs
allow configuration of which jobs actually get procfiles created
check for `Procfile.<environment>` files for environment-specific stuff
create upstart jobs

package dependencies

## use

probably will be called from a rake task so as to call capistrano from the commandline and not share configurations between calls? run a series of tasks with vars set specific ways.

## chef-solo

create solo.rb config file
  needs to contain something like the following:
  
    file_cache_path "/var/chef-solo"
    cookbook_path "/home/spike/cookbooks"
  
create json with relevant capistrano data under "cap" namespace.
create `run_list` entry with role's run-list
call like `sudo chef-solo -j node.json`


## todo:
if cookbooks directory is not there, don't allow config tasks
custom message can be presented if that is the case, defaults to "talk to an admin"
pass more information about capistrano into the json
when reading config files (passed under 'config':{ 'database.yml': ... } style), read specified environment if doing multistage

recipes:
`deploy_user`
`database` (postgres, mysql)
`resque_service`
`vhost`



     .__ _ __.
    ( (  :  ) )
     ||  |  ||
     ||  |  ||
     ||__|__||
     |||||||||
     '"""""""'
