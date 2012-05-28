require 'toque'
require 'fileutils'

module Capistrano
  module Toque

    def self.load_into(config)
      config.load do
        set(:cookbooks_path) { File.expand_path('./cookbooks') }
        set(:user) { fetch(:deploy_user, nil) }

        def recipe( recipe_name, options )
          Toque::recipe recipe_name, options
        end

        namespace :toque do

          desc "Run all configured recipes"
          task :run_recipes do
            old_user = user
            # all chef stuff must use sudo
            set :user, admin_user

            upload_cookbooks

            Toque::init_node_json(variables)

            Toque::recipes.each do |recipe, options|
              put Toque::json_for_runlist(recipe), "#{ Toque::TMP_DIR }/#{ Toque::JSON_FILENAME }"

              sudo "chef-solo -c #{ Toque::TMP_DIR }/#{ Toque::SOLO_CONFIG_FILENAME } -j #{ Toque::TMP_DIR }/#{ Toque::JSON_FILENAME }", options
            end

            cleanup_cookbooks unless fetch(:toque_no_cleanup, false)

            # reset the old user value
            set :user, old_user
          end

          desc "dumps the node json file and prints it to the screen using awesome_print"
          task :dry_run do
            ap :node_json => Toque::init_node_json(variables)
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
              run "mkdir -p #{ Toque::TMP_DIR }"
              upload cookbooks_path, "#{ Toque::TMP_DIR }/#{ Toque::COOKBOOKS_DIR }", :max_hosts => 4
            rescue
              raise "Failed to clean up cookbooks" if @cleaned_up

              puts "Previous toque run did not complete, cleaning up..."

              cleanup_cookbooks
              @cleaned_up = true

              retry
            end

            # generate the solo.rb file
            put Toque::solo_config, "#{ Toque::TMP_DIR }/#{ Toque::SOLO_CONFIG_FILENAME }"
          end

          task :cleanup_cookbooks do
            run "rm -rf #{ Toque::TMP_DIR } || true"
          end

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
    end

  end
end

if Capistrano::Configuration.instance
  Capistrano::Toque.load_into(Capistrano::Configuration.instance)
end

