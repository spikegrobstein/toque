require 'fileutils'

Capistrano::Configuration.instance.load do
  set(:cookbooks_path) { File.expand_path('./cookbooks') }
  
  namespace :toque do

    desc "Run all configured recipes"
    task :run_recipes do
      old_user = user
      # all chef stuff must use sudo
      set :user, admin_user
      
      upload_cookbooks
      
      json_data = Toque::build_node_json(variables)
      
      Toque::chef_recipes.each do |recipe, options|
        server_json = json_data.dup
        
        server_json[:run_list] = [recipe]
        
        put server_json.to_json, '/tmp/node.json'

        sudo "chef-solo -c /tmp/solo.rb -j /tmp/node.json", options
      end
      
      # reset the old user value
      set :user, old_user
    end

    desc "dumps the node json file and prints it to the screen using awesome_print"
    task :dry_run do
      ap :node => Toque::build_node_json(variables, Toque::chef_recipes.keys.split(','))
    end
  
    # push all chef configurations to server
    desc "[internal] Upload cookbooks to all configured servers."
    task :upload_cookbooks do
      # upload cookbooks
      upload cookbooks_path, '/tmp/cookbooks'
      
      # generate the solo.rb file
      put "file_cache_path '/var/chef-solo'\ncookbook_path '/tmp/cookbooks'", '/tmp/solo.rb'
    end

    if ( exists?(:cookbook_repository) )
      desc "Check-out/clone the cookbook repository"
      task :prepare do
        puts "going to fetch the cookbook repository"
      end
    end

    # initialize your shit.
    namespace :init do
      task :all do
        cookbooks
      end
      
      desc "copy the default cookbooks"
      task :cookbooks do
        FileUtils.cp_r File.join(File.dirname(__FILE__), '../cookbooks'), "./"
      end
    end

  end
end
