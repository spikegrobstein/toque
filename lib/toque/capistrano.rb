require 'toque'
require 'fileutils'

Capistrano::Configuration.instance.load do
  set(:cookbooks_path) { File.expand_path('./cookbooks') }
  set(:user) { fetch(:deploy_user, nil) }
  
  namespace :toque do

    desc "Run all configured recipes"
    task :run_recipes do
      old_user = user
      # all chef stuff must use sudo
      set :user, admin_user
      
      upload_cookbooks
      
      json_data = Toque::build_node_json(variables)
      
      Toque::recipes.each do |recipe, options|
        server_json = json_data.dup
        
        server_json[:run_list] = [recipe]
        
        put server_json.to_json, "/tmp/#{ Toque::JSON_FILENAME }"

        sudo "chef-solo -c /tmp/#{ Toque::SOLO_CONFIG_FILENAME } -j /tmp/#{ Toque::JSON_FILENAME }", options
      end
      
      cleanup_cookbooks
      
      # reset the old user value
      set :user, old_user
    end

    desc "dumps the node json file and prints it to the screen using awesome_print"
    task :dry_run do
      ap :node_json => Toque::build_node_json(variables)
      ap :recipes => Toque::recipes
    end
  
    # push all chef configurations to server
    desc "[internal] Upload cookbooks to all configured servers."
    task :upload_cookbooks do
      @cleaned_up = false
      
      # make sure that the local cookbook exists
      unless File.exists?(cookbooks_path) && File.directory?(cookbooks_path)
        raise "Local cookbooks directory does not exist. Please run the toque:init:cookbooks task."
      end
      
      # upload the cookbooks
      # if we fail to do that, it's probably because there are leftover cookbooks from a previous run
      # so try to delete them; if that fails, then raise and error.
      begin
        # upload cookbooks
        upload cookbooks_path, '/tmp/cookbooks', :max_hosts => 4
      rescue
        raise "Failed to clean up cookbooks" if @cleaned_up
                
        puts "Previous toque run did not complete, cleaning up..."
        
        cleanup_cookbooks
        @cleaned_up = true
        
        retry
      end
      
      # generate the solo.rb file
      put "file_cache_path '/var/chef-solo'\ncookbook_path '/tmp/cookbooks'", "/tmp/#{ Toque::SOLO_CONFIG_FILENAME }"
    end
    
    task :cleanup_cookbooks do
      run "rm -rf /tmp/cookbooks /tmp/#{ Toque::SOLO_CONFIG_FILENAME } /tmp/#{ Toque::JSON_FILENAME } || true"
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
        puts "Installing default cookbooks..."
        FileUtils.cp_r File.join(File.dirname(__FILE__), '../cookbooks'), "./"
      end
    end

  end
end
