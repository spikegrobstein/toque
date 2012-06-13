require 'toque'
require 'fileutils'

Capistrano::Configuration.instance.load do

  set(:toque) { Toque.new }
  set(:user) { fetch(:deploy_user, nil) }

  # initialize the toque object
  on :load do

    # if :enable_chef_client is set to true, then enable this task
    if ( fetch(:enable_chef_server, false) )
      desc "Run chef-client on your nodes"
      task :chef_client, :except => { :chef_client => false } do
        old_user = user
        # all chef stuff must use sudo
        set :user, admin_user

        run "#{ try_sudo } chef-client"

        set :user, old_user
      end
    end
  end

  before 'chef:run_recipes' do
    toque.init_node_json(variables)
  end

  unless defined?(recipe)
    def recipe( recipe_name, options={} )
      toque.add_recipe recipe_name, options
    end
  end

  unless defined?(cookbook)
    def cookbook( cookbook_path )
      toque.add_cookbook cookbook_path
    end
  end

  namespace :chef do

    desc "Run all configured recipes"
    task :run_recipes, :except => { :no_cookbooks => true } do
      old_user = user
      # all chef stuff must use sudo
      set :user, admin_user

      upload_cookbooks

      toque.recipes.each do |recipe, options|
        put toque.json_for_runlist(recipe), "#{ Toque::TMP_DIR }/#{ Toque::JSON_FILENAME }"

        sudo "chef-solo -c #{ Toque::TMP_DIR }/#{ Toque::SOLO_CONFIG_FILENAME } -j #{ Toque::TMP_DIR }/#{ Toque::JSON_FILENAME }", options
      end

      cleanup_cookbooks unless fetch(:toque_no_cleanup, false)

      # reset the old user value
      set :user, old_user
    end

    desc "dumps the node json file and prints it to the screen using awesome_print"
    task :dry_run do
      ap :node_json => toque.node_json
      ap :cookbooks => toque.cookbooks
      ap :recipes => toque.recipes
    end

    # push all chef configurations to server
    desc "[internal] Upload cookbooks to all configured servers."
    task :upload_cookbooks, :except => { :no_cookbooks => true } do
      @cleaned_up = false

      cookbooks_path = toque.build_cookbooks
      puts "built cookbooks path: #{ cookbooks_path }"

      # upload the cookbooks
      # if we fail to do that, it's probably because there are leftover cookbooks from a previous run
      # so try to delete them; if that fails, then raise and error.
      begin
        # upload cookbooks
        run "mkdir -p #{ Toque::TMP_DIR }"
        upload "#{ cookbooks_path }/cookbooks", "#{ Toque::TMP_DIR }/#{ Toque::COOKBOOKS_DIR }", :max_hosts => 4
      rescue
        raise "Failed to clean up cookbooks" if @cleaned_up

        puts "Previous toque run did not complete, cleaning up..."

        cleanup_cookbooks
        @cleaned_up = true

        retry
      end

      # generate the solo.rb file
      put toque.solo_config, "#{ Toque::TMP_DIR }/#{ Toque::SOLO_CONFIG_FILENAME }"
    end

    task :cleanup_cookbooks do
      run "rm -rf #{ Toque::TMP_DIR } || true"
    end

    ## future feature
    ## since toque uses local copies of the cookbooks,
    ## it would be nice if they were kept up to date in the event that the user
    ## wants to keep a separate repository for their cookbooks.
    # if ( exists?(:cookbook_repository) )
    #   desc "Check-out/clone the cookbook repository"
    #   task :prepare do
    #     puts "going to fetch the cookbook repository"
    #   end
    # end

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
