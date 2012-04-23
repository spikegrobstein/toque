require "toque/version"

module Toque
  
  class << self
    
    attr_reader :chef_recipes
    
    # Register a recipe to be run
    # recipe names should be namespaced (eg: toque::database)
    # options will be passed to the capistrano run() function
    def chef_recipe(recipe_name, options={})
      @chef_recipes ||= {}
      @chef_recipes[recipe_name] = options
    end

    def build_node_json(variables, run_list=nil)
      raise "Must supply capistrano variables. None given." if variables.nil?

      # variables that we will filter out before passing to recipes
      ignored_vars = [
        :source,
        :strategy,
        :logger,
        :password
      ]
  
      # build the json data
      json_data = {}
      variables.each do |k, v|
        begin
          # ignore ignored vars
          next if ignored_vars.include?(k.to_sym)
          
          # if the variable is callable, call it, so as to dereference it
          v = v.call if v.respond_to? :call
    
          json_data[k] = v
        rescue
          # do nothing.
        end
      end
      
      # set the run_list var unless it's nil
      unless run_list.nil?
        json_data[:run_list] = run_list
      end
  
      json_data
    end

  end
end

Capistrano::Configuration.instance.load do
  namespace :toque do

    task :run_recipes do
      upload_cookbooks
  
      # all chef stuff must use sudo
      set :user, admin_user
      
      json_data = Toque::build_node_json(variables)
      
      Toque::chef_recipes.each do |recipe, options|
        server_json = json_data.dup
        
        server_json[:run_list] = [recipe]
        
        put server_json.to_json, '/tmp/node.json'

        sudo "chef-solo -c /tmp/solo.rb -j /tmp/node.json", options
      end
    end

    desc "Say what you would do with the chef recipes without actually doing it."
    task :dry_run do
      ap :node => Toque::build_node_json(variables, fetch(:run_list, nil).split(','))
    end
  
    # push all chef configurations to server
    task :upload_cookbooks do
      cookbook_archive_path = "/tmp/cookbooks.tar.gz"

      `tar cfz #{ cookbook_archive_path } #{ cookbooks_path }`

      upload cookbook_archive_path, cookbook_archive_path
      run "cd /tmp && tar zxvf #{ File.basename cookbook_archive_path }"

      put "file_cache_path '/var/chef-solo'\ncookbook_path '/tmp/cookbooks'", '/tmp/solo.rb'
    end

    if ( exists?(:cookbook_repository) )
      desc "Check-out/clone the cookbook repository"
      task :prepare do
        puts "going to fetch the cookbook repository"
      end
    end

  end
end
