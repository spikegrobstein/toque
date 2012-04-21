module Toque
  
  class << self
    
    attr_reader :chef_recipes
    
    def chef_recipe(recipe_name, options={})
      @chef_recipes ||= {}
      @chef_recipes[recipe_name] = options
    end
    
    def build_run_list(run_list)
      run_list.split ','
    end

    def build_node_json(variables, run_list=nil)
      raise "Must supply capistrano variables. None given." if variables.nil?
      #json_data = { :cap => solo_json.dup }
  
      ignored_vars = [
        :source,
        :strategy,
        :logger,
        :password
      ]
  
      json_data = {}
      variables.each do |k, v|
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

    # to run recipes, call config:build task
    # can't specify singular recipes to run. will always run all


    # run a given recipe using the given options
    # takes same options as run command
    def run_recipe(recipe, options={})  
      json_data = Toque::build_node_json(variables, Toque::build_run_list(fetch :run_list, nil))
  
      put json_data.to_json, '/tmp/node.json'
  
      sudo "chef-solo -c /tmp/solo.rb -j /tmp/node.json", options
    end
  end
end

Capistrano::Configuration.instance.load do
namespace :config do

  task :build do
    configure_chef
  
    # all chef stuff must use sudo
    set :user, admin_user
    Toque::chef_recipes.each do |recipe, options|
      Toque::run_recipe recipe, options
    end
  end

  desc "Say what you would do with the chef recipes without actually doing it."
  task :dry_run do
    ap :node => Toque::build_node_json(variables, Toque::build_run_list(fetch :run_list, nil))
  end
  
  # push all chef configurations to server
  task :configure_chef do
    cookbook_path = File.join(File.dirname(__FILE__), '../cookbooks')

    cookbook_archive_path = "/tmp/cookbooks.tar.gz"

    `tar cfz #{cookbook_archive_path} cookbooks`

    upload cookbook_archive_path, cookbook_archive_path
    run "cd /tmp && tar zxvf #{ File.basename cookbook_archive_path }"

    put "file_cache_path '/var/chef-solo'\ncookbook_path '/tmp/cookbooks'", '/tmp/solo.rb'

    @chef_configured = true
  end

  if ( exists?(:cookbook_repository) )
    desc "Check-out/clone the cookbook repository"
    task :prepare do
      puts "going to fetch the cookbook repository"
    end
  end

end
end
